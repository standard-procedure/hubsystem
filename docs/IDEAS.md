# Ideas

Scratch pad for ideas, half-thoughts, and things to revisit. Add entries here so they don't get lost.

---

## System-level event bus

HubSystem should have a system-wide event feed — an internal event bus that acts as the backbone for decoupled communication between bounded contexts (DDD style). Components publish events; other components subscribe without knowing about each other.

**First use case: workflow engine**

When a domain event fires (e.g. "ticket created", "ticket marked done"), it can trigger a workflow — a state machine that moves through defined stages. At each stage a workflow can:
- Invoke a Synthetic to do analysis or make a decision
- Ask a human user for input (and branch based on their answer)
- Trigger external actions

Example — ticket lifecycle:
1. Ticket created → workflow starts
2. Synthetic evaluates complexity and best assignee
3. Workflow reports back to creator: "Here's our recommendation — want to kick it off?"
4. Creator confirms → ticket assigned, work begins
5. Ticket marked done → workflow triggers code review
6. Code review complete → workflow reports outcome to creator

**Design notes to consider**
- Event bus should live in `server/` as the shared hub (all participants publish/subscribe via the API or ActionCable)
- Workflows are likely their own bounded context — separate from conversations, tasks, and the Governor feed
- Synthetic participation in a workflow is just the normal API/WebSocket interface — no special coupling
- State machine could be something like `state_machines` gem or a simple JSONB column with explicit transition methods
- "Ask a user for input" could be modelled as a conversation turn — the workflow parks itself waiting for a reply event
