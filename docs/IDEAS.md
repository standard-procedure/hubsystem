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

**Design notes**
- Event bus should live in `server/` as the shared hub (all participants publish/subscribe via the API or ActionCable)
- Workflows are likely their own bounded context — separate from conversations, tasks, and the Governor feed
- Synthetic participation in a workflow is just the normal API/WebSocket interface — no special coupling
- State machine could be something like `state_machines` gem or a simple JSONB column with explicit transition methods
- "Ask a user for input" could be modelled as a conversation turn — the workflow parks itself waiting for a reply event

---

## Sandbox container: per-Synthetic Unix users + Superintendent

The spare Ubuntu sandbox container mounts a volume at `/home`. Each Synthetic gets its own Unix user (`/home/sid`, `/home/alice`, etc.), giving them isolated home directories and file permissions — Synthetics cannot read each other's workspaces by default.

**The Superintendent**

A dedicated Superintendent Synthetic is the only account with `sudo` access. When any other Synthetic wants to install software or run a privileged command, it must ask the Superintendent via a normal HubSystem conversation. The Superintendent evaluates the request and — if approved — runs the `sudo` command itself.

Benefits:
- All privileged operations are logged as conversations in HubSystem, not buried in a shell history
- The Governor applies to the Superintendent's decisions like any other Synthetic response
- A rogue or compromised Synthetic cannot escalate privileges unilaterally
- The approval trail is human-readable and auditable without any extra tooling

**Design notes**
- Container user provisioning could be handled at startup by the devcontainer setup or a world/ bootstrap script
- The Superintendent's Archetype would need a specific Governor prompt around software installation policy (what's allowed, what requires human sign-off)
- SSH or `nsenter` from `world/` into the sandbox as the correct Unix user keeps the isolation clean
- Could extend to resource limits per user (`ulimit`, cgroups) so one Synthetic can't monopolise CPU/disk
- The "ask the Superintendent" pattern is a good template for other capability-gating scenarios beyond sudo

**Scalability of Linux users**

Linux itself handles tens of thousands of user accounts without issue — `/etc/passwd` is just a flat file and the kernel doesn't care. The real constraints at scale would be:
- Disk: each home directory consuming space (mitigated by quotas)
- Process limits: per-user `ulimit` keeping any one Synthetic from forking out of control
- The sandbox container's RAM/CPU, not the user account count itself

At very large scale (thousands of active Synthetics) the bigger question is whether a single sandbox container is the right unit — you'd likely shard Synthetics across multiple sandbox containers, each with their own Superintendent, rather than fight OS limits. The per-user isolation model still holds at that point, just distributed.

**Superintendent as process supervisor**

The Superintendent should also have read access to process and resource information on the `world/` container — `top`, `ps`, `/proc` stats, or equivalent. This lets it:
- Notice a Synthetic consuming runaway CPU or memory and intervene (or report to a human)
- Correlate "Sid asked to install X" with "Sid's process spiked immediately after" 
- Act as a genuine supervisor-of-supervisors: async-service restarts crashed Synthetics automatically, but the Superintendent watches for degraded-but-not-crashed behaviour that automated restart can't catch

This keeps operational visibility inside the same conversation/Governor/audit-trail system rather than requiring separate monitoring infrastructure.
