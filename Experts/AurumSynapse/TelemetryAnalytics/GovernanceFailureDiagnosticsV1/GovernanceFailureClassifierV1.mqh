//+------------------------------------------------------------------+
//| GovernanceFailureClassifierV1.mqh                              |
//| PHASE 20C — derive failure events from existing telemetry        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_FAILURE_CLASSIFIER_V1_MQH__
#define __AURUM_GOV_FAILURE_CLASSIFIER_V1_MQH__

#include "GovernanceFailureDatasetV1.mqh"
#include "../GovernanceRuntimeObservabilityExportV1/GovernanceRuntimeObservabilityDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyAttributionDatasetV1.mqh"
#include "../GovernanceStrategyAttributionIntelligenceV1/GovernanceStrategyToxicityAnalyticsV1.mqh"
#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingModuleV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernancePositionLineageRegistryV1.mqh"
#include "../GovernancePositionLineageIntelligenceV1/GovernanceRecoveryChainAnalyticsV1.mqh"
#include "../GovernanceRuntimeVisualObservabilityV1/GovernanceRuntimeVisualDatasetV1.mqh"

inline void GovFailureClsV1_Build(const string sym,
                                  const SGovRuntimeTaggingModuleV1 &mod,
                                  const SGovLineageRegistryStoreV1 &lin,
                                  const SGovRecoveryStoreV1 &rec,
                                  SGovStratAttribSummaryV1 &sum,
                                  const SGovVisualExecSummaryV1 &ex,
                                  SGovFailureEventListV1 &out)
{
   GovFailureDsV1_InitList(out);
   SGovFailureEventV1 e;

   const int spread_pts = (int)SymbolInfoInteger(sym, SYMBOL_SPREAD);
   if(spread_pts >= 250) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_SPREAD_EXPLOSION_V1;
      e.severity = (spread_pts >= 400) ? GOV_FAIL_SEV_CRITICAL_V1 : GOV_FAIL_SEV_WARNING_V1;
      e.title = "SPREAD_EXPLOSION";
      e.symbol = sym;
      e.metric_i = spread_pts;
      e.detail = "Spread points elevated vs baseline governance thresholds.";
      GovFailureDsV1_Push(out, e);
   }

   if(mod.tel.registry_overflow > 0 || mod.tel.tag_injection_fail > 0) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_EXECUTION_REJECTION_V1;
      e.severity = GOV_FAIL_SEV_HIGH_V1;
      e.title = "TAGGING_FAULT";
      e.detail = "registry_overflow=" + IntegerToString(mod.tel.registry_overflow) + " tag_injection_fail=" + IntegerToString(mod.tel.tag_injection_fail);
      GovFailureDsV1_Push(out, e);
   }

   if(mod.tel.orphan_close > 0) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_LIQUIDITY_COLLAPSE_V1;
      e.severity = GOV_FAIL_SEV_WARNING_V1;
      e.title = "ORPHAN_CLOSE_CLUSTER";
      e.detail = "orphan_close=" + IntegerToString(mod.tel.orphan_close);
      GovFailureDsV1_Push(out, e);
   }

   const SGovRuntimeObsCapitalSnapV1 c = g_gov_runtime_obs_report_v1.cap;
   if(c.result_code == (int)GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_LOT_COLLAPSE_V1;
      e.severity = GOV_FAIL_SEV_CRITICAL_V1;
      e.title = "LOT_NORMALIZATION_COLLAPSE";
      e.detail = "Requested lot could not be normalized to broker grid.";
      GovFailureDsV1_Push(out, e);
   }
   if(c.result_code == (int)GOV_CAP_RES_FREE_MARGIN_LOW || c.result_code == (int)GOV_CAP_RES_INSUFFICIENT_MARGIN) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_MARGIN_STRESS_V1;
      e.severity = GOV_FAIL_SEV_CRITICAL_V1;
      e.title = "MARGIN_STRESS";
      e.detail = "Free margin / insufficient margin snapshot on last governance feed.";
      GovFailureDsV1_Push(out, e);
   }
   if(StringLen(c.last_block_reason) > 0) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_RISK_MANAGER_BLOCK_V1;
      e.severity = GOV_FAIL_SEV_HIGH_V1;
      e.title = "RISK_MANAGER_BLOCK";
      e.detail = c.last_block_reason;
      GovFailureDsV1_Push(out, e);
   }

   if(ex.balance_dd_rel_pct > 35.0 || ex.equity_dd_rel_pct > 40.0) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_DRAWDOWN_STRESS_V1;
      e.severity = GOV_FAIL_SEV_HIGH_V1;
      e.title = "DRAWDOWN_STRESS";
      e.metric_d = ex.balance_dd_rel_pct;
      e.detail = "balance_dd_rel=" + DoubleToString(ex.balance_dd_rel_pct, 2) + " equity_dd_rel=" + DoubleToString(ex.equity_dd_rel_pct, 2);
      GovFailureDsV1_Push(out, e);
   }

   int max_rd = 0;
   for(int i = 0; i < GOV_LINEAGE_MAX_NODES_V1; i++) {
      if(lin.nodes[i].active == 1)
         max_rd = MathMax(max_rd, lin.nodes[i].recovery_depth);
   }
   for(int a = 0; a < GOV_LINEAGE_ARCHIVE_MAX_V1; a++) {
      if(lin.archive_nodes[a].active == 2)
         max_rd = MathMax(max_rd, lin.archive_nodes[a].recovery_depth);
   }
   if(max_rd >= 3) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_RECOVERY_AMPLIFICATION_V1;
      e.severity = GOV_FAIL_SEV_CRITICAL_V1;
      e.title = "RECOVERY_AMPLIFICATION";
      e.metric_i = max_rd;
      e.detail = "Deep recovery generations observed across lineage archive/active.";
      GovFailureDsV1_Push(out, e);
   }

   int casc = 0;
   for(int k = 0; k < GOV_LINEAGE_MAX_RECOVERY_V1; k++) {
      if(rec.chains[k].root_lineage_id == 0)
         continue;
      if(rec.chains[k].generation_depth >= 2)
         casc++;
   }
   if(casc >= 3) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_STOP_CASCADE_V1;
      e.severity = GOV_FAIL_SEV_WARNING_V1;
      e.title = "RECOVERY_CHAIN_VOLUME";
      e.metric_i = casc;
      e.detail = "Recovery chain ring shows sustained cascade signatures.";
      GovFailureDsV1_Push(out, e);
   }

   for(int z = 0; z < GOV_SATTR_STRAT_COUNT_V1; z++)
      GovStratToxV1_Score(z, sum, sum.tox[z]);
   int hi = 0;
   int hi_sid = -1;
   for(int s = 0; s < GOV_SATTR_STRAT_COUNT_V1; s++) {
      if(sum.tox[s].score_0_1000 >= 700 && sum.bd.by_strat[s].trades > 0) {
         hi++;
         hi_sid = s;
      }
   }
   if(hi >= 2) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_TOXIC_STRATEGY_ESCALATION_V1;
      e.severity = GOV_FAIL_SEV_HIGH_V1;
      e.title = "TOXIC_STRATEGY_ESCALATION";
      e.detail = "Multiple strategies exceed toxicity governance band.";
      GovFailureDsV1_Push(out, e);
   } else if(hi == 1 && hi_sid >= 0) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_VOLATILITY_MISMATCH_V1;
      e.severity = GOV_FAIL_SEV_WARNING_V1;
      e.title = "VOLATILITY_MISMATCH";
      e.metric_i = sum.tox[hi_sid].vol_toxicity;
      e.detail = "Single-strategy toxicity spike with live trades.";
      GovFailureDsV1_Push(out, e);
   }

   int regime_skew = 0;
   for(int r = 0; r < GOV_SATTR_REGIME_COUNT_V1; r++) {
      if(sum.bd.regime.by_reg[r].trades > 50 && sum.bd.regime.by_reg[r].pf_milli < 800)
         regime_skew++;
   }
   if(regime_skew >= 2) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_REGIME_MISMATCH_V1;
      e.severity = GOV_FAIL_SEV_WARNING_V1;
      e.title = "REGIME_MISMATCH";
      e.metric_i = regime_skew;
      e.detail = "Multiple regimes trade-heavy with compressed PF.";
      GovFailureDsV1_Push(out, e);
   }

   if(ex.total_trades > 600 && ex.profit_factor < 1.0) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_POSITION_OVEREXPOSURE_V1;
      e.severity = GOV_FAIL_SEV_WARNING_V1;
      e.title = "OVERTRADING_PF_COMPRESSION";
      e.detail = "High trade count with sub-unity profit factor.";
      GovFailureDsV1_Push(out, e);
   }

   if(lin.tel.overflow_events > 0) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_TAIL_RISK_CLUSTER_V1;
      e.severity = GOV_FAIL_SEV_HIGH_V1;
      e.title = "LINEAGE_STORE_PRESSURE";
      e.metric_i = lin.tel.overflow_events;
      e.detail = "Lineage registry ring pressure / overflow telemetry.";
      GovFailureDsV1_Push(out, e);
   }

   if(lin.tel.replay_mismatches > 0) {
      GovFailureDsV1_InitEvent(e);
      e.kind = GOV_FAIL_KIND_SLIPPAGE_STRESS_V1;
      e.severity = GOV_FAIL_SEV_INFO_V1;
      e.title = "LINEAGE_REPLAY_MISMATCH";
      e.metric_i = lin.tel.replay_mismatches;
      e.detail = "Recovery replay reconciliation flagged mismatches (informational).";
      GovFailureDsV1_Push(out, e);
   }
}

#endif // __AURUM_GOV_FAILURE_CLASSIFIER_V1_MQH__
