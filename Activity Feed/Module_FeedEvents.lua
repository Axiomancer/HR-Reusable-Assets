--!Type(Module)

-- Activity Feed event bus.
-- Drop this file into your project alongside UI_ActivityFeed.
--
-- From any server script, fire:
--   FeedEvents.ActivityLog:FireAllClients("iconKey", "Your message here")
--
-- iconKey must match one of the --!SerializeField slots you fill in the Inspector.
-- Any unrecognised key falls back to the iconDefault slot.

-- Server -> All Clients
-- Payload: (iconKey: string, message: string)
ActivityLog = Event.new("ActivityLog")
