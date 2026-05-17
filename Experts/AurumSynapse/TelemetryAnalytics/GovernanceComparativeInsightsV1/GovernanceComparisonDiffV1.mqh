//+------------------------------------------------------------------+
//| GovernanceComparisonDiffV1.mqh                                 |
//| PHASE 20C — textual deltas baseline vs current                   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CMP_DIFF_V1_MQH__
#define __AURUM_GOV_CMP_DIFF_V1_MQH__

#include "GovernanceComparisonDatasetV1.mqh"

struct SGovCmpDiffLinesV1
{
   string improve[16];
   string degrade[16];
   int    ni;
   int    nd;
};

inline void GovCmpDiffV1_Clear(SGovCmpDiffLinesV1 &d)
{
   d.ni = 0;
   d.nd = 0;
   for(int i = 0; i < 16; i++) {
      d.improve[i] = "";
      d.degrade[i] = "";
   }
}

inline bool GovCmpDiffV1_PushImp(SGovCmpDiffLinesV1 &d, const string s)
{
   if(d.ni >= 16)
      return false;
   d.improve[d.ni++] = s;
   return true;
}

inline bool GovCmpDiffV1_PushDeg(SGovCmpDiffLinesV1 &d, const string s)
{
   if(d.nd >= 16)
      return false;
   d.degrade[d.nd++] = s;
   return true;
}

inline void GovCmpDiffV1_Build(const SGovCmpRunRecordV1 &b, const SGovCmpRunRecordV1 &c, SGovCmpDiffLinesV1 &out)
{
   GovCmpDiffV1_Clear(out);
   if(b.valid == 0 || c.valid == 0)
      return;
   if(c.pf > b.pf + 0.02)
      GovCmpDiffV1_PushImp(out, "PF improved " + DoubleToString(b.pf, 3) + " -> " + DoubleToString(c.pf, 3));
   if(c.pf + 0.02 < b.pf)
      GovCmpDiffV1_PushDeg(out, "PF degraded " + DoubleToString(b.pf, 3) + " -> " + DoubleToString(c.pf, 3));
   if(c.dd_bal_pct + 1.0 < b.dd_bal_pct)
      GovCmpDiffV1_PushImp(out, "Balance DD% improved " + DoubleToString(b.dd_bal_pct, 2) + " -> " + DoubleToString(c.dd_bal_pct, 2));
   if(c.dd_bal_pct > b.dd_bal_pct + 1.0)
      GovCmpDiffV1_PushDeg(out, "Balance DD% worsened " + DoubleToString(b.dd_bal_pct, 2) + " -> " + DoubleToString(c.dd_bal_pct, 2));
   if(c.max_tox + 50 < b.max_tox)
      GovCmpDiffV1_PushImp(out, "Toxicity max score improved " + IntegerToString(b.max_tox) + " -> " + IntegerToString(c.max_tox));
   if(c.max_tox > b.max_tox + 50)
      GovCmpDiffV1_PushDeg(out, "Toxicity max score worsened " + IntegerToString(b.max_tox) + " -> " + IntegerToString(c.max_tox));
   if(c.recovery_cascades + 2 < b.recovery_cascades)
      GovCmpDiffV1_PushImp(out, "Recovery cascade count reduced " + IntegerToString(b.recovery_cascades) + " -> " + IntegerToString(c.recovery_cascades));
   if(c.recovery_cascades > b.recovery_cascades + 2)
      GovCmpDiffV1_PushDeg(out, "Recovery cascade count increased " + IntegerToString(b.recovery_cascades) + " -> " + IntegerToString(c.recovery_cascades));
   if(c.strat_bits != b.strat_bits)
      GovCmpDiffV1_PushDeg(out, "Strategy activation map changed (bits " + IntegerToString(b.strat_bits) + " -> " + IntegerToString(c.strat_bits) + ")");
}

#endif // __AURUM_GOV_CMP_DIFF_V1_MQH__
