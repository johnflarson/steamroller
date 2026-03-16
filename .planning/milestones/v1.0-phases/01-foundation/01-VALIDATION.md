---
phase: 1
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GUT (Godot Unit Test) v9.x — designed for Godot 4.x |
| **Config file** | `res://addons/gut/` after installation via Godot Asset Library |
| **Quick run command** | `godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_<file>.gd` |
| **Full suite command** | `godot --headless -s addons/gut/gut_cmdln.gd` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run relevant GUT test file
- **After every plan wave:** Run `godot --headless -s addons/gut/gut_cmdln.gd`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | LOOP-01 | unit | `test_board_generation.gd` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | LOOP-02 | unit | `test_state_machine.gd` | ❌ W0 | ⬜ pending |
| 01-01-03 | 01 | 1 | LOOP-03 | unit | `test_highlight.gd` | ❌ W0 | ⬜ pending |
| 01-01-04 | 01 | 1 | LOOP-04 | unit | `test_claim.gd` | ❌ W0 | ⬜ pending |
| 01-01-05 | 01 | 1 | LOOP-05 | unit | `test_turn_advance.gd` | ❌ W0 | ⬜ pending |
| 01-01-06 | 01 | 1 | LOOP-06 | unit | `test_auto_reroll.gd` | ❌ W0 | ⬜ pending |
| 01-01-07 | 01 | 1 | SCOR-01 | unit | `test_scoring.gd` | ❌ W0 | ⬜ pending |
| 01-01-08 | 01 | 1 | SCOR-02 | unit | `test_scoring.gd` | ❌ W0 | ⬜ pending |
| 01-01-09 | 01 | 1 | WIN-01 | unit | `test_win_condition.gd` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/test_board_generation.gd` — stubs for LOOP-01
- [ ] `test/unit/test_state_machine.gd` — stubs for LOOP-02
- [ ] `test/unit/test_highlight.gd` — stubs for LOOP-03
- [ ] `test/unit/test_claim.gd` — stubs for LOOP-04
- [ ] `test/unit/test_turn_advance.gd` — stubs for LOOP-05
- [ ] `test/unit/test_auto_reroll.gd` — stubs for LOOP-06
- [ ] `test/unit/test_scoring.gd` — stubs for SCOR-01, SCOR-02
- [ ] `test/unit/test_win_condition.gd` — stubs for WIN-01
- [ ] GUT addon installed via Godot Asset Library

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual highlight of valid cells | LOOP-03 | Requires visual inspection of button colors | Roll dice, verify matching cells show highlight color |
| Player color on claimed cells | LOOP-04 | Requires visual inspection | Claim cell, verify button shows correct player color |
| Game log auto-reroll message | LOOP-06 | Log display is UI-only | Create scenario where no valid cells exist, verify log shows reroll |
| Win screen blocks input | WIN-01 | UI interaction test | Reach 5 points, verify roll button and cells are disabled |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
