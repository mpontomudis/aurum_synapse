//+------------------------------------------------------------------+
//| GovernanceEcologyExportV1.mqh                                   |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — UTF-8 LF export             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_EXP_V1_MQH__
#define __AURUM_GOV_ECO_EXP_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "GovernancePredatorPreyV1.mqh"

string GovEcoExpV1_JoinInts6(const int a, const int b, const int c, const int d, const int e, const int f) {
    return IntegerToString(a) + "|" + IntegerToString(b) + "|" + IntegerToString(c) + "|" + IntegerToString(d) + "|" + IntegerToString(e) + "|" + IntegerToString(f);
}

string GovEcoExpV1_JoinInts5(const int a, const int b, const int c, const int d, const int e) {
    return IntegerToString(a) + "|" + IntegerToString(b) + "|" + IntegerToString(c) + "|" + IntegerToString(d) + "|" + IntegerToString(e);
}

bool GovEcoExpV1_Bundle(const SGovEcologySummaryV1 &sum, const SGovEcologySpeciesV1 &sp[], const int n_sp, const SGovEcologyPredPreyV1 &pred, const SGovEcologyBiodiversityV1 &bio, const SGovEcologyCollapseV1 &cl, const SGovEcologyCoexistenceV1 &cx, const SGovEcologyResilienceV1 &eres, const SGovEcologyComparisonV1 &cmp, string &out_utf8, string &out_err) {
    out_err = "";
    out_utf8 = "";
    string ln_eco = "GOV_ECOLOGY_V1|" + IntegerToString(sum.ecology_window_id) + "|" + sum.replay_hash + "|" + sum.policy_fingerprint + "|" + IntegerToString(sum.entity_count) + "|" + IntegerToString(sum.ecological_stability_milli) + "|" + IntegerToString(sum.biodiversity_index_milli) + "|" + IntegerToString(sum.collapse_exposure_milli) + "|" + IntegerToString(sum.coexistence_quality_milli) + "|" + IntegerToString(sum.ecosystem_resilience_milli) + "|" + IntegerToString(sum.predation_pressure_milli);
    const int ns = GovClampInt32(n_sp, 0, 64);
    string ln_sp = "GOV_SPECIES_V1";
    for(int k = 0; k < ns; k++) {
        ln_sp += "|" + IntegerToString(sp[k].entity_id) + "=" + IntegerToString(sp[k].species_code);
    }
    const string ln_pp = "GOV_PREDPREY_V1|" + GovEcoExpV1_JoinInts5(pred.collapse_propagation_milli, pred.pressure_transfer_milli, pred.recovery_suppression_milli, pred.survivability_predation_milli, pred.parasitic_load_milli);
    const string ln_bd = "GOV_BIODIV_V1|" + GovEcoExpV1_JoinInts6(bio.diversity_score_milli, bio.regime_diversity_milli, bio.resilience_diversity_milli, bio.survivability_diversity_milli, bio.civilization_variation_milli, bio.ecosystem_concentration_risk_milli);
    const string ln_er = "GOV_ECO_RES_V1|" + GovEcoExpV1_JoinInts5(eres.ecosystem_resilience_milli, eres.ecosystem_recovery_speed_milli, eres.biodiversity_recovery_milli, eres.collapse_resistance_milli, eres.long_horizon_ecological_survivability_milli);
    const string ln_cl = "GOV_ECO_COLLAPSE_V1|" + GovEcoExpV1_JoinInts6(cl.cascading_collapse_milli, cl.synchronized_failure_milli, cl.ecosystem_instability_milli, cl.biodiversity_collapse_milli, cl.resilience_extinction_milli, cl.collapse_contagion_milli);
    const string ln_cx = "GOV_COEXIST_V1|" + GovEcoExpV1_JoinInts5(cx.coexistence_stability_milli, cx.recovery_harmony_milli, cx.regime_compatibility_milli, cx.intervention_interference_milli, cx.temporal_sync_stability_milli);
    const string ln_cmp = "GOV_ECO_CMP_V1|" + GovEcoExpV1_JoinInts6(cmp.d_ecological_stability_milli, cmp.d_biodiversity_index_milli, cmp.d_collapse_exposure_milli, cmp.d_coexistence_quality_milli, cmp.d_ecosystem_resilience_milli, cmp.d_predation_pressure_milli);
    out_utf8 = ln_eco + "\n" + ln_sp + "\n" + ln_pp + "\n" + ln_bd + "\n" + ln_er + "\n" + ln_cl + "\n" + ln_cx + "\n" + ln_cmp;
    return true;
}

#endif // __AURUM_GOV_ECO_EXP_V1_MQH__
