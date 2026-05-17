//+------------------------------------------------------------------+
//| GovernanceStrategicExportV1.mqh                              |
//| UTF-8/LF deterministic strategic bundles.                        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_STRATEGIC_EXPORT_V1_MQH__
#define __AURUM_GOV_STRATEGIC_EXPORT_V1_MQH__

#include "GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDatasetV1.mqh"

bool GovStrategicExpV1_Bundle(const SGovStrategicSummaryV1 &sum, const SGovStrategicEnduranceV1 &en, const SGovStrategicBudgetV1 &bud, const SGovStrategicContainmentV1 &ctn, const SGovStrategicTrajectoryV1 &tr,
                              const SGovCatastrophicResistanceV1 &cat, const SGovEvolutionGenerationV1 &gens[], const int n, int &rank_ord[], string &out, string &out_err) {
    out_err = "";
    out = "===GOV_STRATEGIC_V1===\n";
    out += "schema,GOV_STRATEGIC_V1\n";
    out += "SUM,sid," + IntegerToString(sum.strategic_window_id);
    out += ",rh," + sum.replay_hash;
    out += ",pf," + sum.policy_fingerprint;
    out += ",lid," + IntegerToString(sum.lineage_id);
    out += ",gh," + IntegerToString(sum.governance_health_0_1000);
    out += ",svh," + IntegerToString(sum.survivability_horizon_0_1000);
    out += ",end," + IntegerToString(sum.endurance_capacity_0_1000);
    out += ",bud," + IntegerToString(sum.intervention_budget_score_0_1000);
    out += ",ctn," + IntegerToString(sum.strategic_containment_quality_0_1000);
    out += ",sus," + IntegerToString(sum.sustainability_index_0_1000);
    out += ",cat," + IntegerToString(sum.catastrophic_resistance_0_1000);
    out += ",dst," + IntegerToString(sum.degradation_stability_0_1000);
    out += ",reb," + IntegerToString(sum.regime_endurance_balance_0_1000);
    out += ",cav," + IntegerToString(sum.collapse_avoidance_score_0_1000);
    out += ",rcs," + IntegerToString(sum.recovery_sustainability_0_1000);
    out += ",fts," + IntegerToString(sum.fatigue_sustainability_0_1000);
    out += ",n," + IntegerToString(sum.strategic_epoch_count);
    out += "\n";
    out += "END,ec," + IntegerToString(en.endurance_composite_0_1000);
    out += ",sp," + IntegerToString(en.survivability_persistence_0_1000);
    out += ",re," + IntegerToString(en.recovery_endurance_0_1000);
    out += ",cs," + IntegerToString(en.containment_sustainability_0_1000);
    out += ",fe," + IntegerToString(en.fatigue_endurance_0_1000);
    out += "\n";
    out += "BUD,bc," + IntegerToString(bud.budget_pressure_composite_0_1000);
    out += ",qe," + IntegerToString(bud.quarantine_expenditure_density_0_1000);
    out += ",fe," + IntegerToString(bud.flatten_expenditure_accum_0_1000);
    out += "\n";
    out += "TRAJ,ss," + IntegerToString(tr.sustainability_slope_milli);
    out += ",ds," + IntegerToString(tr.degradation_stabilization_0_1000);
    out += ",re," + IntegerToString(tr.regime_endurance_balance_0_1000);
    out += ",cr," + IntegerToString(tr.collapse_trajectory_risk_0_1000);
    out += "\n";
    out += "CAT,cs," + IntegerToString(cat.catastrophic_resistance_score_0_1000);
    out += ",ci," + IntegerToString(cat.collapse_interruption_capacity_0_1000);
    out += ",ss," + IntegerToString(cat.strategic_survival_capacity_0_1000);
    out += "\n";
    for(int i = 0; i < n; i++) {
        const int ix = rank_ord[i];
        out += "SRANK," + IntegerToString(i);
        out += ",gid," + IntegerToString(gens[ix].generation_id);
        out += ",ep," + IntegerToString(GovSaturatingAdd32(gens[ix].resilience_profile_0_1000, gens[ix].survivability_score_0_1000));
        out += "\n";
    }
    return true;
}

#endif // __AURUM_GOV_STRATEGIC_EXPORT_V1_MQH__
