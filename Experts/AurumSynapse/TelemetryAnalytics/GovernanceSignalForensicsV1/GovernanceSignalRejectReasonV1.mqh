//+------------------------------------------------------------------+
//| GovernanceSignalRejectReasonV1.mqh                              |
//| PHASE 21 — deterministic reject vocabulary                       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_REJECT_REASON_V1_MQH__
#define __AURUM_GOV_SIG_REJECT_REASON_V1_MQH__

#include "../../Core/Constants.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

enum ENUM_GOV_SIGNAL_REJECT_REASON_V1
{
   GOV_SIG_REJECT_NONE = 0,
   GOV_SIG_REJECT_QUALITY = 1,
   GOV_SIG_REJECT_TREND = 2,
   GOV_SIG_REJECT_KEYLEVEL = 3,
   GOV_SIG_REJECT_MOMENTUM = 4,
   GOV_SIG_REJECT_SPREAD = 5,
   GOV_SIG_REJECT_SESSION = 6,
   GOV_SIG_REJECT_RISK = 7,
   GOV_SIG_REJECT_DD = 8,
   GOV_SIG_REJECT_CONSENSUS = 9,
   GOV_SIG_REJECT_GOVERNANCE_LOCK = 10,
   GOV_SIG_REJECT_MAX_POSITIONS = 11,
   GOV_SIG_REJECT_VOLATILITY = 12,
   GOV_SIG_REJECT_UNKNOWN = 13
};

#define GOV_SIG_REJECT_REASON_COUNT_V1 14

inline string GovSigRejectV1_Label(const int code)
{
   switch(GovClampInt32(code, 0, GOV_SIG_REJECT_REASON_COUNT_V1 - 1)) {
   case GOV_SIG_REJECT_NONE:
      return "NONE";
   case GOV_SIG_REJECT_QUALITY:
      return "QUALITY_SCORE";
   case GOV_SIG_REJECT_TREND:
      return "TREND_ALIGNMENT";
   case GOV_SIG_REJECT_KEYLEVEL:
      return "KEY_LEVEL";
   case GOV_SIG_REJECT_MOMENTUM:
      return "MOMENTUM";
   case GOV_SIG_REJECT_SPREAD:
      return "SPREAD";
   case GOV_SIG_REJECT_SESSION:
      return "SESSION_TIME";
   case GOV_SIG_REJECT_RISK:
      return "RISK_HALT";
   case GOV_SIG_REJECT_DD:
      return "DRAWDOWN_GUARD";
   case GOV_SIG_REJECT_CONSENSUS:
      return "CONSENSUS";
   case GOV_SIG_REJECT_GOVERNANCE_LOCK:
      return "GOVERNANCE_INPUT_LOCK";
   case GOV_SIG_REJECT_MAX_POSITIONS:
      return "MAX_POSITIONS";
   case GOV_SIG_REJECT_VOLATILITY:
      return "VOLATILITY_REGIME";
   default:
      return "UNKNOWN";
   }
}

inline int GovSigRejectV1_FromNative(const ENUM_SIGNAL_REJECT_REASON r)
{
   switch(r) {
   case SIGNAL_REJECT_NONE:
      return GOV_SIG_REJECT_NONE;
   case SIGNAL_REJECT_NO_CONSENSUS:
      return GOV_SIG_REJECT_CONSENSUS;
   case SIGNAL_REJECT_QUALITY_LOW:
      return GOV_SIG_REJECT_QUALITY;
   case SIGNAL_REJECT_REQUIRE_TREND:
      return GOV_SIG_REJECT_TREND;
   case SIGNAL_REJECT_REQUIRE_KEYLEVEL:
      return GOV_SIG_REJECT_KEYLEVEL;
   case SIGNAL_REJECT_REQUIRE_MOMENTUM:
      return GOV_SIG_REJECT_MOMENTUM;
   case SIGNAL_REJECT_MAX_POSITIONS:
      return GOV_SIG_REJECT_MAX_POSITIONS;
   case SIGNAL_REJECT_MAX_CONSEC_LOSSES:
      return GOV_SIG_REJECT_RISK;
   case SIGNAL_REJECT_RISK_HALT:
      return GOV_SIG_REJECT_RISK;
   case SIGNAL_REJECT_TIME_FILTER:
      return GOV_SIG_REJECT_SESSION;
   case SIGNAL_REJECT_SPREAD:
      return GOV_SIG_REJECT_SPREAD;
   case SIGNAL_REJECT_MARKET_UPDATE_FAIL:
      return GOV_SIG_REJECT_VOLATILITY;
   default:
      return GOV_SIG_REJECT_UNKNOWN;
   }
}

#endif // __AURUM_GOV_SIG_REJECT_REASON_V1_MQH__
