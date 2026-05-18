//+------------------------------------------------------------------+
//| GovernanceRegimePersistenceV1.mqh                                |
//| PHASE 22 — append-only CSV (optional cold path)                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_PERSISTENCE_V1_MQH__
#define __AURUM_GOV_REGIME_PERSISTENCE_V1_MQH__

#include "GovernanceRegimeTelemetryV1.mqh"

#define GOV_REGIME_CSV_REL_V1 "AurumSynapse\\TelemetryAnalytics\\Reports\\governance_regime_timeseries_v1.csv"

inline void GovRegimePersistV1_AppendRow(const SGovRegimeTelemetryV1 &t)
{
   const int h = FileOpen(GOV_REGIME_CSV_REL_V1, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(h == INVALID_HANDLE)
      return;
   FileSeek(h, 0, SEEK_END);
   FileWrite(h,
             (long)t.ts,
             (int)t.regime,
             (int)t.secondary_regime,
             t.regime_confidence_permille,
             t.atr,
             t.trend_strength,
             t.volatility_score,
             t.compression_score,
             t.expansion_score,
             t.momentum_score,
             t.breakout_detected ? 1 : 0,
             t.sweep_detected ? 1 : 0,
             t.session_id,
             t.confidence,
             (long)t.replay_hash);
   FileClose(h);
}

#endif // __AURUM_GOV_REGIME_PERSISTENCE_V1_MQH__
