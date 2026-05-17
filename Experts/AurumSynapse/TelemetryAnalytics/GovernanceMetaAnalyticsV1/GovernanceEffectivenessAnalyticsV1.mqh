//+------------------------------------------------------------------+
//| GovernanceEffectivenessAnalyticsV1.mqh                         |
//| Governance effectiveness — integer ratios from replay signals.   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EFFECTIVENESS_ANALYTICS_V1_MQH__
#define __AURUM_GOV_EFFECTIVENESS_ANALYTICS_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceContainmentAnalyticsV1.mqh"
#include "GovernanceMetaAnalyticsDatasetV1.mqh"

bool GovernanceEffectivenessAnalyticsV1_Compute(const SGovReplayTimelineV1 &t, const SGovContainmentMetricsV1 &cm, SGovMetaContainmentStatsV1 &out, string &out_err) {
    out_err = "";
    GovernanceMetaAnalyticsDatasetV1_InitContainmentStats(out);
    const int n = ArraySize(t.epochs);
    const int den = (n > 0) ? n : 1;
    out.prevented_escalation_epochs = cm.prevented_escalation_epochs;
    out.prevented_escalation_ratio_per_1000 = GovernanceMetaAnalyticsDatasetV1_RatePer1000(cm.prevented_escalation_epochs, den);
    out.containment_stabilization_ratio_per_1000 = GovClampInt32(cm.survivability_preservation_score_0_1000, 0, 1000);
    out.survivability_preservation_delta_score_0_1000 = GovClampInt32(cm.survivability_preservation_score_0_1000, 0, 1000);
    out.forced_flatten_effectiveness_0_1000 = GovClampInt32(1000 - GovernanceMetaAnalyticsDatasetV1_RatePer1000(cm.forced_flatten_count, den), 0, 1000);
    out.quarantine_stabilization_efficiency_0_1000 = GovClampInt32(1000 - GovernanceMetaAnalyticsDatasetV1_RatePer1000(cm.quarantine_hard_epoch_hits, den), 0, 1000);
    out.toxic_regime_interruption_ratio_per_1000 = GovernanceMetaAnalyticsDatasetV1_RatePer1000(cm.toxic_interrupt_epochs, den);
    out.governance_intervention_efficiency_per_1000 = GovClampInt32(
        (cm.prevented_escalation_epochs + cm.toxic_interrupt_epochs) * 1000 / den, 0, 1000);
    out.throttle_aggressiveness_score_0_1000 = GovClampInt32(cm.throttle_containment_score_0_1000, 0, 1000);
    out.quarantine_aggressiveness_score_0_1000 = GovClampInt32(GovernanceMetaAnalyticsDatasetV1_RatePer1000(cm.quarantine_hard_epoch_hits, den), 0, 1000);
    out.exposure_compression_sum_milli = cm.exposure_compression_sum_milli;
    return true;
}

#endif // __AURUM_GOV_EFFECTIVENESS_ANALYTICS_V1_MQH__
