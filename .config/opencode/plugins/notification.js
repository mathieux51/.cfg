export const NotificationPlugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await $`osascript -e 'display notification "Ready for input" with title "OpenCode" sound name "default"'`
      }
      if (event.type === "session.error") {
        await $`osascript -e 'display notification "An error occurred" with title "OpenCode" sound name "Basso"'`
      }
    },
  }
}
