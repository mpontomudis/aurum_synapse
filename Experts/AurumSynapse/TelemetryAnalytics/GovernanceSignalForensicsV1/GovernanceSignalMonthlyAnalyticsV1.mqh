//+------------------------------------------------------------------+
//| GovernanceSignalMonthlyAnalyticsV1.mqh                          |
//| PHASE 21 — calendar-axis labels (deterministic month buckets)   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_MONTHLY_ANALYTICS_V1_MQH__
#define __AURUM_GOV_SIG_MONTHLY_ANALYTICS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

inline string GovSigMonthlyV1_AbbrFromIndex0_11(const int m0)
{
   switch(GovClampInt32(m0, 0, 11)) {
   case 0:
      return "Jan";
   case 1:
      return "Feb";
   case 2:
      return "Mar";
   case 3:
      return "Apr";
   case 4:
      return "May";
   case 5:
      return "Jun";
   case 6:
      return "Jul";
   case 7:
      return "Aug";
   case 8:
      return "Sep";
   case 9:
      return "Oct";
   case 10:
      return "Nov";
   default:
      return "Dec";
   }
}

#endif // __AURUM_GOV_SIG_MONTHLY_ANALYTICS_V1_MQH__
