---
name: implementation-workflow
description: "Full software development lifecycle: plan, spike/sketch, TDD, debug, implement via subagents, code review, simplify cleanup. Umbrella for systematic-debugging, test-driven-development, requesting-code-review, simplify-code, spike, and sketch."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [planning, implementation, delegation, subagent, review, workflow, TDD]
---

# Implementation Workflow

End-to-end workflow for planning and executing multi-step features: write a concrete plan, dispatch fresh subagents per task, and review with two-stage quality gates.

---

## Phase 1: Plan Mode

When the user wants a plan instead of execution (or uses `/plan`):

- **Do not implement code** or edit project files (except the plan)
- **Do not run mutating commands** — read-only inspection is OK
- **Deliverable:** markdown plan saved to `.hermes/plans/YYYY-MM-DD_HHMMSS-<slug>.md`

### Plan Requirements

Include when relevant:
- Goal and current context/assumptions
- Proposed approach with step-by-step tasks
- Files likely to change (exact paths)
- Tests / validation steps
- Risks, tradeoffs, open questions

For code tasks, include exact file paths, test targets, and verification steps.

---

## Phase 2: Write Implementation Plans

**Core principle:** A good plan makes implementation obvious. If someone has to guess, the plan is incomplete.

### Task Granularity

**Each task = 2-5 minutes of focused work.** One action per step:

```markdown
### Task 1: Create User model with email field
**Objective:** Add the User model
**Files:** Create `src/models/user.py`, Test `tests/models/test_user.py`

**Step 1: Write failing test**
[complete test code]

**Step 2: Run test to verify failure**
Run: `pytest tests/models/test_user.py -v`
Expected: FAIL — "function not defined"

**Step 3: Write minimal implementation**
[complete implementation code]

**Step 4: Run test to verify pass**
Run: `pytest tests/models/test_user.py -v`
Expected: PASS

**Step 5: Commit**
`git add src/models/user.py tests/models/test_user.py && git commit -m "feat: add User model"`
```

### Principles

- **DRY** — extract shared logic, don't copy-paste
- **YAGNI** — implement only what's needed now
- **TDD** — every code task: write failing test → verify fail → implement → verify pass → commit
- **Frequent commits** — after every task
- **Exact file paths** — not "the config file" but `src/config/settings.py`
- **Complete code** — copy-pasteable, not "add validation" stubs

### Plan Document Structure

```markdown
# [Feature] Implementation Plan

> **For Hermes:** Use subagent-driven-development to implement task-by-task.

**Goal:** [one sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [key technologies]

---

### Task 1: [Name]
[full task spec with TDD steps]

### Task 2: [Name]
[full task spec]
```

---

## Phase 3: Execute via Subagents

**Core principle:** Fresh subagent per task + two-stage review = high quality, fast iteration.

### Per-Task Workflow

**Step 1: Dispatch Implementer**
```python
delegate_task(
    goal="Implement Task 1: Create User model",
    context="TASK: [full task text]\nFOLLOW TDD: [steps]\nPROJECT CONTEXT: [details]",
    toolsets=['terminal', 'file']
)
```

**Step 2: Spec Compliance Review**
```python
delegate_task(
    goal="Review if implementation matches the spec",
    context="ORIGINAL SPEC: [requirements]\nCHECK: [checklist]\nOUTPUT: PASS or list of gaps.",
    toolsets=['file']
)
```
If issues found → fix → re-review until PASS.

**Step 3: Code Quality Review**
```python
delegate_task(
    goal="Review code quality",
    context="FILES: [list]\nCHECK: conventions, error handling, naming, tests, security\nOUTPUT: APPROVED or REQUEST_CHANGES",
    toolsets=['file']
)
```
If issues found → fix → re-review until APPROVED.

**Step 4: Mark Complete**
```python
todo([{"id": "task-1", "content": "...", "status": "completed"}], merge=True)
```

### Final Integration Review

After ALL tasks complete:
```python
delegate_task(
    goal="Review entire implementation for consistency",
    context="All tasks complete. Check: components work together? inconsistencies? all tests passing?",
    toolsets=['terminal', 'file']
)
```

---

## Red Flags — Never Do These

- Start implementation without a plan
- Skip reviews (spec OR quality)
- Proceed with unfixed critical issues
- Dispatch multiple implementers for tasks touching the same files (use API contract for different files in same project)
- Make subagent read the plan file (provide full text in context)
- Skip scene-setting context for subagents
- Accept "close enough" on spec compliance
- Start quality review before spec compliance passes
8. **Let implementer self-review replace actual review** — always have a separate reviewer
9. **Reporting success without testing** — never say "done" until the app launches, loads real data, and produces no crash logs. Compilation ≠ working.

## Handling Issues

- **Subagent asks questions:** Answer clearly before letting them proceed
- **Reviewer finds issues:** Implementer fixes → reviewer re-reviews → repeat until approved
- **Subagent fails:** Dispatch new fix subagent with specific instructions about what went wrong

## Integration with Other Skills

- **TDD:** Every code task follows write-failing-test → implement → verify-pass
- **Code review:** The two-stage review IS the code review
- **Debugging:** If subagent hits bugs, follow systematic-debugging before fixing

## Variant: Parallel Module Build with API Contract

When building a multi-module project (Core/UI/Metal, Backend/Frontend, etc.) with parallel agents, **API mismatches between modules are the #1 failure mode**. Agents independently choose different function signatures, parameter names, and type conventions, producing code that compiles individually but fails catastrophically when merged.

### The Problem

Without coordination, Agent A writes:
```swift
public func process(_ pixels: inout [Float]) { ... }
```
While Agent B writes:
```swift
pipeline.process(pixels: working, width: w, height: h) -> [Float]
```
Result: 50-100 compile errors from API mismatches. Hours wasted fixing.

### The Solution: API Contract Document

Before dispatching parallel agents, write a single `API-CONTRACT.md` that defines EVERY cross-module interface:

```markdown
# API Contract — All modules MUST follow exactly

## ModuleA.swift
public func load(path: String) throws
public func process() -> [Float]
public var width: Int, height: Int

## ModuleB.swift
public func apply(to pixels: [Float]) -> [Float]
public func toDict() -> [String: Any]
```

Each agent receives the FULL contract plus their implementation details. They implement their module to match the contract EXACTLY — no creative API design allowed.

### Workflow

```python
# Step 1: Write API contract (you, not agents)
write_file("API-CONTRACT.md", contract_text)

# Step 2: Dispatch parallel agents with contract
delegate_task(tasks=[
    {"goal": "Create ModuleA following API-CONTRACT.md exactly",
     "context": "Contract: [full text]\nSpec: [details]"},
    {"goal": "Create ModuleB following API-CONTRACT.md exactly",
     "context": "Contract: [full text]\nSpec: [details]"},
])

# Step 3: Build + fix any remaining mismatches
terminal("swift build")  # or equivalent
```

### What the Contract Must Cover

- **Every public function signature** — name, parameter labels, return type
- **Every public property** — name, type, default value
- **Every enum** — name, cases, raw value type
- **Every struct/class init** — parameter names and types
- **Global functions** — especially `clamp()`, logging helpers
- **Type conventions** — flat arrays vs SIMD, String vs URL, Optional vs non-optional

### When to Use This Pattern

- Multi-module Swift/TypeScript/Rust projects with parallel agents
- Any project where 2+ agents build different files that import each other
- When the project has a shared type system (models, protocols, interfaces)

### When NOT to Use

- Single-agent tasks (just implement directly)
- Tasks touching the same files (sequential, not parallel)
- Simple scripts with no cross-module dependencies

### Critical Pitfall: Multi-Agent API Mismatch

When dispatching multiple agents to implement different modules of the SAME project, agents will write incompatible APIs if left to their own devices. This causes 50-100+ compilation errors that take longer to fix than rewriting from scratch.

**Mandatory pattern — API Contract:**
1. Before dispatching agents, write a shared `API-CONTRACT.md` defining EVERY public type, method signature, and property
2. Include the contract text IN EACH AGENT'S CONTEXT (don't just reference a file path — agents don't read files reliably)
3. Each agent must verify `swift build` compiles before reporting success
4. After all agents complete, do a FINAL integration build

**What goes in the contract:**
- Every `public class/struct/enum` with exact property names and types
- Every `public func` with exact parameter labels and return types
- Init signatures
- Which module owns which type (to avoid redefinition)

**Example failure without contract:** Agent A writes `process(inout [Float])` while Agent B calls `process([Float]) -> [Float]`. Agent C defines `SamplingMode` at file scope while Agent B defines it inside a class. Result: 93 errors, 2+ hours of manual fixes.

**Example success with contract:** All 3 agents read the same API spec, write compatible code, build passes on first integration.

### Variant: 3-Profile Parallel Cracking (Reverse Engineering Task)

When the user wants to bypass IAP / reverse-engineer a macOS app, use this specialized 3-profile workflow:

**Phase 1 — Research (`delegate_task` to researcher profile):**
- `strings` / `grep` for unlock-related keywords (unlock, purchase, fullunlock, showPurchaseSheet, Freemium, SizeToggle, proxy, exportSize)
- `otool -Iv` for StoreKit framework linkage
- `nm` for exported symbols
- `python3` binary scanning for hardcoded numeric constants (search BOTH uint16 and uint32 LE)
- Output: structured report with exact file offsets, class names, key strings found

**Phase 2 — Build crack (coder profile, reads research output):**
If dylib injection: write `.m` dylib, compile, deploy, sign
If binary patch: patch ALL instances of numeric constant, resign
Compile command template:
```bash
clang -shared -o bypass.dylib bypass.m \
  -framework Foundation -framework StoreKit -arch arm64 -fobjc-arc -fmodules
```

**Phase 3 — Verify (reviewer profile):**
- Check crash logs: `cat ~/Library/Logs/DiagnosticReports/APP*.ips | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('termination',{}).get('namespace',''))"`
- Verify dylib injection logs: `log show --predicate 'eventMessage CONTAINS "bypass"' --last 15s`
- Code signing check: `codesign -dvvv App.app`

**Key constraints from user feedback:**
- Do NOT build external standalone tools ("在这个APP裡面做" — do it inside the app)
- Do NOT propose workarounds the user didn't ask for
- Test every iteration; report failures honestly with NO fabricated assertions

For large refactoring tasks where the codebase needs investigation before changes:

### Phase 1: Research (parallel)
```python
delegate_task(tasks=[
    {"goal": "Read conversation history / issue tracker for bugs and requirements",
     "toolsets": ["terminal", "file"]},
    {"goal": "Analyze competitor/reference app for feature comparison",
     "toolsets": ["terminal", "file"]}
])
```

### Phase 2: Code (parallel, based on research findings)
```python
delegate_task(tasks=[
    {"goal": "Fix bug group A", "context": "from research...", "toolsets": ["terminal", "file"]},
    {"goal": "Add feature group B", "context": "from research...", "toolsets": ["terminal", "file"]}
])
```

### Phase 3: Review + Test (sequential)
```python
# Build verification
terminal("swift build")  # or equivalent
# Functional test with real data files
terminal("open App.app")  # launch and check logs
terminal("ls -lt ~/Library/Logs/DiagnosticReports/ | grep App")  # crash check
```

### User preference: "测试完你觉得没问题，再给我最终版"
Always test with real data before reporting completion. Don't just verify compilation — launch the app, load test files, check crash logs, verify no regressions.

## Pitfalls

1. **Too-big tasks** — "Implement authentication system" is 10+ tasks, not 1
2. **Vague steps** — "Add validation" without the actual code
3. **Missing verification** — every step needs an exact command with expected output
4. **Context pollution** — fresh subagent per task prevents accumulated state confusion
5. **Wrong review order** — spec compliance FIRST, code quality SECOND
6. **Subagent timeout (600s)** — each subagent has a hard 600-second limit. Tasks that require writing 10+ files WILL time out. Split into smaller batches (3-5 files per agent max). If a task times out, the partially-written code is still on disk — verify what was created before re-dispatching.
7. **Inter-agent API mismatch** — when multiple agents write code in parallel, they WILL invent incompatible APIs (different method signatures, different type names, different parameter orders). **Always create an API contract document first** and pass it to all agents. The contract should specify exact function signatures, types, and parameter names. See `references/api-contract-pattern.md`.
8. **Parallel agents modifying the same file** — agents will overwrite each other's changes. Ensure each agent writes to DISJOINT file sets. If two agents need to modify the same file, serialize them (agent 2 reads agent 1's output).
7. **API drift across parallel agents** — when dispatching 3 agents to build Core/UI/Metal simultaneously, each agent invents its own function signatures, parameter types, and return values. The result: 50-100 compilation errors from type mismatches. **Fix:** Write an explicit `API-CONTRACT.md` before dispatching. Every function signature, parameter type, return type, and enum case must be specified. Each agent reads the contract and MUST NOT deviate. This reduced errors from 93 to 0 in one session.
8. **Subagent timeout on large tasks** — 600s timeout is not enough for building an entire module (10+ files, 1000+ lines). Agents get stuck on slow API calls or iterative compilation fixes. **Fix:** Split into smaller tasks (3-5 files per agent max). Pre-create Package.swift and stub files. If an agent times out, check what it DID create before re-dispatching — partial progress is often salvageable.
9. **Copy exactly instructions** — when the user says to replicate a reference app (照搬照抄), do NOT add creative interpretations, simplifications, or improvements. Match the reference pixel-for-pixel. The user will notice and be frustrated if you deviate, even if you think your version is better.

10. **Color science replication requires exact pipeline order** — When reverse-engineering a color/image processing app, the exact order of operations determines color quality. Copy exactly means:
    - Copy the EXACT formula for each step (not an equivalent approximation)
    - Copy the EXACT color space (Linear sRGB vs sRGB gamma vs ACEScg — different = wrong colors)
    - Copy the EXACT percentile values for auto-analysis (0.5% vs 1% = visible difference)
    - Verify against the reference app on the SAME test image — if the output looks different, the pipeline is wrong
    - User feedback: when the output looks wrong, they will say completely different quality level (完全跟那个negbase不是一个档次)

11. **Show raw data first, process on demand** — When reimplementing a processing app with a load-then-process workflow (like negative film scanners):
    - Load: display RAW input pixels as-is, do NOT process
    - User action (crop, rotate, auto button): ONLY THEN run the processing pipeline
    - This differs from auto-process-on-load which destroys the users ability to see the original
    - User feedback: 导入之后，你应该把我的导入的原始的东西给我呈现出来。我进行裁剪之后，点击自动校色，之后软件再帮我还原颜色
11. **Don't modify pixels when the task is spatial only** — When the user asks you to crop, cut, split, resize, or rearrange images, do NOT apply any color/tonal processing. No gamma correction, no white balance, no pixel value scaling, no "enhancement". The exported file must have the same pixel values as the input. If the user says "输出颜色都变了" (colors changed), you touched pixels you shouldn't have. Only the original image array should be written to output. Read → crop region → write-back directly, with zero intermediate processing.

12. **Installing CLIs / tools — don't guess, read docs** — when the user asks to install a specific CLI tool, do NOT guess the package name from associations. Example: user says "装千问CLI" — do NOT guess `pip install dashscope` or `npm install @alicloud/qwen`. If the user provides a URL, read it and follow it EXACTLY. If no URL, search for official installation docs. After installing, verify with `which <tool>` and a simple smoke test (`tool --version`). Never add unasked configuration (e.g. API keys in unrelated places like Hermes config when the user only asked for the CLI). The user's frustration signal is "不要乱搞" or "我说东你做西" — follow instructions exactly, no creative additions.

### Variant: Multi-Module Swift Projects with 3-Profile Dispatch

When building a multi-module Swift project (Core/UI/Metal) with parallel subagents:

**Step 0 (CRITICAL): Write API Contract**
Create `API-CONTRACT.md` listing EVERY public type, function, property with exact signatures. Example:
```
public func load(path: String) throws
public func process() -> [Float]
public var dmin: SIMD3<Float> { get set }
```
Without this, agents write `func load(from: URL) -> ImageData?` vs `func load(path: String) throws` and nothing compiles.

**Step 1: Dispatch Core agent first** (or all 3 in parallel with contract)
Core creates Package.swift + all engine files. Must follow contract exactly.

**Step 2: Dispatch UI agent**
UI creates all view files. Must import Core types from contract, never redefine them.

**Step 3: Dispatch Metal/App agent**
Metal renderer + shaders + app entry point.

**Step 4: Compile and fix drift**
Even with a contract, expect 5-10 minor fixes (missing imports, optional unwrapping). Fix iteratively.

## Extended References

| Reference | Content |
|-----------|---------|
| [references/gates-taxonomy.md](references/gates-taxonomy.md) | Four canonical gate types (Pre-flight, Revision, Escalation, Abort) |
| [references/context-budget-discipline.md](references/context-budget-discipline.md) | Context degradation model and read-depth rules |
| [references/writing-plans-full.md](references/writing-plans-full.md) | Complete writing-plans skill with examples |
| [references/subagent-driven-development-full.md](references/subagent-driven-development-full.md) | Complete subagent-driven-development skill |
| [references/api-contract-pattern.md](references/api-contract-pattern.md) | API contract pattern for multi-agent parallel development |
| [references/parallel-independent-workstreams.md](references/parallel-independent-workstreams.md) | Dispatch 3+ parallel independent agents via delegate_task |
| [references/debugging-computer-vision-pipelines.md](references/debugging-computer-vision-pipelines.md) | Debug signal-processing CV pipelines — validate against raw pixel data |
| [references/film-strip-frame-detection.md](references/film-strip-frame-detection.md) | Precise frame boundary detection for scanned film strips — luminance-based dark-band localization |

### Absorbed sub-skills (now under `references/`)

| Directory | Former skill | Covers |
|-----------|-------------|--------|
| `references/systematic-debugging.md` | `systematic-debugging` | 4-phase root cause debugging: investigate, pattern analysis, hypothesis testing, implementation. Red flags, anti-rationalization table, Hermes tool integration |
| `references/test-driven-development.md` | `test-driven-development` | Strict RED-GREEN-REFACTOR cycle, iron law (tests before code), anti-rationalization table, integration with debugging and delegation |
| `references/requesting-code-review.md` | `requesting-code-review` | Pre-commit verification pipeline: static security scan, baseline-aware quality gates, independent reviewer subagent, auto-fix loop with 2-cycle limit |
| `references/simplify-code.md` | `simplify-code` | Parallel 3-agent code cleanup (reuse/quality/efficiency reviewers), aggregate findings, apply fixes, verify no breakage |
| `references/spike.md` | `spike` | Throwaway experiments: decompose into feasibility questions, research approaches, build minimal working test, produce VALIDATED/PARTIAL/INVALIDATED verdict |
| `references/sketch.md` | `sketch` (was in `creative/`) | Throwaway HTML mockups: 2-3 design variants per stance, head-to-head comparison table, browser verification, frontier mode for what-to-sketch-next |
