# Aurum Synapse (MQL5)

This repository is centered on **`Experts/AurumSynapse/`** — multi-strategy EA, telemetry (T0–T2), offline analytics (Phase 3A Stream A), and validation assets.

Default MetaTrader 5 template folders under **`Experts/`** (Advisors, Examples, Free Robots, Market) are **not** maintained here.

## Layout

```
Experts/
└── AurumSynapse/
    ├── AurumSynapse.mq5      # Main EA
    ├── Core/ Engine/ Execution/ Intelligence/ Management/ Strategies/ UI/
    ├── Telemetry/             # T0–T2 passive capture + T2 CSV contract
    ├── TelemetryAnalytics/   # Phase 3A Stream A (read-only; not linked by EA)
    ├── Tests/                # Test scripts, roadmap, backtest docs
    └── Docs/                 # Project docs
```

## Build

- Open `Experts/AurumSynapse/AurumSynapse.mq5` (or test scripts under `Tests/`) in **MetaEditor** and compile (F7).  
- **`*.ex5`** is ignored by Git; binaries are local build outputs only.

## Telemetry freeze

- **T1 / T2 / Phase 3A Stream A** completion and **`AS_TELEMETRY_V1`** version lock:  
  `Experts/AurumSynapse/Tests/POST_COMPLETION_VALIDATION_ROADMAP.md` → section **`### PHASE 3A — COMPLETION FREEZE (official) — 2026-05-12`**.  
- Telemetry module overview: `Experts/AurumSynapse/Telemetry/README.md`.

## Remote

Push targets **`main`** on the configured `origin` (GitHub `aurum_synapse`).
