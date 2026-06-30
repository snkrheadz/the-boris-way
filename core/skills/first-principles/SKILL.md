---
name: first-principles
description: "Rethink from design principles. Go back to fundamentals when stuck. Question assumptions and explore essential solutions. Sibling: to decompose and solve a problem taken as given (rather than re-question it), use /core:deep-thinking. Triggers: /core:first-principles, back to basics, from scratch, zero-base"
user-invocable: true
allowed-tools: Read, Grep, Glob, WebSearch
model: sonnet
---

# First Principles Thinking

A skill for rethinking from fundamentals when stuck or things get too complex.

## When to Use

- Implementation got too complex
- Lost sight of what you were trying to build
- Fixated on a technical solution
- Struggling with trade-off decisions
- Don't understand "why it's this way"

## Thinking Framework

### Step 1: Identify the Essential Problem

```markdown
## What are we trying to solve right now?

**Surface problem**:
(Technical implementation talk)

**Essential problem**:
(Value to user/business)

**Verification questions**:
- If this problem is solved, who benefits and how?
- If this feature didn't exist, what problems would occur?
```

### Step 2: List and Question Assumptions

```markdown
## Implicit Assumptions

List assumptions taken for granted in current implementation:

1. [ ] <assumption 1> → Is this really true?
2. [ ] <assumption 2> → Why do we think this?
3. [ ] <assumption 3> → Is there another way?

**Assumptions to question**:
- "Must be..."
- "Impossible to..."
- "Everyone does it this way"
- "It's always been this way"
```

### Step 3: Re-verify Constraints

```markdown
## Real Constraints vs Assumptions

| Constraint | Type | Basis |
|------------|------|-------|
| Budget $10K | 🔒 Fixed | Already approved |
| Use React | ⚠️ Verify | Just because "team is familiar"? |
| REST API | ⚠️ Verify | Why not GraphQL? |
| Complete in 1 week | 🔒 Fixed | Release date confirmed |
```

### Step 4: Zero-Base Options

```markdown
## If starting over from scratch?

**Options thought from constraints only, from blank slate**:

1. **Option A**: <description>
   - Pros:
   - Cons:

2. **Option B**: <description>
   - Pros:
   - Cons:

3. **Option C (current direction)**: <description>
   - Pros:
   - Cons:

**What's the simplest solution?**
(Cut features, different approach, option to not do it)
```

### Step 5: Decision and Next Actions

```markdown
## Conclusion

**Choice**: Option X

**Reasons**:
1. <reason1>
2. <reason2>

**What to drop**:
- <what to drop>

**Next actions**:
1. [ ] <action1>
2. [ ] <action2>
```

## Question List

Questions to ask yourself when stuck:

### About the Problem
- "First of all, is this a problem worth solving?"
- "Is the problem definition correct?"
- "Who is this feature for?"

### About the Solution
- "What's the simplest solution?"
- "What if we don't build this feature?"
- "How to get 80% of value with 20% of effort?"
- "What if it doesn't have to be perfect?"

### About Assumptions
- "Why do we think this?"
- "Is it a fact or speculation?"
- "Could the opposite be true?"
- "Will this assumption still be valid in 5 years?"

## Output Format

```markdown
## First Principles Analysis

### Current State
**What we're trying to do**:
<description>

**Where we're stuck**:
<description>

---

### Essence

**The real problem to solve**:
<core problem>

**Definition of success**:
<what success looks like>

---

### Assumption Verification

| Assumption | Verification Result |
|------------|---------------------|
| <assumption1> | ✅ Valid / ❌ Invalid / ⚠️ Needs verification |

---

### Options After Rethinking

1. **Simple option**: <description>
2. **Modified current option**: <description>
3. **Don't do it option**: <description>

---

### Recommendation

**Choice**: <option>

**Reason**: <rationale>

**What to cut**: <what to cut>
```

## Notes

- **Avoid analysis paralysis**: Don't overthink, connect to action
- **Don't seek perfection**: Sometimes a 70% solution is enough
- **Share with team**: Don't hold alone, borrow perspectives
- **Time-box**: If no conclusion in 30 minutes, consult
