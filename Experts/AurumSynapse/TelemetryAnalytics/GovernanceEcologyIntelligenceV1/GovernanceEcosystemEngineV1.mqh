//+------------------------------------------------------------------+
//| GovernanceEcosystemEngineV1.mqh                                 |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — ecosystem entity build      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_SYS_V1_MQH__
#define __AURUM_GOV_ECO_SYS_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceCivilizationIntelligenceV1/GovernanceCivilizationDatasetV1.mqh"
#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalDatasetV1.mqh"

#define GOV_ECO_LAYER_REPLAY       1
#define GOV_ECO_LAYER_RESILIENCE   2
#define GOV_ECO_LAYER_EVOLUTION    3
#define GOV_ECO_LAYER_STRATEGIC    4
#define GOV_ECO_LAYER_CIVILIZATION 5
#define GOV_ECO_LAYER_TEMPORAL     6

int GovEcoSysV1_ReplayPressureMilli(const SGovReplayTimelineV1 &tl) {
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    if(n <= 0)
        return 0;
    int acc = 0;
    for(int k = 0; k < n; k++) {
        const int q = GovClampInt32(tl.epochs[k].quarantine_state, 0, 1000);
        const int tox = GovClampInt32(tl.epochs[k].toxicity_ms, 0, 100000);
        const int cp = GovClampInt32(tl.epochs[k].causal_pressure_ms, 0, 100000);
        const int row = GovSaturatingAdd32(q * 800, GovSaturatingAdd32(tox * 6, cp * 4));
        acc = GovSaturatingAdd32(acc, row);
    }
    return GovClampInt32(acc / n, 0, 1000000000);
}

int GovEcoSysV1_ReplaySurvivabilityMilli(const SGovReplayTimelineV1 &tl) {
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    if(n <= 0)
        return 0;
    int acc = 0;
    for(int k = 0; k < n; k++) {
        const int s = GovClampInt32(tl.epochs[k].survivability_ms, 0, 100000);
        const int rec = GovClampInt32(tl.epochs[k].recovery_allowed, 0, 1);
        acc = GovSaturatingAdd32(acc, GovSaturatingAdd32(s * 10, rec * 50000));
    }
    return GovClampInt32(acc / n, 0, 1000000000);
}

int GovEcoSysV1_ReplayCollapseExposureMilli(const SGovReplayTimelineV1 &tl) {
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    if(n <= 0)
        return 0;
    int acc = 0;
    for(int k = 0; k < n; k++) {
        const int inst = GovClampInt32(tl.epochs[k].structural_instability_ms, 0, 100000);
        const int rm = GovClampInt32(tl.epochs[k].risk_multiplier_milli, 0, 10000000);
        const int surv = GovClampInt32(tl.epochs[k].survivability_ms, 0, 100000);
        const int miss = GovClampInt32(50000 - surv * 10, 0, 1000000);
        acc = GovSaturatingAdd32(acc, GovSaturatingAdd32(inst * 8 + rm / 100, miss));
    }
    return GovClampInt32(acc / n, 0, 1000000000);
}

int GovEcoSysV1_ReplayRecoveryCoexistMilli(const SGovReplayTimelineV1 &tl) {
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    if(n <= 0)
        return 0;
    int acc = 0;
    for(int k = 0; k < n; k++) {
        const int rec = GovClampInt32(tl.epochs[k].recovery_allowed, 0, 1);
        const int ex = GovClampInt32(tl.epochs[k].execution_allowed, 0, 1);
        const int en = GovClampInt32(tl.epochs[k].entry_allowed, 0, 1);
        acc = GovSaturatingAdd32(acc, rec * 300000 + ex * 200000 + en * 150000);
    }
    return GovClampInt32(acc / n, 0, 1000000000);
}

bool GovEcoSysV1_Build(const SGovReplayTimelineV1 &tl, const SGovResilienceProfileV1 &rp, const SGovEvolutionSummaryV1 &evo, const SGovStrategicSummaryV1 &strat, const SGovCivilizationSummaryV1 &civ, const SGovTemporalSummaryV1 &tmp, SGovEcologyEntityV1 &ents[], int &out_n, string &out_err) {
    out_err = "";
    ArrayResize(ents, 6);
    out_n = 6;
    const string rh = rp.summary.replay_hash;

    GovEcoDsV1_InitEntity(ents[0]);
    ents[0].ecosystem_id = 1;
    ents[0].entity_layer_code = GOV_ECO_LAYER_REPLAY;
    ents[0].replay_hash = tl.source_concat_sha256_hex;
    ents[0].pressure_milli = GovEcoSysV1_ReplayPressureMilli(tl);
    ents[0].survivability_milli = GovEcoSysV1_ReplaySurvivabilityMilli(tl);
    ents[0].collapse_exposure_milli = GovEcoSysV1_ReplayCollapseExposureMilli(tl);
    ents[0].adaptation_pressure_milli = GovClampInt32(GovSaturatingAdd32(ents[0].pressure_milli / 2, ents[0].collapse_exposure_milli / 3), 0, 1000000000);
    ents[0].recovery_coexistence_milli = GovEcoSysV1_ReplayRecoveryCoexistMilli(tl);
    ents[0].species_code = 0;

    GovEcoDsV1_InitEntity(ents[1]);
    ents[1].ecosystem_id = 2;
    ents[1].entity_layer_code = GOV_ECO_LAYER_RESILIENCE;
    ents[1].replay_hash = rh;
    ents[1].pressure_milli = GovClampInt32(GovSaturatingAdd32(rp.summary.quarantine_saturation_0_1000 * 1000, rp.fatigue.quarantine_reuse_pressure_0_1000 * 500), 0, 1000000000);
    ents[1].survivability_milli = GovClampInt32(rp.summary.survivability_resilience_0_1000 * 1000, 0, 1000000000);
    ents[1].collapse_exposure_milli = GovClampInt32(GovSaturatingAdd32(rp.curve.collapse_acceleration_score_0_1000 * 1000, (1000 - rp.summary.collapse_resistance_0_1000) * 800), 0, 1000000000);
    ents[1].adaptation_pressure_milli = GovClampInt32(GovSaturatingAdd32(rp.summary.degradation_velocity_milli, rp.brittleness.brittleness_score_0_1000 * 800), 0, 1000000000);
    ents[1].recovery_coexistence_milli = GovClampInt32(GovSaturatingAdd32(rp.summary.recovery_elasticity_0_1000 * 1000, rp.curve.recovery_curve_quality_0_1000 * 500), 0, 1000000000);
    ents[1].species_code = 0;

    GovEcoDsV1_InitEntity(ents[2]);
    ents[2].ecosystem_id = 3;
    ents[2].entity_layer_code = GOV_ECO_LAYER_EVOLUTION;
    ents[2].replay_hash = evo.replay_hash;
    ents[2].pressure_milli = GovClampInt32(GovSaturatingAdd32(evo.mean_degeneration_score_0_1000 * 1200, evo.max_degeneration_velocity_milli), 0, 1000000000);
    ents[2].survivability_milli = GovClampInt32(evo.mean_survivability_0_1000 * 1000, 0, 1000000000);
    ents[2].collapse_exposure_milli = GovClampInt32(GovSaturatingAdd32(evo.max_degeneration_velocity_milli * 2, (1000 - evo.mean_survivability_0_1000) * 900), 0, 1000000000);
    ents[2].adaptation_pressure_milli = GovClampInt32(evo.topology_branching_factor_0_1000 * 1100 + evo.generation_span * 5000, 0, 1000000000);
    ents[2].recovery_coexistence_milli = GovClampInt32(GovSaturatingAdd32(1000000 - ents[2].collapse_exposure_milli / 2, evo.mean_survivability_0_1000 * 400), 0, 1000000000);
    ents[2].species_code = 0;

    GovEcoDsV1_InitEntity(ents[3]);
    ents[3].ecosystem_id = 4;
    ents[3].entity_layer_code = GOV_ECO_LAYER_STRATEGIC;
    ents[3].replay_hash = strat.replay_hash;
    ents[3].pressure_milli = GovClampInt32(GovSaturatingAdd32(strat.intervention_budget_score_0_1000 * 1000, (1000 - strat.sustainability_index_0_1000) * 700), 0, 1000000000);
    ents[3].survivability_milli = GovClampInt32(strat.survivability_horizon_0_1000 * 1000, 0, 1000000000);
    ents[3].collapse_exposure_milli = GovClampInt32(GovSaturatingAdd32((1000 - strat.collapse_avoidance_score_0_1000) * 1100, strat.degradation_stability_0_1000 * 600), 0, 1000000000);
    ents[3].adaptation_pressure_milli = GovClampInt32(GovSaturatingAdd32(strat.fatigue_sustainability_0_1000 * 800, strat.endurance_capacity_0_1000 * 400), 0, 1000000000);
    ents[3].recovery_coexistence_milli = GovClampInt32(GovSaturatingAdd32(strat.recovery_sustainability_0_1000 * 1000, strat.catastrophic_resistance_0_1000 * 500), 0, 1000000000);
    ents[3].species_code = 0;

    GovEcoDsV1_InitEntity(ents[4]);
    ents[4].ecosystem_id = 5;
    ents[4].entity_layer_code = GOV_ECO_LAYER_CIVILIZATION;
    ents[4].replay_hash = civ.replay_hash;
    ents[4].pressure_milli = GovClampInt32(GovSaturatingAdd32(civ.systemic_collapse_risk_milli, (1000 - GovClampInt32(civ.hierarchy_stability_milli / 1000, 0, 1000)) * 800000), 0, 1000000000);
    ents[4].survivability_milli = GovClampInt32(GovSaturatingAdd32(civ.continuity_milli, civ.civilization_stability_milli), 0, 1000000000);
    ents[4].collapse_exposure_milli = GovClampInt32(GovSaturatingAdd32(civ.systemic_collapse_risk_milli, (1000 - GovClampInt32(civ.memory_stable_cycles, 0, 1000)) * 10000), 0, 1000000000);
    ents[4].adaptation_pressure_milli = GovClampInt32(GovSaturatingAdd32((1000 - GovClampInt32(civ.diplomacy_alignment_milli / 1000, 0, 1000)) * 600000, (1000 - GovClampInt32(civ.topology_stability_milli / 1000, 0, 1000)) * 500000), 0, 1000000000);
    ents[4].recovery_coexistence_milli = GovClampInt32(GovSaturatingAdd32(civ.continuity_milli, civ.regime_balance_milli), 0, 1000000000);
    ents[4].species_code = 0;

    GovEcoDsV1_InitEntity(ents[5]);
    ents[5].ecosystem_id = 6;
    ents[5].entity_layer_code = GOV_ECO_LAYER_TEMPORAL;
    ents[5].replay_hash = tmp.replay_hash;
    ents[5].pressure_milli = GovClampInt32(GovSaturatingAdd32(tmp.cumulative_temporal_pressure_milli, tmp.era_transition_pressure_milli), 0, 1000000000);
    ents[5].survivability_milli = GovClampInt32(GovSaturatingAdd32(tmp.long_cycle_survivability_milli, tmp.continuity_strength_milli / 2), 0, 1000000000);
    ents[5].collapse_exposure_milli = GovClampInt32(GovSaturatingAdd32(tmp.decay_composite_milli, (1000 - GovClampInt32(tmp.temporal_stability_milli / 1000, 0, 1000)) * 900000), 0, 1000000000);
    ents[5].adaptation_pressure_milli = GovClampInt32(GovSaturatingAdd32(tmp.aging_entropy_milli * 10, tmp.era_transition_pressure_milli / 2), 0, 1000000000);
    ents[5].recovery_coexistence_milli = GovClampInt32(GovSaturatingAdd32(tmp.continuity_strength_milli, tmp.temporal_stability_milli / 2), 0, 1000000000);
    ents[5].species_code = 0;

    return true;
}

#endif // __AURUM_GOV_ECO_SYS_V1_MQH__
