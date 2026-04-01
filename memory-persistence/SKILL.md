---
name: memory-persistence
description: "Automatic session lifecycle hooks for context preservation across sessions. Trigger when session is ending or being compacted, heartbeat triggers memory maintenance, user asks to save or restore session context, or before destructive operations that might lose context."
---

# Memory Persistence

Preserve and restore session context automatically across session boundaries.

## Architecture

```
Session Start -> Load checkpoint + recent context
Session Active -> Auto-save on milestones
Session End -> Save full state checkpoint
Pre-Compact -> Snapshot before context compression
```

## State Files

All state stored in `memory/state/`:

```
memory/state/
  checkpoint.json      # Last session state snapshot
  active-context.md    # Current working context
  pending-tasks.md     # Unfinished tasks from last session
  session-meta.json    # Session metadata (timestamps, tokens)
```

## Workflow

### Session Start

Run `scripts/session-restore.sh`:

```bash
bash scripts/session-restore.sh
```

This loads:
1. Last checkpoint summary and pending tasks
2. Today's and yesterday's daily notes
3. Session metadata (last save time, save count)

Present a brief "last session" summary to user if relevant.

### Session End / Checkpoint

Run `scripts/session-save.sh`:

```bash
# Full save
bash scripts/session-save.sh --full

# Quick milestone save
bash scripts/session-save.sh --quick
```

Full save updates:
- `checkpoint.json` with current tasks, decisions, modified files
- `pending-tasks.md` with unfinished items
- `session-meta.json` with timestamps

### Auto-Save Milestones

During a session, automatically save when:
- A complex task completes (code deployed, config changed)
- An important decision is made
- Files are modified outside workspace
- User explicitly says "save" or "checkpoint"

### Pre-Compact Snapshot

Before context compaction, save a timestamped snapshot so nothing critical is lost.

## Checkpoint Format

```json
{
  "timestamp": "2026-03-31T16:00:00+08:00",
  "summary": "Brief session summary",
  "active_tasks": ["Task 1", "Task 2"],
  "files_modified": ["/path/to/file"],
  "key_decisions": ["Decision made and why"],
  "pending_items": ["What's left to do"]
}
```

## Integration with Heartbeat

During heartbeats, run lightweight persistence check:

1. If `active-context.md` is stale (>1 hour), update it
2. If `pending-tasks.md` has items, mention them in heartbeat response
3. If session active >2 hours, suggest a checkpoint

## Anti-Patterns

- Don't save entire conversation (too large)
- Don't auto-restore old context without checking relevance
- Don't checkpoint trivial interactions
- DO save decisions, modified files, and pending tasks
- DO keep summaries concise (under 200 words)
- DO clean up old snapshots (older than 7 days)
