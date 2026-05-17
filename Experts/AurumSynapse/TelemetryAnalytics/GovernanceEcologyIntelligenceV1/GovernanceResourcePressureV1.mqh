//+------------------------------------------------------------------+
//| GovernanceResourcePressureV1.mqh                                |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — resource pressure            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_RESPRESS_V1_MQH__
#define __AURUM_GOV_ECO_RESPRESS_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceStrategicIntelligenceV1/GovernanceStrategicDatasetV1.mqh"

bool GovResPressureV1_Compute(const SGovReplayTimelineV1 &tl, const SGovResilienceProfileV1 &rp, const SGovStrategicSummaryV1 &strat, SGovEcologyPressureV1 &out, string &out_err) {
    out_err = "";
    GovEcoDsV1_InitPress(out);
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    int q_epochs = 0;
    int exec_den = 0;
    int rec_blk = 0;
    for(int k = 0; k < n; k++) {
        if(tl.epochs[k].quarantine_state > 0)
            q_epochs++;
        if(tl.epochs[k].execution_allowed == 0)
            exec_den++;
        if(tl.epochs[k].recovery_allowed == 0)
            rec_blk++;
    }
    const int qdens = (n > 0) ? GovClampInt32((q_epochs * 1000) / n, 0, 1000) : 0;
    const int edens = (n > 0) ? GovClampInt32((exec_den * 1000) / n, 0, 1000) : 0;
    out.quarantine_pressure_milli = GovClampInt32(GovSaturatingAdd32(qdens * 1000, rp.summary.quarantine_saturation_0_1000 * 800), 0, 1000000000);
    out.execution_suppression_load_milli = GovClampInt32(GovSaturatingAdd32(edens * 1000, rp.fatigue.execution_suppression_fatigue_per_1000 * 1000), 0, 1000000000);
    out.intervention_exhaustion_milli = GovClampInt32(GovSaturatingAdd32(rp.summary.intervention_density_0_1000 * 1000, strat.intervention_budget_score_0_1000 * 900), 0, 1000000000);
    const int rsc = (n > 0) ? GovClampInt32((rec_blk * 1000) / n, 0, 1000) : 0;
    out.recovery_resource_scarcity_milli = GovClampInt32(GovSaturatingAdd32(rsc * 1200, (1000 - rp.summary.recovery_elasticity_0_1000) * 800), 0, 1000000000);
    out.survivability_resource_strain_milli = GovClampInt32(GovSaturatingAdd32((1000 - rp.summary.survivability_resilience_0_1000) * 1000, strat.fatigue_sustainability_0_1000 * 700), 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_ECO_RESPRESS_V1_MQH__
