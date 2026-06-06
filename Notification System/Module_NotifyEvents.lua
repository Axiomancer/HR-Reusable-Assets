--!Type(Module)

-- Notification event bus. Standalone -- no dependency on any other module.
--
-- Fire from server:
--   NotifyEvents.Notification:FireClient(player, "success", "Title", "Body text", 4)
--   NotifyEvents.Notification:FireAllClients("warning", "Title", "Body text", 5)
--
-- Types: "success" | "error" | "warning" | "info" | "default"
-- Timeout: seconds before the card auto-hides (default 4)

-- Server -> Client or All Clients
-- Payload: (notifType: string, title: string, text: string, timeout: number)
Notification = Event.new("Notification")
