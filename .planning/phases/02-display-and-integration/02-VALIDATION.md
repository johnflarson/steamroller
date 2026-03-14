---
phase: 2
slug: display-and-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Godot 4 built-in scene runner (no external test framework) |
| **Config file** | none — validated via Godot editor Play + HTML5 export smoke test |
| **Quick run command** | Open Godot editor, press F5 (Play Scene) |
| **Full suite command** | F5 play + HTML5 export + open in browser |
| **Estimated runtime** | ~30 seconds (manual visual verification) |

---

## Sampling Rate

- **After every task commit:** F5 play, verify the specific requirement changed
- **After every plan wave:** Full visual check of all 7 requirements + HTML5 smoke test
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | UI-01 | visual/manual | F5, observe current player badge | ✅ main.gd | ⬜ pending |
| 2-01-02 | 01 | 1 | UI-02 | visual/manual | F5, press Roll, observe large number | ✅ main.gd | ⬜ pending |
| 2-01-03 | 01 | 1 | UI-03 | visual/manual | F5, observe score strip | ✅ main.gd | ⬜ pending |
| 2-01-04 | 01 | 1 | UI-04 | visual/manual | F5, observe color-coded log | ✅ main.gd | ⬜ pending |
| 2-02-01 | 02 | 1 | SCOR-03 | visual/manual | F5, play to score event | ✅ main.gd | ⬜ pending |
| 2-03-01 | 03 | 1 | WIN-02 | visual/manual | F5, reach 5 points | ✅ main.gd | ⬜ pending |
| 2-04-01 | 04 | 2 | UI-05 | smoke test | HTML5 export + open in browser | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] HTML5 export preset configured in Godot (Web export with threads disabled) — covers UI-05
- [ ] `serve.py` downloaded or single-threaded export used for local testing

*Existing infrastructure covers all other phase requirements (visual verification via F5).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Claimed cells show player color | UI-01 | Visual appearance — no automated pixel testing available | F5, claim cells as different players, verify colors match palette |
| Scale pop animation on scoring | SCOR-03 | Animation timing — requires visual observation | F5, form a line of 3, observe cells briefly enlarge |
| Win overlay with ranked scores | WIN-02 | Modal overlay layout — requires visual verification | F5, reach 5 points, verify overlay with winner name and scores |
| Roll result large and prominent | UI-02 | Font size visual check | F5, press Roll, verify number is 48px+ and unmissable |
| Score strip always visible | UI-03 | Layout persistence check | F5, play several turns, verify scores never hidden |
| Game log color-coded entries | UI-04 | Color accuracy check | F5, play turns, verify log entries match player colors |
| Browser layout works | UI-05 | Cross-platform smoke test | HTML5 export, open in Chrome, verify playable |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
