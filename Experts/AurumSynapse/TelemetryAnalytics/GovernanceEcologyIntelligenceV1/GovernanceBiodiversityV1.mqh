//+------------------------------------------------------------------+
//| GovernanceBiodiversityV1.mqh                                    |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — integer diversity metrics     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_BIODIV_V1_MQH__
#define __AURUM_GOV_ECO_BIODIV_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "GovernanceSpeciesEngineV1.mqh"

int GovBiodivV1_HistMaxSharePermille(const int &hist[], const int nb) {
    int sum = 0;
    int mx = 0;
    for(int k = 0; k < nb; k++) {
        sum = GovSaturatingAdd32(sum, hist[k]);
        mx = MathMax(mx, hist[k]);
    }
    if(sum <= 0)
        return 0;
    return GovClampInt32((mx * 1000) / sum, 0, 1000);
}

bool GovBiodivV1_Compute(const SGovReplayTimelineV1 &tl, const SGovEcologyEntityV1 &ents[], const int n_ent, const SGovEcologySpeciesV1 &sp[], const int n_sp, const SGovCivilizationSummaryV1 &civ, SGovEcologyBiodiversityV1 &out, string &out_err) {
    out_err = "";
    GovEcoDsV1_InitBiodiv(out);
    const int nb = 7;
    int hist[7];
    for(int h = 0; h < nb; h++)
        hist[h] = 0;
    const int ns = GovClampInt32(n_sp, 0, 64);
    for(int s = 0; s < ns; s++) {
        const int code = GovClampInt32(sp[s].species_code, 0, nb - 1);
        hist[code] = GovSaturatingAdd32(hist[code], 1);
    }
    const int max_share = GovBiodivV1_HistMaxSharePermille(hist, nb);
    out.diversity_score_milli = GovClampInt32((1000 - max_share) * 1000, 0, 1000000000);
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    int regime_hist[64];
    for(int r = 0; r < 64; r++)
        regime_hist[r] = 0;
    for(int k = 0; k < n; k++) {
        const int rg = GovClampInt32(tl.epochs[k].regime_state, 0, 63);
        regime_hist[rg] = GovSaturatingAdd32(regime_hist[rg], 1);
    }
    int distinct = 0;
    for(int r = 0; r < 64; r++) {
        if(regime_hist[r] > 0)
            distinct++;
    }
    out.regime_diversity_milli = GovClampInt32(distinct * 150000, 0, 1000000000);
    int rs_sum = 0;
    int rs_min = 1000000000;
    int rs_max = 0;
    const int ne = GovClampInt32(n_ent, 0, 64);
    for(int e = 0; e < ne; e++) {
        const int fake_res = GovClampInt32(1000000 - ents[e].collapse_exposure_milli / 2, 0, 1000000000);
        rs_sum = GovSaturatingAdd32(rs_sum, fake_res);
        rs_min = MathMin(rs_min, fake_res);
        rs_max = MathMax(rs_max, fake_res);
    }
    out.resilience_diversity_milli = (ne > 0) ? GovClampInt32(GovSaturatingAdd32(rs_max, -rs_min) + rs_sum / ne, 0, 1000000000) : 0;
    int sv_spread = 0;
    if(ne >= 2) {
        int smin = ents[0].survivability_milli;
        int smax = ents[0].survivability_milli;
        for(int e = 1; e < ne; e++) {
            smin = MathMin(smin, ents[e].survivability_milli);
            smax = MathMax(smax, ents[e].survivability_milli);
        }
        sv_spread = GovSaturatingAdd32(smax, -smin);
    }
    out.survivability_diversity_milli = GovClampInt32(sv_spread, 0, 1000000000);
    out.civilization_variation_milli = GovClampInt32(GovSaturatingAdd32(civ.federation_stability_milli / 3, civ.topology_stability_milli / 3), 0, 1000000000);
    out.ecosystem_concentration_risk_milli = GovClampInt32(max_share * 1000, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_ECO_BIODIV_V1_MQH__
