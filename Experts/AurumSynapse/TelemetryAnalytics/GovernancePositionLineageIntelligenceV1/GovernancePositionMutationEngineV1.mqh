//+------------------------------------------------------------------+
//| GovernancePositionMutationEngineV1.mqh                            |
//| Integer / volume deltas only — deterministic classification.       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POS_MUTATION_ENG_V1_MQH__
#define __AURUM_GOV_POS_MUTATION_ENG_V1_MQH__

#include "GovernancePositionLineageDatasetV1.mqh"

inline int GovMutationV1_Classify(const int deal_entry_in,
                                 const long prev_vol_milli,
                                 const long new_vol_milli,
                                 const long profit_cents_on_out,
                                 const int deal_reason_sl,
                                 const int is_opposite_dir_hedge_hint)
{
   if(deal_entry_in == (int)DEAL_ENTRY_IN) {
      if(prev_vol_milli <= 0)
         return (int)GOV_MUT_NEW_ENTRY;
      if(new_vol_milli > prev_vol_milli)
         return (int)GOV_MUT_SCALE_IN;
      if(new_vol_milli < prev_vol_milli && new_vol_milli > 0)
         return (int)GOV_MUT_PARTIAL_CLOSE;
      if(is_opposite_dir_hedge_hint != 0)
         return (int)GOV_MUT_HEDGE;
      return (int)GOV_MUT_CONTINUATION;
   }
   if(deal_entry_in == (int)DEAL_ENTRY_OUT) {
      if(deal_reason_sl != 0 && profit_cents_on_out < 0)
         return (int)GOV_MUT_RECOVERY;
      if(new_vol_milli <= 0)
         return (int)GOV_MUT_SCALE_OUT;
      if(new_vol_milli < prev_vol_milli)
         return (int)GOV_MUT_PARTIAL_CLOSE;
      return (int)GOV_MUT_SCALE_OUT;
   }
   if(deal_entry_in == (int)DEAL_ENTRY_INOUT)
      return (int)GOV_MUT_REVERSAL;
   return (int)GOV_MUT_NONE;
}

inline int GovMutationV1_Detect(const int deal_entry,
                                const long prev_vol_milli,
                                const long new_vol_milli,
                                const long profit_cents,
                                const int deal_reason_sl,
                                const int hedge_hint)
{
   return GovMutationV1_Classify(deal_entry, prev_vol_milli, new_vol_milli, profit_cents, deal_reason_sl, hedge_hint);
}

inline bool GovMutationV1_IsRecovery(const int mt)
{
   return (mt == (int)GOV_MUT_RECOVERY);
}

inline bool GovMutationV1_IsScaleIn(const int mt)
{
   return (mt == (int)GOV_MUT_SCALE_IN);
}

inline bool GovMutationV1_IsScaleOut(const int mt)
{
   return (mt == (int)GOV_MUT_SCALE_OUT);
}

inline bool GovMutationV1_IsPartialClose(const int mt)
{
   return (mt == (int)GOV_MUT_PARTIAL_CLOSE);
}

#endif // __AURUM_GOV_POS_MUTATION_ENG_V1_MQH__
