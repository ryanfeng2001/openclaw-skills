---
name: continuous-learning
description: "Auto-extract patterns, insights from conversations into reusable knowledge. Trigger when session reveals reusable pattern, user says learn or remember this, heartbeat memory maintenance, or after complex task with insights worth saving."
---

# Continuous Learning

Automatically extract reusable patterns from sessions into structured knowledge files.

## Knowledge Hierarchy

```
Raw experience (session)
  → Pattern (reusable solution template)
    → Instinct (high-confidence, auto-applied rule)
```

## Workflow

### 1. Extract Patterns

After completing a complex task or when triggered:

1. Review the current session for:
   - Problems solved and approaches used
   - Mistakes made and how they were fixed
   - Tool combinations that worked well
   - Domain-specific knowledge discovered

2. For each pattern found, create an entry in `memory/learnings/`:

```markdown
## [DATE] Pattern: [SHORT NAME]

**Context:** What problem/situation triggered this
**Solution:** What worked (specific steps)
**Why:** Why this approach worked
**Confidence:** low | medium | high
**Reuse count:** 1
**Tags:** [domain, tool, pattern-type]
```

### 2. Run Learning Cycle (Heartbeat)

During heartbeat memory maintenance, run `scripts/learning-cycle.sh`:

```bash
bash scripts/learning-cycle.sh
```

This script:
- Scans recent `memory/YYYY-MM-DD.md` files for notable events
- Checks `memory/learnings/` for patterns with reuse count >= 3
- Promotes high-reuse patterns to instincts in `memory/instincts.md`
- Prunes patterns not referenced in 30+ days

### 3. Apply Instincts

Instincts are high-confidence rules stored in `memory/instincts.md`. Format:

```markdown
### [NAME]
- **Rule:** [concise instruction]
- **Origin:** [when/how learned]
- **Confidence:** high
- **Evidence:** [examples of success]
```

Instincts are loaded into MEMORY.md when confidence is high and reuse count confirms reliability.

### 4. Learning Evaluation

When user says "learn-eval" or after extracting patterns, assess quality:

| Criteria | Score 0-2 |
|----------|-----------|
| Specificity | Vague -> Precise steps |
| Reusability | One-off -> Broadly applicable |
| Evidence | None -> Multiple confirmations |
| Clarity | Ambiguous -> Crystal clear |

Patterns scoring < 4/8 need refinement before saving. Don't save trivial or obvious patterns.

## File Structure

```
memory/
  learnings/           # Extracted patterns
  instincts.md         # High-confidence auto-applied rules
  YYYY-MM-DD.md        # Daily notes (source material)
```

## Anti-Patterns

- Don't save obvious facts
- Don't save one-off solutions without generalization
- Don't duplicate existing MEMORY.md content
- Don't save without evidence or confidence assessment
- DO generalize specific solutions into reusable patterns
- DO tag patterns for searchability
- DO track reuse count to validate value
