export const NotificationPlugin = async ({ $, client }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        const session = await client.sessionGet({ path: { id: event.properties.sessionID } })
        if (session.data?.parentID) return
        await $`osascript -e 'display notification "Ready for input" with title "OpenCode" sound name "default"'`
      }
      if (event.type === "session.error") {
        if (event.properties.sessionID) {
          const session = await client.sessionGet({ path: { id: event.properties.sessionID } })
          if (session.data?.parentID) return
        }
        await $`osascript -e 'display notification "An error occurred" with title "OpenCode" sound name "Basso"'`
      }
    },
  }
}
