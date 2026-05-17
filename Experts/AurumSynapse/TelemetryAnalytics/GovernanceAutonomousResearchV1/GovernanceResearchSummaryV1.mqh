//+------------------------------------------------------------------+
//| GovernanceResearchSummaryV1.mqh                              |
//| Assemble deterministic research summary from meta + replay.     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESEARCH_SUMMARY_V1_MQH__
#define __AURUM_GOV_RESEARCH_SUMMARY_V1_MQH__

#include "GovernanceResearchDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceMetaAnalyticsV1/GovernanceMetaAnalyticsDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

bool GovResSumV1_Build(const SGovReplayTimelineV1 &tl, const SGovMetaGovernanceHealthV1 &h, const SGovMetaIncidentStatsV1 &inc, const SGovMetaContainmentStatsV1 &con,
                       const SGovMetaPolicyFingerprintV1 &fp, SGovResearchSummaryV1 &out, string &out_err) {
    out_err = "";
    GovResDsV1_InitSum(out);
    out.observation_window_epochs = ArraySize(tl.epochs);
    out.incident_density_per_1000 = inc.incident_frequency_per_1000_epochs;
    out.containment_quality_0_1000 = GovClampInt32(con.containment_stabilization_ratio_per_1000, 0, 1000);
    out.survivability_preservation_0_1000 = GovClampInt32(inc.survivability_preservation_score_0_1000, 0, 1000);
    out.quarantine_pressure_0_1000 = GovClampInt32(inc.quarantine_frequency_per_1000_epochs, 0, 1000);
    int frag = 0;
    const int ne = ArraySize(tl.epochs);
    for(int i = 0; i < ne; i++) {
        if(tl.epochs[i].regime_state >= 2 && tl.epochs[i].regime_state <= 3)
            frag = GovSaturatingAdd32(frag, 1);
    }
    out.regime_fragility_0_1000 = (ne > 0) ? GovClampInt32(frag * 1000 / ne, 0, 1000) : 0;
    int rec_ok = 0;
    for(int j = 0; j < ne; j++) {
        if(tl.epochs[j].recovery_allowed == 1)
            rec_ok = GovSaturatingAdd32(rec_ok, 1);
    }
    out.recovery_stability_0_1000 = (ne > 0) ? GovClampInt32(rec_ok * 1000 / ne, 0, 1000) : 0;
    out.throttle_pressure_0_1000 = GovClampInt32(con.throttle_aggressiveness_score_0_1000, 0, 1000);
    out.governance_health_index = GovClampInt32(h.governance_health_index_0_1000, 0, 1000);
    out.dominant_behavior_fingerprint = fp.policy_behavior_fingerprint;
    out.policy_fingerprint = fp.dominant_policy_fingerprint;
    out.replay_hash = tl.source_concat_sha256_hex;
    return true;
}

#endif // __AURUM_GOV_RESEARCH_SUMMARY_V1_MQH__
