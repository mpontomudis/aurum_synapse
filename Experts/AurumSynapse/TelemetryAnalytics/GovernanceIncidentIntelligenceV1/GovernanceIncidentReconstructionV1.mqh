//+------------------------------------------------------------------+
//| GovernanceIncidentReconstructionV1.mqh                          |
//| Deterministic incident chain reconstruction (replay indices).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INCIDENT_RECONSTRUCTION_V1_MQH__
#define __AURUM_GOV_INCIDENT_RECONSTRUCTION_V1_MQH__

#include "GovernanceIncidentDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTelemetryV1.mqh"

void GovIncidentReconstructionV1_SortU64Asc(ulong &ids[]) {
    const int n = ArraySize(ids);
    for(int a = 0; a < n; a++) {
        for(int b = a + 1; b < n; b++) {
            if(ids[b] < ids[a]) {
                const ulong t = ids[a];
                ids[a] = ids[b];
                ids[b] = t;
            }
        }
    }
}

void GovernanceIncidentReconstructionV1_EventEpochBounds(const SGovIncidentEventV1 &ev, ulong &out_min, ulong &out_max) {
    ulong a = ev.start_epoch;
    ulong b = ev.peak_epoch;
    ulong c = ev.recovery_epoch;
    out_min = a;
    out_max = a;
    if(b < out_min)
        out_min = b;
    if(b > out_max)
        out_max = b;
    if(c < out_min)
        out_min = c;
    if(c > out_max)
        out_max = c;
}

void GovernanceIncidentReconstructionV1_InitChain(SGovIncidentChainV1 &ch) {
    ch.incident_id = GOV_INCIDENT_V1_UNSET;
    ch.incident_type = (int)GOV_INCIDENT_V1_NONE;
    ArrayResize(ch.epoch_ids, 0);
    ch.ladder_notes = "";
}

bool GovernanceIncidentReconstructionV1_RebuildChain(const SGovReplayTimelineV1 &tl, const SGovIncidentEventV1 &ev,
                                                       SGovIncidentChainV1 &out, string &out_err) {
    out_err = "";
    GovernanceIncidentReconstructionV1_InitChain(out);
    out.incident_id = ev.incident_id;
    out.incident_type = ev.incident_type;
    ulong emin = 0, emax = 0;
    GovernanceIncidentReconstructionV1_EventEpochBounds(ev, emin, emax);
    ulong acc[];
    ArrayResize(acc, 0);
    const int n = ArraySize(tl.epochs);
    for(int i = 0; i < n; i++) {
        const ulong eid = tl.epochs[i].epoch_id;
        if(eid >= emin && eid <= emax) {
            const int m = ArraySize(acc);
            ArrayResize(acc, m + 1);
            acc[m] = eid;
        }
    }
    GovIncidentReconstructionV1_SortU64Asc(acc);
    ArrayResize(out.epoch_ids, ArraySize(acc));
    for(int k = 0; k < ArraySize(acc); k++)
        out.epoch_ids[k] = acc[k];
    out.ladder_notes = "";
    for(int k = 0; k < ArraySize(out.epoch_ids); k++) {
        const ulong eid = out.epoch_ids[k];
        const int ix = GovernanceReplayDatasetV1_FindEpochIndex(tl, eid);
        if(ix < 0)
            continue;
        const SGovReplayEpochV1 ep = tl.epochs[ix];
        if(StringLen(out.ladder_notes) > 0)
            out.ladder_notes += "\n";
        out.ladder_notes += "EPOCH=" + GovernanceTelemetryV1_FormatU64Dec(eid);
        out.ladder_notes += "|GS=" + IntegerToString(ep.governance_state);
        out.ladder_notes += "|RG=" + IntegerToString(ep.regime_state);
        out.ladder_notes += "|QX=" + IntegerToString(ep.quarantine_state);
        out.ladder_notes += "|EX=" + IntegerToString(ep.execution_allowed);
        out.ladder_notes += "|FF=" + IntegerToString(ep.forced_flatten_required);
        out.ladder_notes += "|TX=" + IntegerToString(ep.toxicity_ms);
        out.ladder_notes += "|SV=" + IntegerToString(ep.survivability_ms);
    }
    return true;
}

#endif // __AURUM_GOV_INCIDENT_RECONSTRUCTION_V1_MQH__
