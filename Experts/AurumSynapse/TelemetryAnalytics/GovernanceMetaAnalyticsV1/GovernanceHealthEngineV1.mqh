//+------------------------------------------------------------------+
//| GovernanceHealthEngineV1.mqh                                   |
//| Deterministic governance health index (observational only).      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_HEALTH_ENGINE_V1_MQH__
#define __AURUM_GOV_HEALTH_ENGINE_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "GovernanceMetaAnalyticsDatasetV1.mqh"

bool GovernanceHealthEngineV1_Compute(const SGovReplayTimelineV1 &tl, const SGovMetaIncidentStatsV1 &inc, const SGovMetaContainmentStatsV1 &con,
                                      const SGovMetaRegimeStatsV1 &reg, SGovMetaGovernanceHealthV1 &out, string &out_err) {
    out_err = "";
    GovernanceMetaAnalyticsDatasetV1_InitHealth(out);
    out.replay_stability_0_1000 = (tl.integrity_ok != 0) ? 1000 : 0;
    out.containment_quality_0_1000 = GovClampInt32(con.containment_stabilization_ratio_per_1000, 0, 1000);
    out.survivability_preservation_0_1000 = GovClampInt32(inc.survivability_preservation_score_0_1000, 0, 1000);
    out.escalation_interruption_0_1000 = GovClampInt32(con.prevented_escalation_ratio_per_1000, 0, 1000);
    out.quarantine_effectiveness_0_1000 = GovClampInt32(con.quarantine_stabilization_efficiency_0_1000, 0, 1000);
    out.recovery_stabilization_0_1000 = GovClampInt32(reg.recovery_stabilization_score_0_1000, 0, 1000);
    out.execution_containment_efficiency_0_1000 = GovClampInt32(con.governance_intervention_efficiency_per_1000, 0, 1000);
    const int sum = out.replay_stability_0_1000 + out.containment_quality_0_1000 + out.survivability_preservation_0_1000 + out.escalation_interruption_0_1000 +
                    out.quarantine_effectiveness_0_1000 + out.recovery_stabilization_0_1000 + out.execution_containment_efficiency_0_1000;
    out.governance_health_index_0_1000 = sum / 7;
    return true;
}

#endif // __AURUM_GOV_HEALTH_ENGINE_V1_MQH__
