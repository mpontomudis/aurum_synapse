//+------------------------------------------------------------------+
//| GovernanceContinuityAwarenessV1.mqh                             |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — continuity awareness  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_CONTAW_V1_MQH__
#define __AURUM_GOV_CON_CONTAW_V1_MQH__

#include "GovernanceConsciousnessDatasetV1.mqh"
#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalDatasetV1.mqh"
#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"

bool GovContAwareV1_Compute(const SGovReplayTimelineV1 &tl, const SGovTemporalSummaryV1 &tmp, const SGovCivilizationSummaryV1 &civ, SGovContinuityAwarenessV1 &out, string &out_err) {
    out_err = "";
    GovConDsV1_InitContAware(out);
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    int cont_epochs = 0;
    for(int k = 0; k < n; k++) {
        if(tl.epochs[k].recovery_allowed > 0 && tl.epochs[k].execution_allowed > 0)
            cont_epochs++;
    }
    out.continuity_persistence_milli = GovClampInt32((n > 0) ? (cont_epochs * 1000000) / n : 0, 0, 1000000000);
    out.long_horizon_awareness_milli = GovClampInt32(GovSaturatingAdd32(tmp.long_cycle_survivability_milli / 2, tmp.temporal_stability_milli / 2), 0, 1000000000);
    out.replay_continuity_stability_milli = GovClampInt32(GovSaturatingAdd32(tmp.continuity_strength_milli, n * 10000), 0, 1000000000);
    out.governance_survival_continuity_milli = GovClampInt32(GovSaturatingAdd32(tmp.continuity_strength_milli / 2, out.continuity_persistence_milli / 2), 0, 1000000000);
    out.civilization_continuity_awareness_milli = GovClampInt32(GovSaturatingAdd32(civ.continuity_milli, civ.memory_stable_cycles * 50000), 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_CON_CONTAW_V1_MQH__
