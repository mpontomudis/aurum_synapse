//+------------------------------------------------------------------+
//| GovernanceSustainabilityTrajectoryV1.mqh                     |
//| Sustainability slopes & stabilization (integer).               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SUST_TRAJ_V1_MQH__
#define __AURUM_GOV_SUST_TRAJ_V1_MQH__

#include "GovernanceStrategicDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceEvolutionIntelligenceV1/GovernanceEvolutionDatasetV1.mqh"

bool GovStratTrajV1_Compute(const SGovResilienceProfileV1 &rp, const SGovEvolutionDriftV1 &dr, const SGovEvolutionSurvivabilityV1 &sv, SGovStrategicTrajectoryV1 &out, string &out_err) {
    out_err = "";
    GovStratDsV1_InitTraj(out);
    out.sustainability_slope_milli = GovClampInt32(dr.drift_survivability_milli + dr.drift_recovery_milli / 2, -10000000, 10000000);
    out.degradation_stabilization_0_1000 = GovClampInt32(1000 - GovClampInt32(rp.summary.degradation_velocity_milli / 20, 0, 1000), 0, 1000);
    out.survivability_persistence_traj_0_1000 = GovClampInt32(sv.inheritance_quality_0_1000 + rp.summary.survivability_resilience_0_1000 / 3, 0, 1000);
    out.fatigue_stabilization_0_1000 = GovClampInt32(1000 - rp.fatigue.fatigue_composite_0_1000 - rp.brittleness.oscillation_index_0_1000 / 5, 0, 1000);
    out.recovery_sustainability_traj_0_1000 = GovClampInt32(sv.inheritance_quality_0_1000 / 2 + GovClampInt32(sv.recovery_elasticity_evolution_milli / 50, 0, 500), 0, 1000);
    out.regime_endurance_balance_0_1000 = GovClampInt32(1000 - rp.brittleness.brittleness_score_0_1000 / 2 + rp.brittleness.stabilization_persistence_0_1000 / 4, 0, 1000);
    out.collapse_trajectory_risk_0_1000 = GovClampInt32(rp.curve.collapse_acceleration_score_0_1000 + (1000 - rp.summary.collapse_resistance_0_1000) / 3, 0, 1000);
    return true;
}

#endif // __AURUM_GOV_SUST_TRAJ_V1_MQH__
