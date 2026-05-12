# `Telemetry/Archive/` (T0 — philosophy only)

**Purpose:** Closed **run bundles** (CSV + manifest pointer) after T1+ export.  
**Rotation:** Operator zips or moves files here when file size exceeds policy; EA does **not** auto-archive at T0/T1 unless explicitly designed later.

**T0:** No runtime code in this folder.

**Freeze (2026-05-12):** T2 persistence is **validated**; archive remains operator-driven. See `Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` — **`### PHASE 3A — COMPLETION FREEZE (official) — 2026-05-12`**.
