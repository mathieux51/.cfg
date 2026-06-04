// Fires a macOS notification only when opencode is waiting on the user:
//   - permission.asked: a gated bash command, edit, etc. needs approval
//   - question.asked:   the agent is asking a multiple-choice question
export const NotificationPlugin = async ({ $ }) => {
  const notify = async (message) => {
    try {
      await $`osascript -e ${`display notification "${message}" with title "OpenCode" sound name "default"`}`
    } catch {
      // ignore notification failures
    }
  }

  return {
    event: async ({ event }) => {
      if (event.type === "permission.asked") {
        const title = event.properties?.title || event.properties?.type || "approval"
        await notify(`Waiting for approval: ${title}`)
        return
      }

      if (event.type === "question.asked") {
        const first = event.properties?.questions?.[0]
        const label = first?.header || first?.question || "input"
        await notify(`Question needs input: ${label}`)
        return
      }
    },
  }
}
