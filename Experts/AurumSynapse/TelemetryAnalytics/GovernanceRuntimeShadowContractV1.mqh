//+------------------------------------------------------------------+
//| GovernanceRuntimeShadowContractV1.mqh                           |
//| Lightweight shadow snapshot — no replay, no export, no I/O     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_SHADOW_CONTRACT_V1_MQH__
#define __AURUM_GOV_RUNTIME_SHADOW_CONTRACT_V1_MQH__

#ifndef GOV_RUNTIME_SHADOW_CONTRACT_V1_NO_REPLAY
   #define GOV_RUNTIME_SHADOW_CONTRACT_V1_NO_REPLAY 1
#endif

//+------------------------------------------------------------------+
//| Packed observation row (memory-only lane).                      |
//+------------------------------------------------------------------+
struct SGovRuntimeShadowSnapshotV1
{
   datetime ts_utc;
   string   symbol;
   long     spread_points;
   long     equity_cents;
   long     max_equity_dd_bp;
   int      open_positions;
   int      strategy_id;
   long     quality_score_bp;
   bool     execution_allowed_native;
   uint     governance_shadow_state;
   int      survivability_score_0_100;
   int      toxicity_score_0_100;
   uint     anomaly_flags;
};

//+------------------------------------------------------------------+
inline void GovRuntimeShadowV1_InitSnapshot(SGovRuntimeShadowSnapshotV1 &s)
{
   s.ts_utc = 0;
   s.symbol = "";
   s.spread_points = 0;
   s.equity_cents = 0;
   s.max_equity_dd_bp = 0;
   s.open_positions = 0;
   s.strategy_id = -1;
   s.quality_score_bp = 0;
   s.execution_allowed_native = false;
   s.governance_shadow_state = 0;
   s.survivability_score_0_100 = 0;
   s.toxicity_score_0_100 = 0;
   s.anomaly_flags = 0;
}

//+------------------------------------------------------------------+
inline long GovRuntimeShadowV1_SymbolHash(const string sym)
{
   const int n = StringLen(sym);
   long h = 5381;
   for(int i = 0; i < n; i++)
      h = ((h << 5) + h) + (long)StringGetCharacter(sym, i);
   return h;
}

//+------------------------------------------------------------------+
//| Capture — O(1), no file I/O, no parser, no governance umbrella. |
//+------------------------------------------------------------------+
inline void GovRuntimeShadowV1_Capture(const datetime ts_utc,
                                       const string symbol,
                                       const long spread_points,
                                       const double equity,
                                       const double max_equity_dd_frac,
                                       const int open_positions,
                                       const int strategy_id,
                                       const double quality_score_0_100,
                                       const bool execution_allowed_native,
                                       const uint governance_shadow_state,
                                       const int survivability_score_0_100,
                                       const int toxicity_score_0_100,
                                       const uint anomaly_flags,
                                       SGovRuntimeShadowSnapshotV1 &out)
{
   GovRuntimeShadowV1_InitSnapshot(out);
   out.ts_utc = ts_utc;
   out.symbol = symbol;
   out.spread_points = spread_points;
   if(MathIsValidNumber(equity))
      out.equity_cents = (long)MathRound(equity * 100.0);
   if(MathIsValidNumber(max_equity_dd_frac))
      out.max_equity_dd_bp = (long)MathRound(max_equity_dd_frac * 10000.0);
   out.open_positions = open_positions;
   out.strategy_id = strategy_id;
   if(MathIsValidNumber(quality_score_0_100))
      out.quality_score_bp = (long)MathRound(quality_score_0_100 * 100.0);
   out.execution_allowed_native = execution_allowed_native;
   out.governance_shadow_state = governance_shadow_state;
   out.survivability_score_0_100 = survivability_score_0_100;
   out.toxicity_score_0_100 = toxicity_score_0_100;
   out.anomaly_flags = anomaly_flags;
}

#endif // __AURUM_GOV_RUNTIME_SHADOW_CONTRACT_V1_MQH__
