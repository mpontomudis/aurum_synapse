//+------------------------------------------------------------------+
//| GovernanceFederationEngineV1.mqh                                |
//| Deterministic federation aggregation (integer-only).              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_FED_ENG_V1_MQH__
#define __AURUM_GOV_CIV_FED_ENG_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

bool GovFedEngV1_Build(const SGovEvolutionSummaryV1 &evo, const SGovStrategicSummaryV1 &strat, const SGovResilienceProfileV1 &rp, SGovCivilizationFederationV1 &out, string &out_err) {
    out_err = "";
    GovCivDsV1_InitFed(out);
    const int mc = GovClampInt32(evo.generation_span, 1, 32);
    out.member_count = mc;
    int h = GovClampInt32(evo.lineage_id, 0, 1000000);
    const int slen = StringLen(evo.replay_hash);
    for(int k = 0; k < slen && k < 24; k++)
        h = GovSaturatingAdd32(h, (int)(StringGetCharacter(evo.replay_hash, k) & 0xFF));
    h = GovSaturatingAdd32(h, StringLen(rp.summary.replay_hash));
    out.federation_id = GovClampInt32(1 + (h & 0x7FFFFFFF) % 100000, 1, 100000);
    const int sum_res = GovSaturatingAdd32(evo.mean_survivability_0_1000 * 1000, rp.summary.survivability_resilience_0_1000 * 500);
    const int sum_surv = GovSaturatingAdd32(evo.mean_survivability_0_1000 * 1000, rp.summary.survivability_resilience_0_1000 * 1000);
    out.avg_resilience_milli = sum_res / mc;
    out.avg_survivability_milli = sum_surv / mc;
    out.federation_stability_milli = GovClampInt32(strat.sustainability_index_0_1000 * 1000, 0, 1000000);
    out.federation_collapse_risk_milli = GovClampInt32(evo.mean_degeneration_score_0_1000 * 1000, 0, 1000000);
    return true;
}

#endif // __AURUM_GOV_CIV_FED_ENG_V1_MQH__
