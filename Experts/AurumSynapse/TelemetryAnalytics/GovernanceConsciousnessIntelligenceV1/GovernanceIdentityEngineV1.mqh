//+------------------------------------------------------------------+
//| GovernanceIdentityEngineV1.mqh                                  |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — identity profile      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_ID_V1_MQH__
#define __AURUM_GOV_CON_ID_V1_MQH__

#include "GovernanceConsciousnessDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalDatasetV1.mqh"
#include "../GovernanceEcologyIntelligenceV1/GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDatasetV1.mqh"

bool GovIdentityV1_Build(const SGovReplayTimelineV1 &tl, const SGovResilienceProfileV1 &rp, const SGovEvolutionSummaryV1 &evo, const SGovCivilizationSummaryV1 &civ, const SGovTemporalSummaryV1 &tmp, const SGovEcologySummaryV1 &eco, SGovIdentityProfileV1 &out, string &out_err) {
    out_err = "";
    GovConDsV1_InitIdentity(out);
    out.replay_identity_fingerprint = tl.source_concat_sha256_hex;
    out.policy_identity_fingerprint = rp.summary.policy_fingerprint;
    out.governance_identity_id = 1;
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    out.identity_persistence_epochs = n;
    int rec_run = 0;
    int surv_acc = 0;
    for(int k = 0; k < n; k++) {
        surv_acc = GovSaturatingAdd32(surv_acc, GovClampInt32(tl.epochs[k].survivability_ms, 0, 100000));
        if(tl.epochs[k].recovery_allowed > 0)
            rec_run++;
    }
    const int surv_mean = (n > 0) ? surv_acc / n : 0;
    out.identity_recovery_strength_milli = GovClampInt32(GovSaturatingAdd32(rec_run * 100000 / GovClampInt32(n, 1, 100000), surv_mean * 100), 0, 1000000000);
    const int civ_st = GovClampInt32(civ.civilization_stability_milli / 1000, 0, 1000);
    const int eco_coh = GovClampInt32(eco.coexistence_quality_milli / 1000, 0, 1000);
    const int tmp_cont = GovClampInt32(tmp.continuity_strength_milli / 1000, 0, 1000);
    const int evo_ln = GovClampInt32(evo.lineage_id, 0, 1000000);
    out.identity_integrity_milli = GovClampInt32(GovSaturatingAdd32(civ_st * 80000, GovSaturatingAdd32(tmp_cont * 70000, eco_coh * 60000)) + GovClampInt32(evo_ln % 1000, 0, 999) * 100, 0, 1000000000);
    const int frag_civ = GovClampInt32(1000 - civ.hierarchy_stability_milli / 1000, 0, 1000);
    const int frag_eco = GovClampInt32(eco.predation_pressure_milli / 1000, 0, 1000000);
    const int frag_tmp = GovClampInt32(tmp.era_transition_pressure_milli / 1000, 0, 1000000);
    out.identity_fragmentation_milli = GovClampInt32(GovSaturatingAdd32(frag_civ * 50000, GovSaturatingAdd32(frag_eco / 10, frag_tmp / 20)), 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_CON_ID_V1_MQH__
