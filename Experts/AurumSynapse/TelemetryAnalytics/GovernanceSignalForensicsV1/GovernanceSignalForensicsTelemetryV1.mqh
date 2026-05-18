//+------------------------------------------------------------------+
//| GovernanceSignalForensicsTelemetryV1.mqh                         |
//| PHASE 21 — saturating counters + bundle (deterministic)        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_FORENSICS_TELEMETRY_V1_MQH__
#define __AURUM_GOV_SIG_FORENSICS_TELEMETRY_V1_MQH__

#include "../../Core/Constants.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceSignalForensicsDatasetV1.mqh"
#include "GovernanceSignalRejectReasonV1.mqh"
#include "GovernanceSignalLifecycleRegistryV1.mqh"

struct SGovSignalForensicsTelemetryV1
{
   SGovSignalLifecycleRegistryV1 life;

   ulong state_hits[6];
   ulong reject_by_reason[GOV_SIG_REJECT_REASON_COUNT_V1];

   ulong month_created[GOV_SIG_FORENSICS_MONTH_BUCKETS_V1];
   ulong month_passed[GOV_SIG_FORENSICS_MONTH_BUCKETS_V1];
   ulong month_rejected[GOV_SIG_FORENSICS_MONTH_BUCKETS_V1];

   ulong strat_sig[GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1];
   ulong strat_acc[GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1];
   ulong strat_rej[GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1];

   ulong reg_sig[GOV_SIG_FORENSICS_REGIME_SLOTS_V1];
   ulong reg_acc[GOV_SIG_FORENSICS_REGIME_SLOTS_V1];

   ulong consensus_attempts;
   ulong consensus_pass;
   ulong consensus_fail;
   ulong consensus_agree_sum;
   ulong consensus_agree_samples;

   ulong heat_strat_rej[GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1][GOV_SIG_REJECT_REASON_COUNT_V1];
   ulong heat_reg_rej[GOV_SIG_FORENSICS_REGIME_SLOTS_V1][GOV_SIG_REJECT_REASON_COUNT_V1];
   ulong heat_month_rej[GOV_SIG_FORENSICS_MONTH_BUCKETS_V1][GOV_SIG_REJECT_REASON_COUNT_V1];

   int last_accept_month_1_12;
   int dead_zone_month_first_1_12;
   ulong starvation_alerts;
};

SGovSignalForensicsTelemetryV1 g_gov_sig_forensics_tel_v1;

inline void GovSigFoV1_SatAdd(ulong &dst, const ulong v)
{
   if(v == 0)
      return;
   const ulong maxv = (ulong)18446744073709551615;
   if(dst > maxv - v)
      dst = maxv;
   else
      dst += v;
}

inline void GovSigFoV1_Init(SGovSignalForensicsTelemetryV1 &t)
{
   GovSigLifecycleV1_Init(t.life);
   for(int i = 0; i < 6; i++)
      t.state_hits[i] = 0;
   for(int j = 0; j < GOV_SIG_REJECT_REASON_COUNT_V1; j++)
      t.reject_by_reason[j] = 0;
   for(int m = 0; m < GOV_SIG_FORENSICS_MONTH_BUCKETS_V1; m++) {
      t.month_created[m] = 0;
      t.month_passed[m] = 0;
      t.month_rejected[m] = 0;
   }
   for(int s = 0; s < GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1; s++) {
      t.strat_sig[s] = 0;
      t.strat_acc[s] = 0;
      t.strat_rej[s] = 0;
   }
   for(int r = 0; r < GOV_SIG_FORENSICS_REGIME_SLOTS_V1; r++) {
      t.reg_sig[r] = 0;
      t.reg_acc[r] = 0;
   }
   t.consensus_attempts = 0;
   t.consensus_pass = 0;
   t.consensus_fail = 0;
   t.consensus_agree_sum = 0;
   t.consensus_agree_samples = 0;
   for(int s = 0; s < GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1; s++)
      for(int j = 0; j < GOV_SIG_REJECT_REASON_COUNT_V1; j++)
         t.heat_strat_rej[s][j] = 0;
   for(int rg = 0; rg < GOV_SIG_FORENSICS_REGIME_SLOTS_V1; rg++)
      for(int j = 0; j < GOV_SIG_REJECT_REASON_COUNT_V1; j++)
         t.heat_reg_rej[rg][j] = 0;
   for(int m = 0; m < GOV_SIG_FORENSICS_MONTH_BUCKETS_V1; m++)
      for(int j = 0; j < GOV_SIG_REJECT_REASON_COUNT_V1; j++)
         t.heat_month_rej[m][j] = 0;
   t.last_accept_month_1_12 = -1;
   t.dead_zone_month_first_1_12 = -1;
   t.starvation_alerts = 0;
}

inline int GovSigFoV1_MonthIndex1_12(const datetime ts)
{
   if(ts <= 0)
      return 1;
   MqlDateTime dt;
   TimeToStruct(ts, dt);
   int m = dt.mon;
   if(m < 1)
      m = 1;
   if(m > 12)
      m = 12;
   return m;
}

inline int GovSigFoV1_RegimeIndex(const ENUM_REGIME regime)
{
   if(regime == REGIME_TRENDING)
      return 0;
   if(regime == REGIME_RANGING)
      return 1;
   if(regime == REGIME_VOLATILE)
      return 2;
   return 3;
}

inline void GovSigFoV1_HeatBump(SGovSignalForensicsTelemetryV1 &t, const int strat_slot, const int reg_slot, const int month_1_12, const int rej)
{
   const int rr = GovClampInt32(rej, 0, GOV_SIG_REJECT_REASON_COUNT_V1 - 1);
   const int m0 = GovClampInt32(month_1_12 - 1, 0, GOV_SIG_FORENSICS_MONTH_BUCKETS_V1 - 1);
   const int s0 = GovClampInt32(strat_slot, 0, GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1 - 1);
   const int r0 = GovClampInt32(reg_slot, 0, GOV_SIG_FORENSICS_REGIME_SLOTS_V1 - 1);
   GovSigFoV1_SatAdd(t.heat_strat_rej[s0][rr], 1);
   GovSigFoV1_SatAdd(t.heat_reg_rej[r0][rr], 1);
   GovSigFoV1_SatAdd(t.heat_month_rej[m0][rr], 1);
}

inline void GovSigFoV1_OnReject(SGovSignalForensicsTelemetryV1 &t, const datetime ts, const int strat_slot, const ENUM_REGIME regime, const int rej_native_mapped, const bool as_filtered_stage)
{
   const int month = GovSigFoV1_MonthIndex1_12(ts);
   const int m0 = month - 1;
   const int ridx = GovSigFoV1_RegimeIndex(regime);
   const int s0 = GovClampInt32(strat_slot, 0, GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1 - 1);

   if(as_filtered_stage)
      GovSigFoV1_SatAdd(t.state_hits[GOV_SIG_FILTERED], 1);
   else
      GovSigFoV1_SatAdd(t.state_hits[GOV_SIG_REJECTED], 1);
   GovSigFoV1_SatAdd(t.month_created[m0], 1);
   GovSigFoV1_SatAdd(t.month_rejected[m0], 1);
   GovSigFoV1_SatAdd(t.strat_sig[s0], 1);
   GovSigFoV1_SatAdd(t.strat_rej[s0], 1);
   GovSigFoV1_SatAdd(t.reg_sig[ridx], 1);

   const int rr = GovClampInt32(rej_native_mapped, 0, GOV_SIG_REJECT_REASON_COUNT_V1 - 1);
   GovSigFoV1_SatAdd(t.reject_by_reason[rr], 1);
   GovSigFoV1_HeatBump(t, s0, ridx, month, rr);

   if(t.last_accept_month_1_12 >= 1 && month > t.last_accept_month_1_12 + 1 && t.month_passed[m0] == 0 && t.month_rejected[m0] > 10) {
      GovSigFoV1_SatAdd(t.starvation_alerts, 1);
      if(t.dead_zone_month_first_1_12 < 0)
         t.dead_zone_month_first_1_12 = month;
   }
}

inline void GovSigFoV1_OnConsensusFail(SGovSignalForensicsTelemetryV1 &t, const datetime ts, const ENUM_REGIME regime)
{
   GovSigFoV1_SatAdd(t.consensus_attempts, 1);
   GovSigFoV1_SatAdd(t.consensus_fail, 1);
   GovSigFoV1_SatAdd(t.state_hits[GOV_SIG_REJECTED], 1);
   const int ridx = GovSigFoV1_RegimeIndex(regime);
   const int month = GovSigFoV1_MonthIndex1_12(ts);
   const int rr = GOV_SIG_REJECT_CONSENSUS;
   GovSigFoV1_SatAdd(t.reject_by_reason[rr], 1);
   GovSigFoV1_HeatBump(t, 0, ridx, month, rr);
   const int m0 = month - 1;
   GovSigFoV1_SatAdd(t.month_created[m0], 1);
   GovSigFoV1_SatAdd(t.month_rejected[m0], 1);
   GovSigFoV1_SatAdd(t.reg_sig[ridx], 1);
}

inline void GovSigFoV1_OnConsensusPass(SGovSignalForensicsTelemetryV1 &t, const int agreeing)
{
   GovSigFoV1_SatAdd(t.consensus_attempts, 1);
   GovSigFoV1_SatAdd(t.consensus_pass, 1);
   const int a = GovClampInt32(agreeing, 0, GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1);
   GovSigFoV1_SatAdd(t.consensus_agree_sum, (ulong)a);
   GovSigFoV1_SatAdd(t.consensus_agree_samples, 1);
}

inline void GovSigFoV1_OnAcceptedPath(SGovSignalForensicsTelemetryV1 &t, const datetime ts, const int strat_slot, const ENUM_REGIME regime)
{
   const int month = GovSigFoV1_MonthIndex1_12(ts);
   const int m0 = month - 1;
   const int ridx = GovSigFoV1_RegimeIndex(regime);
   const int s0 = GovClampInt32(strat_slot, 0, GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1 - 1);

   GovSigFoV1_SatAdd(t.state_hits[GOV_SIG_ACCEPTED], 1);
   GovSigFoV1_SatAdd(t.month_created[m0], 1);
   GovSigFoV1_SatAdd(t.month_passed[m0], 1);
   GovSigFoV1_SatAdd(t.strat_sig[s0], 1);
   GovSigFoV1_SatAdd(t.strat_acc[s0], 1);
   GovSigFoV1_SatAdd(t.reg_sig[ridx], 1);
   GovSigFoV1_SatAdd(t.reg_acc[ridx], 1);
   t.last_accept_month_1_12 = month;
}

inline void GovSigFoV1_OnExecuted(SGovSignalForensicsTelemetryV1 &t)
{
   GovSigFoV1_SatAdd(t.state_hits[GOV_SIG_EXECUTED], 1);
}

inline void GovSigFoV1_OnCreatedOnly(SGovSignalForensicsTelemetryV1 &t, const datetime ts)
{
   GovSigFoV1_SatAdd(t.state_hits[GOV_SIG_CREATED], 1);
}

#endif // __AURUM_GOV_SIG_FORENSICS_TELEMETRY_V1_MQH__
