//+------------------------------------------------------------------+
//| GovernanceEcologyEngineV1.mqh                                   |
//| PHASE 23 — bar pipeline: score → state → signal shaping          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECOLOGY_ENGINE_V1_MQH__
#define __AURUM_GOV_ECOLOGY_ENGINE_V1_MQH__

#include "../../Core/Structures.mqh"
#include "GovernanceEcologyDatasetV1.mqh"
#include "GovernanceEcologyCompatibilityV1.mqh"
#include "GovernanceEcologyTelemetryV1.mqh"
#include "GovernanceEcologyScoringV1.mqh"
#include "GovernanceEcologySuppressionV1.mqh"
#include "../GovernanceRegimeEngineV1/GovernanceRegimeDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

inline void GovEcoEngV1_ApplyParticipation(SGovEcologyStoreV1 &st, SignalResult &signals[])
{
   st.last_bar_suppress_clears = 0;
   st.last_bar_throttle_events = 0;
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      const ENUM_SIGNAL prev_sig = signals[i].signal;
      const int ps = st.s[i].part_state;
      if(ps == GOV_ECO_ST_SUPPRESSED || ps == GOV_ECO_ST_TOXIC || ps == GOV_ECO_ST_DISABLED_BY_REGIME) {
         if(prev_sig != SIGNAL_NONE)
            st.last_bar_suppress_clears++;
         signals[i].signal = SIGNAL_NONE;
         signals[i].strength = 0.0;
         st.s[i].bars_suppression++;
      } else if(ps == GOV_ECO_ST_THROTTLED) {
         if(prev_sig != SIGNAL_NONE)
            st.last_bar_throttle_events++;
         signals[i].strength *= 0.55;
         signals[i].weight *= 0.65;
         st.s[i].bars_throttled++;
      } else if(ps == GOV_ECO_ST_PASSIVE) {
         signals[i].strength *= 0.78;
         signals[i].weight *= 0.82;
      } else if(ps == GOV_ECO_ST_DOMINANT) {
         signals[i].weight *= 1.12;
         if(signals[i].weight > 1.85)
            signals[i].weight = 1.85;
         st.s[i].bars_dominant++;
      } else if(ps == GOV_ECO_ST_RECOVERING) {
         signals[i].strength *= 0.88;
         signals[i].weight *= 0.90;
      }
      if(signals[i].signal != SIGNAL_NONE)
         st.s[i].bars_participation++;
   }
}

inline void GovEcoEngV1_OnBarSignals(SGovEcologyStoreV1 &st,
                                     const datetime ts,
                                     const EAurumMarketRegime reg,
                                     const ENUM_REGIME legacy_reg,
                                     const int session_id,
                                     const double atr_ratio,
                                     SignalResult &signals[])
{
   if(!st.enabled)
      return;
   st.bar_index++;
   st.last_ts = ts;
   const int pref = GovEcoCompatV1_PreferredStratSlot(reg);
   const int mi = GovEcoTelV1_MonthIdx(ts);
   const int vb = GovEcoTelV1_VolBucket(atr_ratio);
   const int se = GovClampInt32(session_id, 0, GOV_ECO_SESSION_COUNT_V1 - 1);

   GovEcoTelV1_OnCooccurrencePreApply(st, signals);

   int best = -1;
   double bestStr = -1.0;
   for(int k = 0; k < GOV_ECO_STRAT_COUNT_V1; k++) {
      if(signals[k].signal == SIGNAL_NONE)
         continue;
      if(signals[k].strength > bestStr) {
         bestStr = signals[k].strength;
         best = k;
      }
   }

   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      const bool active = (signals[i].signal != SIGNAL_NONE);
      const int al = (active && pref == i) ? 1 : 0;
      const int mm = (active && pref >= 0 && pref != i &&
                      (reg == AURUM_REGIME_VOLATILITY_EXPANSION || reg == AURUM_REGIME_HIGH_VOL || reg == AURUM_REGIME_BREAKOUT))
                        ? 1
                        : 0;
      const int dp = (best == i) ? 1 : 0;
      GovEcoScoreV1_UpdateStratScores(st.s[i], al, mm, dp);
   }

   GovEcoScoreV1_RecomputeDiversity(st);

   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++) {
      st.s[i].part_state = GovEcoSupV1_ResolveState(reg, legacy_reg, st.s[i], i, st.monoculture_warn);
      const bool active2 = (signals[i].signal != SIGNAL_NONE);
      GovEcoTelV1_OnStratBarSlice(st, i, se, vb, mi, active2);
   }

   GovEcoEngV1_ApplyParticipation(st, signals);
}

#endif // __AURUM_GOV_ECOLOGY_ENGINE_V1_MQH__
