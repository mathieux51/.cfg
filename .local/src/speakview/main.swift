// speakview: reads markdown aloud and highlights each word as it is spoken.
// Meant to run full-screen inside a tmux popup (see ~/.local/bin/speakview-popup).
//
//   speakview FILE
//
// Keys: space pause/resume, n/p (or ]/[) next/previous item, left/right
// next/previous sentence, +/- speed, s airy/compact spacing, r restart, q or Esc close. Click a word to
// read from there. Scrolling (wheel/trackpad, up/down, j/k, PgUp/PgDn, g/G) is
// independent of the voice; f goes back to following it.
//
// The file is rendered like Claude Code renders a reply (headings, bold, inline
// code, bullets, code blocks, tables) in Nord colors, while the voice gets clean
// text: no markdown symbols, code blocks and URLs skipped, table rows read as
// "cell, cell.". Every displayed glyph remembers its offset in that spoken text,
// which is how a spoken word finds its way back to the screen.
//
// Uses AVSpeechSynthesizer, the engine behind Spoken Content (Option+Esc), because
// it reports the range of every word as it starts; `say` reports nothing. Voice and
// rate are Spoken Content's own per-language settings, taken from
//   defaults read com.apple.Accessibility SpokenContentDefaultVoiceSelectionsByLanguage
// en = Ava (Premium) at 0.6, fr = Aurelie (Enhanced) at 0.65. Re-sync if they move.
// SPEAK_VOICE_ID and SPEAK_AV_RATE override them.
//
// Redraws only the rows that changed, inside synchronized-output markers
// (ESC[?2026h/l), and never clears the screen mid-read, so nothing flickers.

import AVFoundation
import Foundation
import NaturalLanguage

// MARK: Nord

struct RGB: Equatable { let r: Int, g: Int, b: Int }
func hex(_ v: Int) -> RGB { RGB(r: v >> 16 & 0xff, g: v >> 8 & 0xff, b: v & 0xff) }

let nord0 = hex(0x2E3440), nord1 = hex(0x3B4252), nord2 = hex(0x434C5E), nord3 = hex(0x4C566A)
let nord4 = hex(0xD8DEE9), nord6 = hex(0xECEFF4)
let nord7 = hex(0x8FBCBB), nord8 = hex(0x88C0D0), nord9 = hex(0x81A1C1)
let nord13 = hex(0xEBCB8B), nord14 = hex(0xA3BE8C), nord15 = hex(0xB48EAD)
let readFg = hex(0x7B88A1)  // Nord's brightened comment grey: receded, still legible

// MARK: Model

enum Role { case body, strong, em, code, link, h1, h2, h3, marker, quote, codeBlock, border, header }

// One displayed character. `at` is its offset (UTF-16) in the spoken text, and
// `len` how much of the spoken text it accounts for (0 when it is not spoken).
struct Glyph { let ch: Character; let role: Role; let at: Int; let len: Int }

struct Line {
    let g: [Glyph]
    var fill = false   // code block line: paint the background across the full width
    var tight = false  // code and table-grid lines: never spaced apart, or the box breaks
    let endAt: Int     // end of the last spoken glyph, -1 when the line speaks nothing
    init(_ g: [Glyph], fill: Bool = false, tight: Bool = false) {
        self.g = g
        self.fill = fill
        self.tight = tight
        endAt = g.filter { $0.len > 0 }.map { $0.at + $0.len }.max() ?? -1
    }
}

enum Block {
    case para([Glyph]), heading(Int, [Glyph]), item(String, Int, [Glyph]), quote([Glyph])
    case code([[Glyph]]), table([[[Glyph]]], [Character]), rule(Int), blank  // table: rows, alignment l/c/r per column
}

// MARK: Spoken text

var speech = ""
var speechLen = 0

// Superscripts and subscripts from U+2070-209F (10⁹, H₂O; the Latin-1 ¹²³ are fine)
// make the voice report every word as the whole utterance, which pinned the
// highlight to the start. Say them as plain text: 10⁹ is "10 to the power of 9",
// H₂O is "H2O".
var inSuperscript = false
func spokenForm(_ ch: Character) -> String {
    guard let u = ch.unicodeScalars.first?.value, (0x2070...0x209F).contains(u) else {
        inSuperscript = false
        return String(ch)
    }
    let plain = String(ch).precomposedStringWithCompatibilityMapping
    if u >= 0x2080 { inSuperscript = false; return plain }
    defer { inSuperscript = true }
    return inSuperscript ? plain : " to the power of " + plain
}

func emit(_ s: String, _ role: Role, spoken: Bool = true) -> [Glyph] {
    var out: [Glyph] = []
    for ch in s {
        let say = spoken ? spokenForm(ch) : ""
        let l = say.utf16.count
        out.append(Glyph(ch: ch, role: role, at: speechLen, len: l))
        if spoken { speech += say; speechLen += l }
    }
    return out
}

func speakOnly(_ s: String) { speech += s; speechLen += s.utf16.count }

// Where each item (paragraph, heading, bullet, quote, table row) starts in the
// spoken text, for n/p.
var items: [Int] = []
func startItem() { if items.last != speechLen { items.append(speechLen) } }

// End a block with a sentence break so the voice pauses between items and cells.
func endBlock() {
    let t = speech.trimmingCharacters(in: .whitespacesAndNewlines)
    if let last = t.last, !".!?:;".contains(last) { speakOnly(".") }
    speakOnly("\n")
}

func deco(_ s: String, _ role: Role, _ at: Int) -> [Glyph] { s.map { Glyph(ch: $0, role: role, at: at, len: 0) } }
func anchor(_ g: [Glyph], _ fallback: Int) -> Int { g.first?.at ?? fallback }

// MARK: Markdown

func inline(_ s: String, _ base: Role) -> [Glyph] {
    let c = Array(s)
    var out: [Glyph] = []
    var i = 0, bold = false, ital = false
    func role() -> Role { base != .body ? base : (bold ? .strong : (ital ? .em : .body)) }
    func has(_ p: String, _ j: Int) -> Bool {
        let pc = Array(p)
        return j + pc.count <= c.count && Array(c[j..<j + pc.count]) == pc
    }
    func find(_ p: String, _ j: Int) -> Int? {
        var k = j
        while k < c.count { if has(p, k) { return k }; k += 1 }
        return nil
    }
    while i < c.count {
        if c[i] == "`", let e = find("`", i + 1) {
            // Code is shown but not read, except a short plain word like `say` that the
            // sentence would not make sense without. Paths, flags and commands stay silent.
            let code = String(c[i + 1..<e])
            out += emit(code, .code, spoken: matches(code, #"^[A-Za-z][A-Za-z +-]{0,23}$"#) != nil)
            i = e + 1; continue
        }
        if has("**", i) || has("__", i) {
            if bold || find(String(c[i...i + 1]), i + 2) != nil { bold.toggle(); i += 2; continue }
        }
        if c[i] == "*", ital || (i + 1 < c.count && c[i + 1] != " " && find("*", i + 1) != nil) {
            ital.toggle(); i += 1; continue
        }
        if c[i] == "[", let m = find("](", i + 1), let e = find(")", m + 2) {
            out += emit(String(c[i + 1..<m]), .link); i = e + 1; continue
        }
        if has("http://", i) || has("https://", i) {
            var e = i
            while e < c.count, !c[e].isWhitespace, c[e] != ")" { e += 1 }
            out += emit(String(c[i..<e]), .link, spoken: false); i = e; continue
        }
        out += emit(String(c[i]), role()); i += 1
    }
    return out
}

func matches(_ s: String, _ pattern: String) -> [String]? {
    guard let re = try? NSRegularExpression(pattern: pattern),
          let m = re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) else { return nil }
    return (0..<m.numberOfRanges).map { m.range(at: $0).location == NSNotFound ? "" : (s as NSString).substring(with: m.range(at: $0)) }
}

func parse(_ text: String) -> [Block] {
    let src = text.components(separatedBy: "\n")
    var blocks: [Block] = []
    var i = 0
    func special(_ l: String) -> Bool {
        let t = l.trimmingCharacters(in: .whitespaces)
        return t.isEmpty || t.hasPrefix("```") || t.hasPrefix("|") || t.hasPrefix("#") || t.hasPrefix(">")
            || matches(l, #"^\s*([-*+]|\d+[.)])\s+"#) != nil || matches(t, #"^(-{3,}|\*{3,}|_{3,})$"#) != nil
    }
    while i < src.count {
        let line = src[i]
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.isEmpty {
            if case .blank? = blocks.last {} else { blocks.append(.blank) }
            i += 1
        } else if t.hasPrefix("```") {
            var code: [[Glyph]] = []
            i += 1
            while i < src.count, !src[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                code.append(emit(src[i].replacingOccurrences(of: "\t", with: "    "), .codeBlock, spoken: false)); i += 1
            }
            i += 1
            blocks.append(.code(code))
        } else if t.hasPrefix("|") {
            var rows: [[[Glyph]]] = []
            var aligns: [Character] = []
            while i < src.count, src[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                let r = src[i].trimmingCharacters(in: .whitespaces)
                i += 1
                if matches(r, #"^[\s|:-]+$"#) != nil {
                    // The |:--|:-:|--:| row: column alignment.
                    aligns = r.split(separator: "|").map { c in
                        let t = c.trimmingCharacters(in: .whitespaces)
                        return t.hasPrefix(":") && t.hasSuffix(":") ? "c" : (t.hasSuffix(":") ? "r" : "l")
                    }
                    continue
                }
                var cells = r.components(separatedBy: "|")
                cells.removeFirst()
                if cells.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { cells.removeLast() }
                var row: [[Glyph]] = []
                startItem()
                for (j, cell) in cells.enumerated() {
                    row.append(inline(cell.trimmingCharacters(in: .whitespaces), rows.isEmpty ? .header : .body))
                    if j < cells.count - 1 { speakOnly(", ") }
                }
                endBlock()
                rows.append(row)
            }
            blocks.append(.table(rows, aligns))
        } else if let m = matches(t, #"^(#{1,6})\s+(.*)$"#) {
            let level = m[1].count
            startItem()
            blocks.append(.heading(level, inline(m[2], level == 1 ? .h1 : (level == 2 ? .h2 : .h3))))
            endBlock(); i += 1
        } else if matches(t, #"^(-{3,}|\*{3,}|_{3,})$"#) != nil {
            blocks.append(.rule(speechLen)); i += 1
        } else if let m = matches(line, #"^(\s*)([-*+]|\d+[.)])\s+(.*)$"#) {
            let level = min(3, m[1].count / 2)
            let marker = m[2].first!.isNumber ? m[2] : ["•", "◦", "▪", "‣"][level]
            startItem()
            blocks.append(.item(marker, level, inline(m[3], .body)))
            endBlock(); i += 1
        } else if t.hasPrefix(">") {
            startItem()
            blocks.append(.quote(inline(String(t.dropFirst()).trimmingCharacters(in: .whitespaces), .body)))
            endBlock(); i += 1
        } else {
            // A paragraph: join soft-wrapped lines so it reflows to the popup width.
            var para = t
            i += 1
            while i < src.count, !special(src[i]) { para += " " + src[i].trimmingCharacters(in: .whitespaces); i += 1 }
            startItem()
            blocks.append(.para(inline(para, .body)))
            endBlock()
        }
    }
    return blocks
}

// MARK: Input text

let args = CommandLine.arguments
guard args.count > 1, let raw = try? String(contentsOfFile: args[1], encoding: .utf8) else {
    FileHandle.standardError.write("usage: speakview FILE\n".data(using: .utf8)!)
    exit(2)
}
let blocks = parse(raw.trimmingCharacters(in: .whitespacesAndNewlines))
let ns = speech as NSString
if blocks.isEmpty { exit(0) }
// Text with nothing to say (only code, only a URL) still opens, so it can be read
// on screen instead of the popup flashing shut.
let silent = speech.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

var sentences: [NSRange] = []
do {
    let tok = NLTokenizer(unit: .sentence)
    tok.string = speech
    tok.enumerateTokens(in: speech.startIndex..<speech.endIndex) { r, _ in
        sentences.append(NSRange(r, in: speech)); return true
    }
    if sentences.isEmpty { sentences = [NSRange(location: 0, length: ns.length)] }
}

// MARK: Voice

let env = ProcessInfo.processInfo.environment
let recognizer = NLLanguageRecognizer()
recognizer.processString(speech)
let isFrench = recognizer.dominantLanguage == .french

let voice: AVSpeechSynthesisVoice? = {
    let wanted = env["SPEAK_VOICE_ID"] ?? (isFrench
        ? "com.apple.voice.enhanced.fr-FR.Aurelie"
        : "com.apple.voice.premium.en-US.Ava")
    return AVSpeechSynthesisVoice(identifier: wanted)
        ?? AVSpeechSynthesisVoice(language: isFrench ? "fr-FR" : "en-US")
}()
var rate: Float = Float(env["SPEAK_AV_RATE"] ?? "") ?? (isFrench ? 0.65 : 0.6)

// MARK: Terminal

var original = termios()
tcgetattr(STDIN_FILENO, &original)

func restoreTerminal() {
    var t = original
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &t)
    print("\u{1b}[0m\u{1b}[?1006l\u{1b}[?1000l\u{1b}[?7h\u{1b}[?25h\u{1b}[?1049l", terminator: "")
    fflush(stdout)
}

func enterRawMode() {
    var t = original
    t.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG | IEXTEN)
    t.c_iflag &= ~tcflag_t(IXON | ICRNL)
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &t)
    // ?7l turns off autowrap: a row that touches the last column must never scroll the screen.
    // ?1000h + ?1006h: mouse reporting (SGR encoding) for the wheel, trackpad and clicks.
    print("\u{1b}[?1049h\u{1b}[?25l\u{1b}[?7l\u{1b}[?1000h\u{1b}[?1006h", terminator: "")
}

func terminalSize() -> (cols: Int, rows: Int) {
    var w = winsize()
    if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0, w.ws_col > 0 { return (Int(w.ws_col), Int(w.ws_row)) }
    return (80, 24)
}

// MARK: Layout

var lines: [Line] = []
var textWidth = 80
var margin = 2

func wrap(_ g: [Glyph], _ first: [Glyph], _ rest: [Glyph]) -> [Line] {
    if g.isEmpty { return [Line(first)] }
    var out: [Line] = []
    var start = 0, prefix = first
    while start < g.count {
        let w = max(10, textWidth - prefix.count)
        var end = min(g.count, start + w)
        if end < g.count {
            var cut = end
            while cut > start, g[cut].ch != " " { cut -= 1 }
            if cut > start { end = cut }
        }
        out.append(Line(prefix + Array(g[start..<end])))
        start = end
        while start < g.count, g[start].ch == " " { start += 1 }
        prefix = rest
    }
    return out
}

// Tables follow Claude Code's own renderer (2.1.x, read from its bundle):
// - each column gets its natural width when the table fits; otherwise every
//   column keeps at least its longest word and the spare room is shared in
//   proportion to how much each one wanted; if even that is too wide, words are
//   hard-broken;
// - cells wrap inside their column and sit vertically centered in the row; the
//   header is centered, body cells follow the |:-:| alignment (left by default);
// - a separator line runs between every row;
// - if any cell would need more than 4 lines, the grid is dropped for bold
//   "Header: value" lines with a short rule between rows.
func tableLines(_ rows: [[[Glyph]]], _ aligns: [Character]) -> [Line] {
    let n = rows.map(\.count).max() ?? 0
    guard n > 0, let head = rows.first else { return [] }
    let body = Array(rows.dropFirst())
    func cell(_ r: [[Glyph]], _ j: Int) -> [Glyph] { j < r.count ? r[j] : [] }
    func longestWord(_ g: [Glyph]) -> Int {
        var best = 0, cur = 0
        for x in g { if x.ch == " " { cur = 0 } else { cur += 1; best = max(best, cur) } }
        return best
    }
    let minW = (0..<n).map { j in max(3, rows.map { longestWord(cell($0, j)) }.max() ?? 0) }
    let idealW = (0..<n).map { j in max(3, rows.map { cell($0, j).count }.max() ?? 0) }
    let room = max(textWidth - (1 + n * 3), n * 3)
    var w = idealW
    if idealW.reduce(0, +) > room {
        let minSum = minW.reduce(0, +)
        if minSum <= room {
            let spare = room - minSum
            let want = zip(idealW, minW).map { $0 - $1 }
            let wantSum = want.reduce(0, +)
            w = (0..<n).map { j in wantSum == 0 ? minW[j] : minW[j] + want[j] * spare / wantSum }
        } else {
            w = minW.map { max(3, $0 * room / minSum) }
        }
    }

    // Word-wrap a cell to `width`; a word longer than the column is broken.
    func wrapCell(_ g: [Glyph], _ width: Int) -> [[Glyph]] {
        var out: [[Glyph]] = [], line: [Glyph] = [], word: [Glyph] = []
        func flushWord() {
            guard !word.isEmpty else { return }
            if !line.isEmpty, line.count + 1 + word.count <= width {
                line += [Glyph(ch: " ", role: line.last!.role, at: line.last!.at, len: 0)] + word
                word = []
                return
            }
            if !line.isEmpty { out.append(line); line = [] }
            while word.count > width { out.append(Array(word.prefix(width))); word.removeFirst(width) }
            line = word
            word = []
        }
        for x in g { if x.ch == " " { flushWord() } else { word.append(x) } }
        flushWord()
        if !line.isEmpty { out.append(line) }
        return out.isEmpty ? [[]] : out
    }

    let wrapped = rows.map { r in (0..<n).map { wrapCell(cell(r, $0), w[$0]) } }
    let tallest = wrapped.flatMap { $0.map(\.count) }.max() ?? 1
    let rowAt = rows.map { r in anchor(r.first(where: { !$0.isEmpty }) ?? [], speechLen) }

    if tallest > 4 {
        var l: [Line] = []
        let rule = String(repeating: "─", count: min(textWidth - 1, 40))
        for (ri, r) in body.enumerated() {
            if ri > 0 { l.append(Line(deco(rule, .border, rowAt[ri + 1]), tight: true)) }
            for j in 0..<n {
                let value = cell(r, j)
                let at = anchor(value, rowAt[ri + 1])
                let label = j < head.count ? String(head[j].map(\.ch)) : ""
                if label.isEmpty, value.isEmpty { continue }
                let lead = label.isEmpty ? [] : deco(label + ": ", .header, at)
                l += wrap(value, lead, []).map { var x = $0; x.tight = true; return x }
            }
        }
        return l
    }

    func border(_ left: String, _ mid: String, _ right: String, _ at: Int) -> Line {
        var s = left
        for j in 0..<n { s += String(repeating: "─", count: w[j] + 2) + (j == n - 1 ? right : mid) }
        return Line(deco(s, .border, at), tight: true)
    }
    func rowLines(_ ri: Int) -> [Line] {
        let cells = wrapped[ri], at = rowAt[ri]
        let height = cells.map(\.count).max() ?? 1
        var out: [Line] = []
        for k in 0..<height {
            var g = deco("│", .border, at)
            for j in 0..<n {
                let top = (height - cells[j].count) / 2
                let text = k - top >= 0 && k - top < cells[j].count ? cells[j][k - top] : []
                let pad = w[j] - text.count
                let align: Character = ri == 0 ? "c" : (j < aligns.count ? aligns[j] : "l")
                let before = align == "c" ? pad / 2 : (align == "r" ? pad : 0)
                g += deco(" " + String(repeating: " ", count: before), .border, at) + text
                g += deco(String(repeating: " ", count: pad - before) + " │", .border, at)
            }
            out.append(Line(g, tight: true))
        }
        return out
    }
    var l = [border("┌", "┬", "┐", rowAt[0])]
    for ri in 0..<rows.count {
        if ri > 0 { l.append(border("├", "┼", "┤", rowAt[ri])) }
        l += rowLines(ri)
    }
    l.append(border("└", "┴", "┘", rowAt[rows.count - 1]))
    return l
}

// Airy (the default, s toggles it): two blank lines between paragraphs, one
// between bullets of the same list and after a heading. Lines inside a paragraph
// stay together: a terminal can only space lines by whole rows, and a blank row
// between every line read as too loose. Compact keeps the source's own breaks.
var airy = true

func layout() {
    let (cols, _) = terminalSize()
    textWidth = max(30, min(cols - 8, 72))  // ~70 columns is the comfortable reading measure
    margin = max(2, (cols - textWidth) / 2)

    // Each item becomes a chunk; the gap before it depends on the mode.
    var chunks: [(lines: [Line], gap: Int)] = []
    var sawBlank = true, afterHeading = false, afterBullet = false
    func add(_ l: [Line], heading: Bool = false, bullet: Bool = false) {
        guard !l.isEmpty else { return }
        let gap = chunks.isEmpty ? 0
            : airy ? (afterHeading || (bullet && afterBullet) ? 1 : 2)
            : (sawBlank || heading ? 1 : 0)
        chunks.append((l, gap))
        sawBlank = false
        afterHeading = heading
        afterBullet = bullet
    }

    for b in blocks {
        switch b {
        case .blank:
            sawBlank = true
        case .para(let g):
            add(wrap(g, [], []))
        case .heading(_, let g):
            add(wrap(g, [], []), heading: true)
        case .item(let marker, let level, let g):
            let at = anchor(g, speechLen)
            let indent = String(repeating: "  ", count: level)
            let lead = deco(indent + marker + " ", .marker, at)
            add(wrap(g, lead, deco(String(repeating: " ", count: lead.count), .body, at)), bullet: true)
        case .quote(let g):
            let at = anchor(g, speechLen)
            add(wrap(g, deco("▎ ", .quote, at), deco("▎ ", .quote, at)))
        case .code(let rows):
            let at = anchor(rows.first ?? [], speechLen)
            var l = [Line([], fill: true, tight: true)]
            for r in rows {
                let shown = r.count > textWidth - 4 ? Array(r.prefix(textWidth - 5)) + deco("…", .codeBlock, at) : r
                l.append(Line(deco("  ", .codeBlock, at) + shown, fill: true, tight: true))
            }
            l.append(Line([], fill: true, tight: true))
            sawBlank = true
            add(l)
        case .rule(let at):
            sawBlank = true
            add([Line(deco(String(repeating: "─", count: textWidth), .border, at), tight: true)])
        case .table(let rows, let aligns):
            sawBlank = true
            add(tableLines(rows, aligns))
        }
    }

    var out: [Line] = []
    for c in chunks {
        for _ in 0..<c.gap { out.append(Line([])) }
        out += c.lines
    }
    lines = out
}

// MARK: State

var spoken = NSRange(location: 0, length: 0)  // the word being said, in the spoken text
var paused = false
var finished = false
var top = 0
// The view follows the voice until you scroll. After that it stays where you put
// it, whatever is being read, until f or a jump (n/p, left/right, r, a click).
var following = true
var voiceLoading = false  // waiting for the Kokoro server to load the model

func lineIndex(forOffset off: Int) -> Int {
    if let n = lines.firstIndex(where: { $0.endAt > off }) { return n }
    return max(0, lines.count - 1)
}

func sentence(at off: Int) -> NSRange {
    sentences.last(where: { $0.location <= off }) ?? sentences[0]
}

// MARK: Rendering

func sgr(_ fg: RGB, _ bg: RGB, bold: Bool = false, italic: Bool = false, underline: Bool = false) -> String {
    var s = "\u{1b}[0;38;2;\(fg.r);\(fg.g);\(fg.b);48;2;\(bg.r);\(bg.g);\(bg.b)"
    if bold { s += ";1" }
    if italic { s += ";3" }
    if underline { s += ";4" }
    return s + "m"
}

func look(_ g: Glyph, _ sent: NSRange) -> String {
    var fg = nord4, bg = nord0, bold = false, italic = false, underline = false
    switch g.role {
    case .body: break
    case .strong: fg = nord6; bold = true
    case .em: italic = true
    case .code: fg = nord7; bg = nord2
    case .link: fg = nord8; underline = true
    case .h1: fg = nord8; bold = true
    case .h2: fg = nord8; bold = true
    case .h3: fg = nord7; bold = true
    case .marker: fg = nord9
    case .quote: fg = nord3
    case .codeBlock: bg = nord1
    case .border: fg = nord3
    case .header: fg = nord8; bold = true
    }
    if g.len > 0, !finished, g.at >= spoken.location, g.at < spoken.location + max(spoken.length, 1) {
        return sgr(nord0, nord13, bold: true)
    }
    if finished || g.at < sent.location {
        if g.role != .border, g.role != .quote { fg = readFg }
    } else if g.at < sent.location + sent.length, g.role != .codeBlock {
        if bg == nord0 { bg = nord1 }
        if fg == nord4 { fg = nord6 }
    }
    return sgr(fg, bg, bold: bold, italic: italic, underline: underline)
}

var previous: [String] = []

func render() {
    let (cols, rows) = terminalSize()
    let bodyRows = max(1, rows - 3)  // one row of padding on top, a gap and the footer below
    let current = finished ? lines.count - 1 : lineIndex(forOffset: spoken.location)
    // Scroll in jumps, not every line: only move when the spoken line leaves the
    // middle band, then bring it back to a quarter of the way down.
    if following, current < top || current >= top + bodyRows * 2 / 3 {
        top = current - bodyRows / 4
    }
    top = max(0, min(top, lines.count - bodyRows))

    let sent = sentence(at: spoken.location)
    let blank = sgr(nord4, nord0)
    let pad = String(repeating: " ", count: margin)
    var frame: [String] = [blank + "\u{1b}[K"]
    for r in 0..<bodyRows {
        var s = blank + pad
        if top + r < lines.count {
            let line = lines[top + r]
            var last = blank
            if line.fill { s += sgr(nord4, nord1); last = "" }
            for g in line.g {
                let seq = look(g, sent)
                if seq != last { s += seq; last = seq }
                s.append(g.ch)
            }
            if line.fill, textWidth > line.g.count {
                s += sgr(nord4, nord1) + String(repeating: " ", count: textWidth - line.g.count)
            }
        }
        frame.append(s + blank + "\u{1b}[K")
    }
    frame.append(blank + "\u{1b}[K")

    let (label, color): (String, RGB) = silent ? ("nothing to read aloud", nord3) : finished ? ("done", nord8) : voiceLoading ? ("loading voice", nord13) : (paused ? ("paused", nord13) : ("reading", nord14))
    let pct = ns.length > 0 ? min(100, spoken.location * 100 / ns.length) : 100
    let bar = sgr(nord4, nord1)
    // Footer pieces are added only while they fit, so the row never reaches past the screen.
    var footer = bar, used = 0
    func add(_ styled: String, _ visible: Int) -> Bool {
        guard used + visible < cols else { return false }
        footer += styled; used += visible; return true
    }
    let status = " ● \(label)  \(pct)%  "
    _ = add(bar + " " + sgr(color, nord1, bold: true) + "● " + label + bar + "  \(pct)%  ", status.count)
    if !following { _ = add(sgr(nord13, nord1, bold: true) + "free scroll  ", 13) }
    // Most important first: whatever does not fit on a narrow popup is dropped from the end.
    let keys = [("space", "pause"), ("n/p", "item"), ("←/→", "sentence"), ("f", following ? "following" : "follow"),
                ("+/-", "speed " + String(format: "%.2f", rate)), ("s", airy ? "compact" : "airy"), ("r", "restart"), ("q", "close")]
    for (k, what) in keys {
        if !add(sgr(nord3, nord1) + "│ " + sgr(nord8, nord1, bold: true) + k + bar + " " + what + " ", k.count + what.count + 4) { break }
    }
    frame.append(footer + "\u{1b}[K")

    var out = "\u{1b}[?2026h"
    for (n, row) in frame.enumerated() where n >= previous.count || previous[n] != row {
        out += "\u{1b}[\(n + 1);1H" + row
    }
    out += "\u{1b}[0m\u{1b}[?2026l"
    previous = frame
    print(out, terminator: "")
    fflush(stdout)
}

// MARK: Speech

func isSpace(_ c: unichar) -> Bool { c == 32 || c == 10 || c == 9 || c == 13 }

// Length of the word starting at `loc`, stopping at whitespace or `limit`.
func wordLength(at loc: Int, limit: Int) -> Int {
    var e = loc
    while e < min(limit, ns.length), !isSpace(ns.character(at: e)) { e += 1 }
    return max(1, e - loc)
}

protocol Speaker: AnyObject {
    func speak(from offset: Int)
    func togglePause()
    func stop()
}

final class Reader: NSObject, AVSpeechSynthesizerDelegate, Speaker {
    let synth = AVSpeechSynthesizer()
    var base = 0  // offset of the current utterance in the spoken text
    var current: AVSpeechUtterance?

    // The premium voices sometimes report a whole phrase as one "word". Then the
    // highlight walks through that phrase on its own, at the speaking speed
    // measured from the normal one-word callbacks (characters per second).
    var phrase: NSRange?
    var phraseStart = Date()
    var cps = 25.0
    var lastWord: (time: Date, at: Int)?
    var ticker: Timer?

    override init() { super.init(); synth.delegate = self }

    func speak(from offset: Int) {
        let start = max(0, min(offset, ns.length))
        if synth.isSpeaking { current = nil; synth.stopSpeaking(at: .immediate) }
        finished = false
        paused = false
        following = true
        stopPhrase()
        lastWord = nil
        spoken = NSRange(location: start, length: 0)
        guard start < ns.length else { finished = true; render(); return }
        let u = AVSpeechUtterance(string: ns.substring(from: start))
        u.voice = voice
        u.rate = rate
        base = start
        current = u
        synth.speak(u)
        render()
    }

    func togglePause() {
        if finished { speak(from: 0); return }
        if paused {
            synth.continueSpeaking()
            paused = false
            // Pick the phrase walk up from the word it stopped on.
            if let p = phrase { phraseStart = Date().addingTimeInterval(-Double(spoken.location - p.location) / cps) }
        } else {
            synth.pauseSpeaking(at: .immediate)
            paused = true
        }
        render()
    }

    func stopPhrase() { ticker?.invalidate(); ticker = nil; phrase = nil }

    func stop() { current = nil; synth.stopSpeaking(at: .immediate) }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, willSpeakRangeOfSpeechString r: NSRange, utterance u: AVSpeechUtterance) {
        guard u === current else { return }
        let range = NSRange(location: base + r.location, length: r.length)
        let now = Date()
        if phrase == nil, let last = lastWord, range.location > last.at {
            let dt = now.timeIntervalSince(last.time)
            if dt > 0.05, dt < 2 { cps = cps * 0.7 + 0.3 * Double(range.location - last.at) / dt }
        }
        lastWord = (now, range.location)
        stopPhrase()
        let end = range.location + range.length
        spoken = NSRange(location: range.location, length: wordLength(at: range.location, limit: end))
        if spoken.length < range.length {
            phrase = range
            phraseStart = now
            ticker = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in self?.walkPhrase() }
        }
        render()
    }

    func walkPhrase() {
        guard let p = phrase, !paused else { return }
        let end = p.location + p.length
        var at = min(end - 1, p.location + Int(Date().timeIntervalSince(phraseStart) * cps))
        while at > p.location, !isSpace(ns.character(at: at - 1)) { at -= 1 }
        while at < end, isSpace(ns.character(at: at)) { at += 1 }
        guard at < end, at != spoken.location else { return }
        spoken = NSRange(location: at, length: wordLength(at: at, limit: end))
        render()
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        guard u === current else { return }
        stopPhrase()
        finished = true
        spoken = NSRange(location: ns.length, length: 0)
        render()
    }
}

// MARK: Kokoro

// English is read by Kokoro (an open model, run locally by kokoro/kokoro-serve.py),
// which sounds far more natural than Ava. It sends audio in chunks with the time
// each word starts, and the highlight follows the playback clock. French stays on
// Apple's Aurelie. The model runs as a background server on a Unix socket, so
// only the first read after a while waits for it to load (~10-30 s); if it never
// comes up, English falls back to Ava.
let kokoroDir = NSHomeDirectory() + "/.local/src/speakview/kokoro"
let kokoroOut = NSHomeDirectory() + "/.local/state/speakview/kokoro"
let kokoroSock = NSHomeDirectory() + "/.local/state/speakview/kokoro.sock"

func connectKokoro() -> Int32? {
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else { return nil }
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)
    withUnsafeMutableBytes(of: &addr.sun_path) { p in
        kokoroSock.withCString { _ = strncpy(p.baseAddress!.assumingMemoryBound(to: CChar.self), $0, p.count - 1) }
    }
    let ok = withUnsafePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
    }
    if ok == 0 { return fd }
    close(fd)
    return nil
}

// Start the server, detached: nohup so it outlives the popup closing.
func startKokoro() {
    let log = NSHomeDirectory() + "/.local/state/speakview/kokoro.log"
    FileManager.default.createFile(atPath: log, contents: nil)
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/nohup")
    p.arguments = ["/opt/homebrew/bin/uv", "run", "--quiet", "--project", kokoroDir,
                   kokoroDir + "/kokoro-serve.py", kokoroSock, kokoroOut]
    p.standardInput = FileHandle.nullDevice
    p.standardOutput = FileHandle(forWritingAtPath: log)
    p.standardError = FileHandle(forWritingAtPath: log)
    try? p.run()
}

final class KokoroReader: NSObject, AVAudioPlayerDelegate, Speaker {
    var conn: FileHandle?
    var fallback: Reader?  // Ava, when the server never answers
    var ready = false
    var id = 0
    var base = 0          // offset of the current request in the spoken text
    var chunks: [(audio: Data, words: [[Double]])] = []
    var done = false      // the model has sent every chunk of the current request
    var player: AVAudioPlayer?
    var words: [[Double]] = []  // [at, len, start, end] for the chunk playing
    var ticker: Timer?
    var buffer = Data()

    override init() {
        super.init()
        voiceLoading = true
        try? FileManager.default.createDirectory(atPath: kokoroOut, withIntermediateDirectories: true)
        DispatchQueue.global().async {
            var fd = connectKokoro()
            if fd == nil {
                startKokoro()
                // The first load after an install can take ~30 s.
                for _ in 0..<450 where fd == nil {
                    usleep(200_000)
                    fd = connectKokoro()
                }
            }
            DispatchQueue.main.async { self.attach(fd) }
        }
    }

    func attach(_ fd: Int32?) {
        guard let fd else {
            let r = Reader()
            fallback = r
            voiceLoading = false
            if !finished { r.speak(from: spoken.location) }
            return
        }
        let h = FileHandle(fileDescriptor: fd, closeOnDealloc: false)
        h.readabilityHandler = { h in
            let d = h.availableData
            DispatchQueue.main.async { self.received(d) }
        }
        conn = h
    }

    func received(_ d: Data) {
        buffer.append(d)
        while let nl = buffer.firstIndex(of: 10) {
            let line = buffer[buffer.startIndex..<nl]
            buffer.removeSubrange(buffer.startIndex...nl)
            guard let msg = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else { continue }
            if msg["ready"] != nil {
                ready = true
                voiceLoading = false
                if !finished { request() }
                continue
            }
            let wav = msg["wav"] as? String
            defer { if let wav { try? FileManager.default.removeItem(atPath: wav) } }
            guard msg["id"] as? Int == id else { continue }
            if let wav, let audio = FileManager.default.contents(atPath: wav) {
                chunks.append((audio, msg["words"] as? [[Double]] ?? []))
                if player == nil, !paused { playNext() }
            } else if msg["done"] != nil {
                done = true
                if player == nil, chunks.isEmpty { finish() }
            }
        }
    }

    func request() {
        guard ready else { return }  // sent once the model reports it is ready
        // Apple's 0.5 is normal speed, so 0.6 would be 1.2x; Kokoro reads a bit slow at
        // that, so English goes 15% faster than the rate shown in the footer.
        let req: [String: Any] = ["id": id, "text": ns.substring(from: base), "speed": Double(rate) / 0.5 * 1.15]
        guard var data = try? JSONSerialization.data(withJSONObject: req) else { return }
        data.append(10)
        conn?.write(data)
    }

    func speak(from offset: Int) {
        if let f = fallback { f.speak(from: offset); return }
        let start = max(0, min(offset, ns.length))
        stopAudio()
        finished = false
        paused = false
        following = true
        spoken = NSRange(location: start, length: 0)
        guard start < ns.length else { finished = true; render(); return }
        id += 1
        base = start
        done = false
        request()
        render()
    }

    func stopAudio() {
        ticker?.invalidate(); ticker = nil
        player?.stop(); player = nil
        chunks = []
    }

    func playNext() {
        guard !chunks.isEmpty else {
            player = nil
            if done { finish() }
            return
        }
        let c = chunks.removeFirst()
        words = c.words
        player = try? AVAudioPlayer(data: c.audio)
        player?.delegate = self
        player?.play()
        if ticker == nil {
            ticker = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in self?.tick() }
        }
    }

    func tick() {
        guard let p = player, p.isPlaying, let w = words.last(where: { $0[2] <= p.currentTime }) else { return }
        let at = base + Int(w[0])
        guard at != spoken.location else { return }
        spoken = NSRange(location: at, length: Int(w[1]))
        render()
    }

    func audioPlayerDidFinishPlaying(_ p: AVAudioPlayer, successfully _: Bool) {
        guard p === player else { return }
        playNext()
    }

    func finish() {
        stopAudio()
        finished = true
        spoken = NSRange(location: ns.length, length: 0)
        render()
    }

    func togglePause() {
        if let f = fallback { f.togglePause(); return }
        if finished { speak(from: 0); return }
        if paused {
            paused = false
            if let p = player { p.play() } else { playNext() }
        } else {
            player?.pause()
            paused = true
        }
        render()
    }

    // The server stays up for the next read; closing the connection is enough.
    func stop() {
        fallback?.stop()
        stopAudio()
        conn?.readabilityHandler = nil
        try? conn?.close()
    }
}

// let reader = Reader()
let reader: Speaker = isFrench ? Reader() : KokoroReader()

func sentenceIndex(at off: Int) -> Int { sentences.lastIndex(where: { $0.location <= off }) ?? 0 }

// Next (dir > 0) or previous item. Going back from the middle of an item restarts
// it; going back from its first words goes to the one before, like a music player.
func jumpItem(_ dir: Int) {
    guard !items.isEmpty else { return }
    let cur = items.lastIndex(where: { $0 <= spoken.location }) ?? 0
    let n = dir > 0 ? cur + 1 : (spoken.location - items[cur] < 12 && cur > 0 ? cur - 1 : cur)
    if n < items.count { reader.speak(from: items[n]) }
}

func jumpSentence(_ dir: Int) {
    let cur = sentenceIndex(at: spoken.location)
    let n = dir > 0 ? cur + 1 : (spoken.location - sentences[cur].location < 12 && cur > 0 ? cur - 1 : cur)
    if n < sentences.count { reader.speak(from: sentences[n].location) }
}

func bodyRows() -> Int { max(1, terminalSize().rows - 3) }

func scroll(_ delta: Int) {
    following = false
    top = max(0, min(top + delta, max(0, lines.count - bodyRows())))
    render()
}

// A click on a word starts reading from that word. Screen row 1 is padding, so
// body row r is screen row r + 2; columns start after the left margin.
func click(col: Int, row: Int) {
    let n = top + row - 2, x = col - 1 - margin
    guard row >= 2, row - 2 < bodyRows(), n >= 0, n < lines.count, x >= 0 else { return }
    let g = lines[n].g
    guard !g.isEmpty else { return }
    var k = min(x, g.count - 1)
    // Step back to the start of the word that was clicked.
    while k > 0, g[k - 1].ch != " ", g[k - 1].len > 0 { k -= 1 }
    reader.speak(from: g[k].at)
}

// MARK: Keys

func handle(_ bytes: [UInt8]) {
    var i = 0
    while i < bytes.count {
        let b = bytes[i]
        if b == 0x1b, i + 1 < bytes.count, bytes[i + 1] == 0x5b {
            let j = i + 2
            // Find the CSI final byte, e.g. A in ESC[A, ~ in ESC[5~, M/m in ESC[<64;10;5M.
            var k = j
            while k < bytes.count, !(0x40...0x7e).contains(bytes[k]) { k += 1 }
            guard k < bytes.count else { return }
            let param = String(decoding: bytes[j..<k], as: UTF8.self)
            switch bytes[k] {
            case UInt8(ascii: "M") where param.hasPrefix("<"), UInt8(ascii: "m") where param.hasPrefix("<"):
                let f = param.dropFirst().split(separator: ";").compactMap { Int($0) }
                if f.count == 3 {
                    if f[0] == 64 { scroll(-2) }                                         // wheel up
                    else if f[0] == 65 { scroll(2) }                                     // wheel down
                    else if f[0] == 0, bytes[k] == UInt8(ascii: "M") { click(col: f[1], row: f[2]) }
                }
            case UInt8(ascii: "A"): scroll(-2)
            case UInt8(ascii: "B"): scroll(2)
            case UInt8(ascii: "C"): jumpSentence(1)
            case UInt8(ascii: "D"): jumpSentence(-1)
            case UInt8(ascii: "~") where param == "5": scroll(-(bodyRows() - 2))       // PgUp
            case UInt8(ascii: "~") where param == "6": scroll(bodyRows() - 2)          // PgDn
            default: break
            }
            i = k + 1
            continue
        }
        switch b {
        case 0x1b, UInt8(ascii: "q"), 0x03:
            // reader.current = nil
            // reader.synth.stopSpeaking(at: .immediate)
            reader.stop()
            restoreTerminal()
            exit(0)
        case UInt8(ascii: " "):
            reader.togglePause()
        case UInt8(ascii: "n"), UInt8(ascii: "]"):
            jumpItem(1)
        case UInt8(ascii: "p"), UInt8(ascii: "["):
            jumpItem(-1)
        case UInt8(ascii: "j"): scroll(2)
        case UInt8(ascii: "k"): scroll(-2)
        case UInt8(ascii: "g"): scroll(-lines.count)
        case UInt8(ascii: "G"): scroll(lines.count)
        case UInt8(ascii: "f"):
            following = true
            render()
        case UInt8(ascii: "+"), UInt8(ascii: "="), UInt8(ascii: "-"), UInt8(ascii: "_"):
            let up = b == UInt8(ascii: "+") || b == UInt8(ascii: "=")
            rate = max(0.3, min(0.9, rate + (up ? 0.05 : -0.05)))
            // A rate change only takes effect on a new utterance, so restart at this word.
            // Keep the view where it is if you had scrolled away.
            let keep = following
            if finished { render() } else { reader.speak(from: spoken.location); following = keep; render() }
        case UInt8(ascii: "r"):
            reader.speak(from: 0)
        case UInt8(ascii: "s"):
            airy.toggle()
            layout()
            following = true
            render()
        default: break
        }
        i += 1
    }
}

// MARK: Main

for sig in [SIGTERM, SIGHUP, SIGINT] {
    signal(sig) { _ in restoreTerminal(); exit(0) }
}

enterRawMode()
layout()

let winch = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .main)
signal(SIGWINCH, SIG_IGN)
winch.setEventHandler {
    layout()
    previous = []
    print("\u{1b}[2J", terminator: "")
    render()
}
winch.resume()

let input = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: .main)
input.setEventHandler {
    var buf = [UInt8](repeating: 0, count: 64)
    let n = read(STDIN_FILENO, &buf, buf.count)
    if n <= 0 { restoreTerminal(); exit(0) }
    handle(Array(buf[0..<n]))
}
input.resume()

if silent { finished = true; render() } else { reader.speak(from: 0) }
CFRunLoopRun()
