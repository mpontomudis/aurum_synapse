//+------------------------------------------------------------------+
//| GovernanceSuppressionCalibrationV1.mqh                          |
//| PHASE 22A — governance suppression / starvation observability    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SUPPRESSION_CALIBRATION_V1_MQH__
#define __AURUM_GOV_SUPPRESSION_CALIBRATION_V1_MQH__

#include "../../Core/Constants.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceSignalForensicsTelemetryV1.mqh"

struct SGovSuppressionCalibrationV1
{
   ulong risk_halt_sub[AS_CT_DENY_DETAIL_COUNT_V1];
   ulong risk_halt_pos_limit;
   ulong risk_halt_margin_stub;
   ulong bars_exec_path;
   ulong bars_halted_early;
};

inline SGovSuppressionCalibrationV1 g_gov_sup_calib_v1;

inline void GovSupCalibV1_Init(SGovSuppressionCalibrationV1 &c)
{
   for(int i = 0; i < AS_CT_DENY_DETAIL_COUNT_V1; i++)
      c.risk_halt_sub[i] = 0;
   c.risk_halt_pos_limit = 0;
   c.risk_halt_margin_stub = 0;
   c.bars_exec_path = 0;
   c.bars_halted_early = 0;
}

inline string GovSupCalibV1_RiskSubLabel(const int code)
{
   switch(GovClampInt32(code, 0, AS_CT_DENY_DETAIL_COUNT_V1 - 1)) {
   case AS_CT_DENY_NONE:
      return "RISK_OK";
   case AS_CT_DENY_COOLDOWN:
      return "RISK_COOLDOWN";
   case AS_CT_DENY_DAILY_LOSS:
      return "RISK_DAILY_LOSS";
   case AS_CT_DENY_DD_LOCK:
      return "RISK_DD_LOCK";
   case AS_CT_DENY_CONSEC:
      return "RISK_CONSEC_LOSS";
   case AS_CT_DENY_MARGIN_LOCK:
      return "RISK_MARGIN_LOCK";
   case AS_CT_DENY_POSITION_LIMIT:
      return "RISK_POSITION_LIMIT";
   case AS_CT_DENY_EQUITY_GUARD:
      return "RISK_EQUITY_GUARD";
   default:
      return "RISK_UNKNOWN";
   }
}

inline void GovSupCalibV1_BumpRiskHaltSub(SGovSuppressionCalibrationV1 &c, const int detail)
{
   const int d = GovClampInt32(detail, 0, AS_CT_DENY_DETAIL_COUNT_V1 - 1);
   if(c.risk_halt_sub[d] < (ulong)18446744073709551615)
      c.risk_halt_sub[d]++;
}

inline void GovSupCalibV1_OnPositionLimitReject(void)
{
   if(g_gov_sup_calib_v1.risk_halt_pos_limit < (ulong)18446744073709551615)
      g_gov_sup_calib_v1.risk_halt_pos_limit++;
}

inline int GovSupCalibV1_GovernanceAggressivenessPermille(const ulong created, const ulong accepted)
{
   if(created == 0)
      return 0;
   return (int)MathMin(1000UL, 1000UL * accepted / created);
}

inline int GovSupCalibV1_GovernanceBalancePermille(const ulong created, const ulong accepted, const ulong rejected)
{
   if(created == 0)
      return 0;
   const ulong denom = accepted + rejected;
   if(denom == 0)
      return 0;
   return (int)MathMin(1000UL, 1000UL * accepted / denom);
}

inline int GovSupCalibV1_EcosystemViabilityPermille(const ulong created, const ulong executed)
{
   if(created == 0)
      return 0;
   return (int)MathMin(1000UL, 1000UL * executed / created);
}

inline int GovSupCalibV1_MonthsWithoutExecution(const SGovSignalForensicsTelemetryV1 &t)
{
   int z = 0;
   for(int m = 0; m < GOV_SIG_FORENSICS_MONTH_BUCKETS_V1; m++) {
      if(t.month_passed[m] == 0)
         z++;
   }
   return z;
}

#endif // __AURUM_GOV_SUPPRESSION_CALIBRATION_V1_MQH__
