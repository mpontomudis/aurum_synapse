//+------------------------------------------------------------------+
//| GovernanceCausalReplayInspectorV1.mqh                         |
//| Deterministic causal explanations (integer attribution only).  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CAUSAL_REPLAY_INSPECTOR_V1_MQH__
#define __AURUM_GOV_CAUSAL_REPLAY_INSPECTOR_V1_MQH__

#include "GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTelemetryV1.mqh"

#define GOV_CAUS_V1_FIELDS 9

int GovernanceCausalReplayInspectorV1_DominantFactorCode(const SGovReplayEpochV1 &e) {
    int dom = 0;
    int best = -1;
    int stress_surv = GOV_REPLAY_V1_UNSET_INT;
    if(e.survivability_ms != GOV_REPLAY_V1_UNSET_INT)
        stress_surv = GovClampInt32(100000 - GovClampInt32(e.survivability_ms, 0, 100000), 0, 1000000);
    const int cands[4] = {e.structural_instability_ms, e.toxicity_ms, e.causal_pressure_ms, stress_surv};
    for(int i = 0; i < 4; i++) {
        if(cands[i] == GOV_REPLAY_V1_UNSET_INT)
            continue;
        if(cands[i] > best) {
            best = cands[i];
            dom = i + 1;
        }
    }
    return dom;
}

bool GovernanceCausalReplayInspectorV1_FormatTransition(const ulong epoch,
                                                       const int gs_old,
                                                       const int gs_new,
                                                       const SGovReplayEpochV1 &e,
                                                       string &out_line) {
    out_line = "GOV_CAUS_V1";
    out_line += "|" + GovernanceTelemetryV1_FormatU64Dec(epoch);
    out_line += "|" + IntegerToString(gs_old);
    out_line += "|" + IntegerToString(gs_new);
    out_line += "|" + IntegerToString(GovernanceCausalReplayInspectorV1_DominantFactorCode(e));
    out_line += "|" + IntegerToString(e.toxicity_ms);
    out_line += "|" + IntegerToString(e.survivability_ms);
    out_line += "|" + IntegerToString(e.quarantine_state);
    out_line += "|" + IntegerToString(e.causal_reason_code);
    string parts[];
    return (StringSplit(out_line, StringGetCharacter("|", 0), parts) == GOV_CAUS_V1_FIELDS);
}

bool GovernanceCausalReplayInspectorV1_BuildTransitions(const SGovReplayTimelineV1 &t, string &out_block, string &out_err) {
    out_err = "";
    out_block = "";
    const int n = ArraySize(t.epochs);
    int prev_gs = GOV_REPLAY_V1_UNSET_INT;
    for(int i = 0; i < n; i++) {
        const int gs = t.epochs[i].governance_state;
        if(gs == GOV_REPLAY_V1_UNSET_INT)
            continue;
        if(prev_gs != GOV_REPLAY_V1_UNSET_INT && gs != prev_gs) {
            string ln = "";
            if(!GovernanceCausalReplayInspectorV1_FormatTransition(t.epochs[i].epoch_id, prev_gs, gs, t.epochs[i], ln))
                return false;
            if(StringLen(out_block) > 0)
                out_block += "\n";
            out_block += ln;
        }
        prev_gs = gs;
    }
    return true;
}

#endif // __AURUM_GOV_CAUSAL_REPLAY_INSPECTOR_V1_MQH__
