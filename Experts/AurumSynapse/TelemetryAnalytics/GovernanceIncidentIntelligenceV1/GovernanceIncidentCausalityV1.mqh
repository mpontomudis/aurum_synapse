//+------------------------------------------------------------------+
//| GovernanceIncidentCausalityV1.mqh                               |
//| Deterministic causal line formatting (no inference).              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INCIDENT_CAUSALITY_V1_MQH__
#define __AURUM_GOV_INCIDENT_CAUSALITY_V1_MQH__

#include "GovernanceIncidentDatasetV1.mqh"
#include "GovernanceIncidentReconstructionV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"

string GovIncidentCausalityV1_GsAbbrev(const int gs) {
    if(gs == (int)GOV_STATE_NORMAL)
        return "NORMAL";
    if(gs == (int)GOV_STATE_RECOVERY)
        return "RECOVERY";
    if(gs == (int)GOV_STATE_CAUTION)
        return "CAUTION";
    if(gs == (int)GOV_STATE_DEFENSIVE)
        return "DEFENSIVE";
    if(gs == (int)GOV_STATE_SURVIVAL)
        return "SURVIVAL";
    if(gs == (int)GOV_STATE_LOCKDOWN)
        return "LOCKDOWN";
    return "GS" + IntegerToString(gs);
}

string GovIncidentCausalityV1_IncidentCode(const int incident_type) {
    if(incident_type == (int)GOV_INCIDENT_V1_TOX_SPIRAL)
        return "TOX_SPIRAL_V1";
    if(incident_type == (int)GOV_INCIDENT_V1_SURV_COLLAPSE)
        return "SURV_COLLAPSE_V1";
    if(incident_type == (int)GOV_INCIDENT_V1_FALSE_RECOVERY)
        return "FALSE_RECOVERY_V1";
    if(incident_type == (int)GOV_INCIDENT_V1_QUAR_ESCALATION)
        return "QUAR_ESCALATION_V1";
    if(incident_type == (int)GOV_INCIDENT_V1_EXEC_SUPPRESSION)
        return "EXEC_SUPPRESSION_V1";
    if(incident_type == (int)GOV_INCIDENT_V1_REGIME_BREAKDOWN)
        return "REGIME_BREAKDOWN_V1";
    return "INCIDENT_NONE";
}

string GovIncidentCausalityV1_CauseCode(const SGovIncidentEventV1 &ev) {
    if(ev.incident_type == (int)GOV_INCIDENT_V1_REGIME_BREAKDOWN)
        return "STRUCTURAL_INSTABILITY";
    if(ev.incident_type == (int)GOV_INCIDENT_V1_TOX_SPIRAL)
        return "TOXICITY_ESCALATION";
    if(ev.incident_type == (int)GOV_INCIDENT_V1_SURV_COLLAPSE)
        return "SURVIVABILITY_STRESS";
    if(ev.incident_type == (int)GOV_INCIDENT_V1_FALSE_RECOVERY)
        return "CONTAINMENT_LAPSE";
    if(ev.incident_type == (int)GOV_INCIDENT_V1_QUAR_ESCALATION)
        return "QUARANTINE_PRESSURE";
    if(ev.incident_type == (int)GOV_INCIDENT_V1_EXEC_SUPPRESSION)
        return "EXECUTION_LOCK";
    return "UNKNOWN";
}

string GovIncidentCausalityV1_QuarTag(const int qp) {
    if(qp >= 2)
        return "HARD";
    if(qp == 1)
        return "SOFT";
    return "NONE";
}

bool GovernanceIncidentCausalityV1_BuildGovPath(const SGovReplayTimelineV1 &tl, const SGovIncidentEventV1 &ev, string &out_path) {
    ulong emin = 0, emax = 0;
    GovernanceIncidentReconstructionV1_EventEpochBounds(ev, emin, emax);
    out_path = "";
    const int n = ArraySize(tl.epochs);
    ulong acc[];
    ArrayResize(acc, 0);
    for(int i = 0; i < n; i++) {
        const ulong eid = tl.epochs[i].epoch_id;
        if(eid < emin || eid > emax)
            continue;
        const int m = ArraySize(acc);
        ArrayResize(acc, m + 1);
        acc[m] = eid;
    }
    GovIncidentReconstructionV1_SortU64Asc(acc);
    for(int k = 0; k < ArraySize(acc); k++) {
        const int ix = GovernanceReplayDatasetV1_FindEpochIndex(tl, acc[k]);
        if(ix < 0)
            continue;
        if(StringLen(out_path) > 0)
            out_path += "->";
        out_path += GovIncidentCausalityV1_GsAbbrev(tl.epochs[ix].governance_state);
    }
    if(StringLen(out_path) < 1)
        out_path = GovIncidentCausalityV1_GsAbbrev(ev.dominant_governance_state);
    return true;
}

bool GovernanceIncidentCausalityV1_FormatReport(const SGovReplayTimelineV1 &tl, const SGovIncidentEventV1 &ev, string &out_line) {
    string path = "";
    GovernanceIncidentCausalityV1_BuildGovPath(tl, ev, path);
    const string inc = GovIncidentCausalityV1_IncidentCode(ev.incident_type);
    const string cause = GovIncidentCausalityV1_CauseCode(ev);
    const string quar = GovIncidentCausalityV1_QuarTag(ev.quarantine_peak);
    int surv = ev.survivability_floor_ms;
    if(surv == GOV_REPLAY_V1_UNSET_INT)
        surv = 0;
    out_line = "INCIDENT=" + inc;
    out_line += "|CAUSE=" + cause;
    out_line += "|GOV_PATH=" + path;
    out_line += "|QUARANTINE=" + quar;
    out_line += "|SURV_MIN=" + IntegerToString(surv);
    out_line += "|DOM_EVID=" + IntegerToString(ev.dominant_causal_factor);
    out_line += "|REPLAY_HASH=" + ev.replay_hash;
    return true;
}

#endif // __AURUM_GOV_INCIDENT_CAUSALITY_V1_MQH__
