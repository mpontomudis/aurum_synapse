//+------------------------------------------------------------------+
//| GovernanceRegimeTelemetryV1.mqh                                  |
//| PHASE 22 — ring-buffer telemetry + replay hash                    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_TELEMETRY_V1_MQH__
#define __AURUM_GOV_REGIME_TELEMETRY_V1_MQH__

#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityReplayV1.mqh"
#include "GovernanceRegimeEngineV1.mqh"

inline ulong GovRegimeTelV1_HashSnapshot(const SGovRegimeTelemetryV1 &t)
{
   const string s = IntegerToString((long)t.ts) + "|" + IntegerToString((int)t.regime) + "|" +
                    DoubleToString(t.atr, 6) + "|" + DoubleToString(t.trend_strength, 6) + "|" +
                    DoubleToString(t.volatility_score, 6) + "|" + DoubleToString(t.confidence, 6) + "|" +
                    IntegerToString(t.breakout_detected ? 1 : 0) + "|" + IntegerToString(t.sweep_detected ? 1 : 0);
   return GovRuntimeObsReplayV1_Hash64(s);
}

inline void GovRegimeTelV1_Push(SGovRegimeRuntimeStoreV1 &s,
                                const SGovRegimeTelemetryV1 &row)
{
   const int cap = GOV_REGIME_TELEM_RING_V1;
   const int idx = (s.tel_head + s.tel_count) % cap;
   s.tel_ring[idx] = row;
   if(s.tel_count < cap)
      s.tel_count++;
   else
      s.tel_head = (s.tel_head + 1) % cap;
}

inline void GovRegimeTelV1_BuildRow(const datetime ts,
                                     const EAurumMarketRegime reg,
                                     const MarketState &st,
                                     const SGovRegimeFeaturesV1 &f,
                                     const double conf,
                                     SGovRegimeTelemetryV1 &out)
{
   out.ts = ts;
   out.regime = reg;
   out.atr = st.atr14;
   out.trend_strength = f.directional_persist;
   out.volatility_score = f.expansion_score;
   out.compression_score = f.compression_density;
   out.expansion_score = f.range_expansion;
   out.momentum_score = f.momentum_persist;
   out.breakout_detected = (reg == AURUM_REGIME_BREAKOUT || reg == AURUM_REGIME_VOLATILITY_EXPANSION);
   out.sweep_detected = (reg == AURUM_REGIME_LIQUIDITY_SWEEP);
   out.session_id = (int)st.session;
   out.confidence = conf;
   out.replay_hash = 0;
   out.replay_hash = GovRegimeTelV1_HashSnapshot(out);
}

#endif // __AURUM_GOV_REGIME_TELEMETRY_V1_MQH__
