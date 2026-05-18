//+------------------------------------------------------------------+
//| GovernanceComparisonDatasetV1.mqh                              |
//| PHASE 20C — one governance run snapshot for baselines            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CMP_DATASET_V1_MQH__
#define __AURUM_GOV_CMP_DATASET_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovCmpRunRecordV1
{
   int      valid;
   string   run_ts;
   string   sym;
   string   tf;
   string   git;
   int      build_no;
   long     deposit_cents;
   int      leverage;
   int      strat_bits;
   double   pf;
   double   dd_bal_pct;
   double   dd_eq_pct;
   int      winrate_x1000;
   int      max_tox;
   int      trades;
   int      lineage_roots;
   int      lineage_children;
   int      recovery_cascades;
   string   regime_pf_compact;
   string   vol_pf_compact;
   int      eco_diversity_pm;
   int      eco_entropy_pm;
   int      eco_balance_pm;
   int      eco_dom_slot;
   int      eco_dom_frac_x1000;
};

inline void GovCmpDsV1_Init(SGovCmpRunRecordV1 &r)
{
   r.valid = 0;
   r.run_ts = "";
   r.sym = "";
   r.tf = "";
   r.git = "";
   r.build_no = 0;
   r.deposit_cents = 0;
   r.leverage = 0;
   r.strat_bits = 0;
   r.pf = 0.0;
   r.dd_bal_pct = 0.0;
   r.dd_eq_pct = 0.0;
   r.winrate_x1000 = 0;
   r.max_tox = 0;
   r.trades = 0;
   r.lineage_roots = 0;
   r.lineage_children = 0;
   r.recovery_cascades = 0;
   r.regime_pf_compact = "";
   r.vol_pf_compact = "";
   r.eco_diversity_pm = 0;
   r.eco_entropy_pm = 0;
   r.eco_balance_pm = 0;
   r.eco_dom_slot = 0;
   r.eco_dom_frac_x1000 = 0;
}

#endif // __AURUM_GOV_CMP_DATASET_V1_MQH__
