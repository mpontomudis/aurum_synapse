//+------------------------------------------------------------------+
//| GovernanceIncidentContainmentAnalyticsV1.mqh                    |
//| Integer-first deterministic metrics for a single incident window. |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INCIDENT_CONTAINMENT_ANALYTICS_V1_MQH__
#define __AURUM_GOV_INCIDENT_CONTAINMENT_ANALYTICS_V1_MQH__

#include "GovernanceIncidentDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceIncidentReconstructionV1.mqh"

struct SGovIncidentContainmentAnalyticsRowV1 {
    int containment_success_0_1000;
    int escalation_interruption_efficiency_0_1000;
    int survivability_preservation_delta_ms;
    int forced_flatten_effectiveness_0_1000;
    int quarantine_stabilization_efficiency_0_1000;
    int governance_response_latency_epochs;
    int recovery_stabilization_quality_0_1000;
};

void GovernanceIncidentContainmentAnalyticsV1_InitRow(SGovIncidentContainmentAnalyticsRowV1 &r) {
    r.containment_success_0_1000 = 0;
    r.escalation_interruption_efficiency_0_1000 = 0;
    r.survivability_preservation_delta_ms = 0;
    r.forced_flatten_effectiveness_0_1000 = 0;
    r.quarantine_stabilization_efficiency_0_1000 = 0;
    r.governance_response_latency_epochs = 0;
    r.recovery_stabilization_quality_0_1000 = 0;
}

bool GovernanceIncidentContainmentAnalyticsV1_Compute(const SGovReplayTimelineV1 &tl, const SGovIncidentEventV1 &ev,
                                                      SGovIncidentContainmentAnalyticsRowV1 &out, string &out_err) {
    out_err = "";
    GovernanceIncidentContainmentAnalyticsV1_InitRow(out);
    ulong emin = 0, emax = 0;
    GovernanceIncidentReconstructionV1_EventEpochBounds(ev, emin, emax);
    int first_i = -1;
    int last_i = -1;
    int win_n = 0;
    int exec_den = 0;
    int ff_hits = 0;
    int q_hard = 0;
    int rec_ok_tail = 0;
    int min_sv = GOV_REPLAY_V1_UNSET_INT;
    int max_sv = GOV_REPLAY_V1_UNSET_INT;
    const int n = ArraySize(tl.epochs);
    for(int i = 0; i < n; i++) {
        const ulong eid = tl.epochs[i].epoch_id;
        if(eid < emin || eid > emax)
            continue;
        if(first_i < 0)
            first_i = i;
        last_i = i;
        win_n = GovSaturatingAdd32(win_n, 1);
        const SGovReplayEpochV1 ep = tl.epochs[i];
        if(ep.execution_allowed == 0)
            exec_den = GovSaturatingAdd32(exec_den, 1);
        if(ep.forced_flatten_required == 1)
            ff_hits = GovSaturatingAdd32(ff_hits, 1);
        if(ep.quarantine_state >= 2)
            q_hard = GovSaturatingAdd32(q_hard, 1);
        if(ep.survivability_ms != GOV_REPLAY_V1_UNSET_INT) {
            if(min_sv == GOV_REPLAY_V1_UNSET_INT || ep.survivability_ms < min_sv)
                min_sv = ep.survivability_ms;
            if(max_sv == GOV_REPLAY_V1_UNSET_INT || ep.survivability_ms > max_sv)
                max_sv = ep.survivability_ms;
        }
    }
    if(first_i >= 0 && last_i >= first_i) {
        const SGovReplayEpochV1 tail = tl.epochs[last_i];
        if(tail.recovery_allowed == 1)
            rec_ok_tail = 1;
    }
    if(min_sv != GOV_REPLAY_V1_UNSET_INT && max_sv != GOV_REPLAY_V1_UNSET_INT)
        out.survivability_preservation_delta_ms = max_sv - min_sv;
    out.governance_response_latency_epochs = (first_i >= 0 && last_i >= first_i) ? GovClampInt32(last_i - first_i + 1, 0, 1000000) : 0;
    out.containment_success_0_1000 = GovClampInt32(ev.containment_effectiveness_score_0_1000, 0, 1000);
    out.escalation_interruption_efficiency_0_1000 = GovClampInt32(1000 - GovClampInt32(exec_den * 120, 0, 1000), 0, 1000);
    out.forced_flatten_effectiveness_0_1000 = (ff_hits > 0) ? GovClampInt32(600 + 100 * GovClampInt32(ff_hits, 0, 4), 0, 1000) : 200;
    out.quarantine_stabilization_efficiency_0_1000 = GovClampInt32(1000 - GovClampInt32(q_hard * 90, 0, 1000), 0, 1000);
    out.recovery_stabilization_quality_0_1000 = rec_ok_tail != 0 ? 820 : 310;
    if(win_n < 1)
        out_err = "GOV_INCIDENT_CONTAIN_EMPTY_WINDOW";
    return (win_n >= 1);
}

#endif // __AURUM_GOV_INCIDENT_CONTAINMENT_ANALYTICS_V1_MQH__
