//+------------------------------------------------------------------+
//| GovernancePolicyDriftObservationV1.mqh                        |
//| Observational deltas between two research summaries.             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POLICY_DRIFT_OBS_V1_MQH__
#define __AURUM_GOV_POLICY_DRIFT_OBS_V1_MQH__

#include "GovernanceResearchDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

bool GovPolDriftV1_Format(const SGovResearchSummaryV1 &a, const SGovResearchSummaryV1 &b, string &out, string &out_err) {
    out_err = "";
    out = "DRIFT_V1";
    out += "|D_HEALTH=" + IntegerToString(GovSaturatingAdd32(a.governance_health_index, -b.governance_health_index));
    out += "|D_INC=" + IntegerToString(GovSaturatingAdd32(a.incident_density_per_1000, -b.incident_density_per_1000));
    out += "|D_CTN=" + IntegerToString(GovSaturatingAdd32(a.containment_quality_0_1000, -b.containment_quality_0_1000));
    out += "|D_SURV=" + IntegerToString(GovSaturatingAdd32(a.survivability_preservation_0_1000, -b.survivability_preservation_0_1000));
    out += "|D_QUAR=" + IntegerToString(GovSaturatingAdd32(a.quarantine_pressure_0_1000, -b.quarantine_pressure_0_1000));
    out += "|D_THR=" + IntegerToString(GovSaturatingAdd32(a.throttle_pressure_0_1000, -b.throttle_pressure_0_1000));
    out += "\n";
    return true;
}

#endif // __AURUM_GOV_POLICY_DRIFT_OBS_V1_MQH__
