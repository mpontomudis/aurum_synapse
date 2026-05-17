//+------------------------------------------------------------------+
//| GovernanceStrategyTradeTaggerV1.mqh                              |
//| Deterministic tag strings (fixed vocabulary).                    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRAT_TAG_V1_MQH__
#define __AURUM_GOV_STRAT_TAG_V1_MQH__

#include "GovernanceStrategyAttributionDatasetV1.mqh"

#define GOV_SATTR_TAG_MAX 63

inline string GovStratTagV1_StrategyCode(const int strat)
{
   switch(GovClampInt32(strat, 0, 7)) {
   case GOV_STRAT_TF: return "TF";
   case GOV_STRAT_BO: return "BO";
   case GOV_STRAT_MR: return "MR";
   case GOV_STRAT_SD: return "SD";
   case GOV_STRAT_SM: return "SM";
   case GOV_STRAT_PA: return "PA";
   case GOV_STRAT_GR: return "GR";
   default: return "MS";
   }
}

inline string GovStratTagV1_RegimeCode(const int regime)
{
   switch(GovClampInt32(regime, 0, 5)) {
   case GOV_REGIME_TREND: return "TREND";
   case GOV_REGIME_CHOP: return "CHOP";
   case GOV_REGIME_EXPANSION: return "EXP";
   case GOV_REGIME_COMPRESSION: return "COMP";
   case GOV_REGIME_SWEEP: return "SWP";
   default: return "TOX";
   }
}

inline string GovStratTagV1_VolCode(const int vol)
{
   switch(GovClampInt32(vol, 0, 3)) {
   case GOV_SATTR_VOL_LOW: return "LOWVOL";
   case GOV_SATTR_VOL_MED: return "MEDVOL";
   case GOV_SATTR_VOL_HIGH: return "HIGHVOL";
   default: return "XTVOL";
   }
}

inline string GovStratTagV1_SessionCode(const int sess)
{
   switch(GovClampInt32(sess, 0, 3)) {
   case GOV_SATTR_SESS_ASIA: return "ASIA";
   case GOV_SATTR_SESS_LONDON: return "LON";
   case GOV_SATTR_SESS_NY: return "NY";
   default: return "OVR";
   }
}

inline void GovStratTagV1_BuildTag(const int strat, const int regime, const int vol, const int sess, string &out_tag)
{
   const string a = GovStratTagV1_StrategyCode(strat);
   const string b = GovStratTagV1_RegimeCode(regime);
   const string c = GovStratTagV1_VolCode(vol);
   const string d = GovStratTagV1_SessionCode(sess);
   out_tag = a + "|" + b + "|" + c + "|" + d;
   if(StringLen(out_tag) > GOV_SATTR_TAG_MAX)
      out_tag = StringSubstr(out_tag, 0, GOV_SATTR_TAG_MAX);
}

#endif // __AURUM_GOV_STRAT_TAG_V1_MQH__
