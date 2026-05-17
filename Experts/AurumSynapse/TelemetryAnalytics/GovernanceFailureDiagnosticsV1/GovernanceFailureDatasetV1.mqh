//+------------------------------------------------------------------+
//| GovernanceFailureDatasetV1.mqh                                  |
//| PHASE 20C — failure event POD (cold path)                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_FAILURE_DATASET_V1_MQH__
#define __AURUM_GOV_FAILURE_DATASET_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

#define GOV_FAILURE_MAX_EVENTS_V1   48

enum ENUM_GOV_FAILURE_SEVERITY_V1
{
   GOV_FAIL_SEV_INFO_V1 = 0,
   GOV_FAIL_SEV_WARNING_V1 = 1,
   GOV_FAIL_SEV_HIGH_V1 = 2,
   GOV_FAIL_SEV_CRITICAL_V1 = 3
};

enum ENUM_GOV_FAILURE_KIND_V1
{
   GOV_FAIL_KIND_NONE_V1 = 0,
   GOV_FAIL_KIND_SPREAD_EXPLOSION_V1 = 1,
   GOV_FAIL_KIND_LIQUIDITY_COLLAPSE_V1 = 2,
   GOV_FAIL_KIND_VOLATILITY_MISMATCH_V1 = 3,
   GOV_FAIL_KIND_REGIME_MISMATCH_V1 = 4,
   GOV_FAIL_KIND_STOP_CASCADE_V1 = 5,
   GOV_FAIL_KIND_COOLDOWN_LOCK_V1 = 6,
   GOV_FAIL_KIND_RISK_MANAGER_BLOCK_V1 = 7,
   GOV_FAIL_KIND_MARGIN_STRESS_V1 = 8,
   GOV_FAIL_KIND_TAIL_RISK_CLUSTER_V1 = 9,
   GOV_FAIL_KIND_RECOVERY_AMPLIFICATION_V1 = 10,
   GOV_FAIL_KIND_EXECUTION_REJECTION_V1 = 11,
   GOV_FAIL_KIND_SLIPPAGE_STRESS_V1 = 12,
   GOV_FAIL_KIND_POSITION_OVEREXPOSURE_V1 = 13,
   GOV_FAIL_KIND_TOXIC_STRATEGY_ESCALATION_V1 = 14,
   GOV_FAIL_KIND_LOT_COLLAPSE_V1 = 15,
   GOV_FAIL_KIND_DRAWDOWN_STRESS_V1 = 16,
   GOV_FAIL_KIND_TAGGING_FAULT_V1 = 17
};

struct SGovFailureEventV1
{
   int      kind;
   int      severity;
   string   title;
   string   detail;
   string   symbol;
   int      metric_i;
   double   metric_d;
};

inline void GovFailureDsV1_InitEvent(SGovFailureEventV1 &e)
{
   e.kind = GOV_FAIL_KIND_NONE_V1;
   e.severity = GOV_FAIL_SEV_INFO_V1;
   e.title = "";
   e.detail = "";
   e.symbol = "";
   e.metric_i = 0;
   e.metric_d = 0.0;
}

struct SGovFailureEventListV1
{
   SGovFailureEventV1 ev[GOV_FAILURE_MAX_EVENTS_V1];
   int                 n;
};

inline void GovFailureDsV1_InitList(SGovFailureEventListV1 &l)
{
   l.n = 0;
   for(int i = 0; i < GOV_FAILURE_MAX_EVENTS_V1; i++)
      GovFailureDsV1_InitEvent(l.ev[i]);
}

inline bool GovFailureDsV1_Push(SGovFailureEventListV1 &l, const SGovFailureEventV1 &e)
{
   if(l.n >= GOV_FAILURE_MAX_EVENTS_V1)
      return false;
   l.ev[l.n++] = e;
   return true;
}

#endif // __AURUM_GOV_FAILURE_DATASET_V1_MQH__
