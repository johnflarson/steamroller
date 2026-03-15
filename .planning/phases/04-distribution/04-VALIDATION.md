---
phase: 4
slug: distribution
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (no automated test framework) |
| **Config file** | none |
| **Quick run command** | `ls -la export/web/index.html export/linux/steamroller.x86_64 export/windows/steamroller.exe` |
| **Full suite command** | Manual smoke test on each platform |
| **Estimated runtime** | ~5 minutes (manual per-platform verification) |

---

## Sampling Rate

- **After every task commit:** Verify build artifacts exist and are non-zero size
- **After every plan wave:** Manual smoke test on affected platform(s)
- **Before `/gsd:verify-work`:** Full manual smoke test on all platforms (HTML5 in browser, Linux native, Windows via WSL2 host)
- **Max feedback latency:** n/a (manual verification)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | EXPORT-01 | smoke | `test -f export/web/index.html && echo OK` | ✅ | ⬜ pending |
| 4-01-02 | 01 | 1 | EXPORT-02 | smoke | `test -f export/linux/steamroller.x86_64 && echo OK` | ❌ W0 | ⬜ pending |
| 4-01-03 | 01 | 1 | EXPORT-02 | smoke | `test -f export/windows/steamroller.exe && echo OK` | ❌ W0 | ⬜ pending |
| 4-02-01 | 02 | 2 | EXPORT-01 | manual | Manual: load game in browser iframe | n/a | ⬜ pending |
| 4-02-02 | 02 | 2 | EXPORT-02 | manual | Manual: run desktop builds | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `export/linux/` — directory must exist before Godot export
- [ ] `export/windows/` — directory must exist before Godot export
- [ ] butler CLI installed and authenticated — prerequisite for deploy.sh
- [ ] gh CLI installed and authenticated — prerequisite for GitHub Release
- [ ] GitHub remote configured on dicegame repo — prerequisite for gh release create
- [ ] itch.io game page created at `steamroller` slug — prerequisite for butler push

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| HTML5 build loads and plays complete game in hosted browser | EXPORT-01 | Requires browser + iframe + hosted server | Open luminaldata.com game page in browser, play through a full game |
| Linux desktop build runs full game | EXPORT-02 | Requires launching native binary | Run `./export/linux/steamroller.x86_64`, play through a full game |
| Windows desktop build runs full game | EXPORT-02 | Requires Windows environment | Run `steamroller.exe` on WSL2 host Windows, play through a full game |
| itch.io page shows playable embed | EXPORT-01 | Requires itch.io browser check | Visit itch.io game page, verify Play button (not Download) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
