# kokoro-serve: speech for speakview's English replies, from the Kokoro model.
# Loading the model takes ~10 s, too long to wait at every Cmd+Shift+R, so this
# runs in the background on a Unix socket: the first speakview starts it, later
# ones connect at once. It exits after 30 minutes without a connection.
#
#   uv run --project ~/.local/src/speakview/kokoro kokoro-serve.py SOCKET OUTDIR
#
# One speakview at a time. Over the connection, it sends {"ready": true}, then
# reads one JSON request per line, each replacing the one before:
#   {"id": 3, "text": "...", "speed": 1.2}
# and answers with one JSON line per chunk of audio, in order:
#   {"id": 3, "wav": "OUTDIR/3-0.wav", "words": [[at, len, start, end], ...]}
#   {"id": 3, "done": true}
# `at` and `len` are UTF-16 offsets into the request's text, as Swift's NSString
# counts them; `start` and `end` are seconds from the start of that chunk's wav.

import json
import os
import queue
import socket
import sys
import threading

import soundfile as sf
from kokoro import KPipeline

VOICE = os.environ.get("SPEAK_KOKORO_VOICE", "af_heart")
IDLE_EXIT = 30 * 60

sock_path, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)

# Another copy may already be serving (two popups opened at once): leave it be.
probe = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    probe.connect(sock_path)
    sys.exit(0)
except OSError:
    pass
finally:
    probe.close()

pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")


def utf16(s: str, i: int) -> int:
    return len(s[:i].encode("utf-16-le")) // 2


def chunks(text: str, speed: float):
    """Yield (n, audio, words) for each chunk of `text`, in reading order."""
    cursor = 0  # where to look for the next word, in code points
    for n, result in enumerate(pipeline(text, voice=VOICE, speed=speed)):
        if result.audio is None:
            continue
        words = []
        for tok in result.tokens or []:
            if tok.start_ts is None or not any(c.isalnum() for c in tok.text):
                continue
            # Tokens come back in reading order, so each one is found after the last.
            # A token the model rewrote is skipped rather than matched far ahead.
            i = text.find(tok.text, cursor, cursor + len(tok.text) + 200)
            if i < 0:
                continue
            cursor = i + len(tok.text)
            at = utf16(text, i)
            words.append([at, utf16(text, cursor) - at, tok.start_ts, tok.end_ts])
        yield n, result.audio, words


def handle(conn: socket.socket):
    rfile, wfile = conn.makefile("r"), conn.makefile("w")
    requests: "queue.Queue[dict | None]" = queue.Queue()
    latest = {"id": -1}

    def read():
        for line in rfile:
            try:
                req = json.loads(line)
            except ValueError:
                continue
            latest["id"] = req["id"]
            requests.put(req)
        requests.put(None)  # speakview closed

    def send(obj):
        wfile.write(json.dumps(obj) + "\n")
        wfile.flush()

    threading.Thread(target=read, daemon=True).start()
    send({"ready": True})
    while (req := requests.get()) is not None:
        rid = req["id"]
        if rid != latest["id"]:
            continue
        for n, audio, words in chunks(req["text"], req.get("speed", 1.0)):
            if latest["id"] != rid:
                break
            wav = os.path.join(outdir, f"{rid}-{n}.wav")
            sf.write(wav, audio.numpy(), 24000)
            try:
                send({"id": rid, "wav": wav, "words": words})
            except OSError:
                os.unlink(wav)  # speakview deletes the ones it receives
                raise
        else:
            send({"id": rid, "done": True})


if os.path.exists(sock_path):
    os.unlink(sock_path)
server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(sock_path)
server.listen(4)
server.settimeout(IDLE_EXIT)
while True:
    try:
        conn, _ = server.accept()
    except socket.timeout:
        break
    conn.settimeout(None)
    try:
        handle(conn)
    except OSError:
        pass  # speakview went away mid-reply
    finally:
        conn.close()
os.unlink(sock_path)
