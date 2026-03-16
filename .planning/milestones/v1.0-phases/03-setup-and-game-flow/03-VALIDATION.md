---
phase: 3
slug: setup-and-game-flow
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — manual testing via Godot 4 editor (F5) |
| **Config file** | none |
| **Quick run command** | Open `project.godot` in Godot 4 editor, press F5 |
| **Full suite command** | Manual play-through: start game, configure 2/3/4 players, verify all flows |
| **Estimated runtime** | ~60 seconds (manual) |

---

## Sampling Rate

- **After every task commit:** Run game in editor (F5), verify the specific task's behavior
- **After every plan wave:** Full play-through: select players, enter names, play to win, return to setup
- **Before `/gsd:verify-work`:** All three requirements verified manually
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | SETUP-01 | manual-smoke | Run game: verify count buttons appear, default 2 | N/A | ⬜ pending |
| 03-01-02 | 01 | 1 | SETUP-02 | manual-smoke | Run game: verify name fields, pre-fill, 15 char max | N/A | ⬜ pending |
| 03-01-03 | 01 | 1 | SETUP-01, SETUP-02 | manual-smoke | Run game: verify count toggle shows/hides name fields | N/A | ⬜ pending |
| 03-02-01 | 02 | 1 | WIN-03 | manual-smoke | Play to win, click New Game: verify setup screen shown | N/A | ⬜ pending |
| 03-02-02 | 02 | 1 | WIN-03 | manual-smoke | Return to setup: verify previous names and count preserved | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework needed — manual testing via Godot editor is the established project standard.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Player count selection (2/3/4 toggles) | SETUP-01 | UI interaction requires visual verification | Run game, click each count button, verify name fields show/hide |
| Name entry with pre-fill, max length, Enter chain | SETUP-02 | Text input behavior requires manual interaction | Type in fields, verify 15 char limit, press Enter to advance |
| Win screen → New Game → setup with state preserved | WIN-03 | End-to-end flow requires full play-through | Play to win, click New Game, verify setup shows with previous names |
| Fade transitions (~0.2s) | UX quality | Visual smoothness requires human judgment | Observe transitions between setup↔game and game-over→setup |

---

## Validation Sign-Off

- [ ] All tasks have manual-smoke verification steps
- [ ] Sampling continuity: every task verified by running game in editor
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
