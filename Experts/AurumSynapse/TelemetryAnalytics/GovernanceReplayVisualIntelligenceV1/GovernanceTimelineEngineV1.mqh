//+------------------------------------------------------------------+
//| GovernanceTimelineEngineV1.mqh                               |
//| Deterministic timeline frames (CSV-friendly, append-only safe). |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TIMELINE_ENGINE_V1_MQH__
#define __AURUM_GOV_TIMELINE_ENGINE_V1_MQH__

#include "GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTelemetryV1.mqh"

#define GOV_TL_V1_EXPECTED_PIPE_FIELDS 5

int GovernanceTimelineEngineV1_CountPipeFields(const string line) {
    if(StringLen(line) < 1)
        return 0;
    string parts[];
    return StringSplit(line, StringGetCharacter("|", 0), parts);
}

bool GovernanceTimelineEngineV1_AppendFrame(string &acc, const string kind, const ulong epoch, const int v1, const int v2) {
    string ln = "GOV_TL_V1";
    ln += "|" + kind;
    ln += "|" + GovernanceTelemetryV1_FormatU64Dec(epoch);
    ln += "|" + IntegerToString(v1);
    ln += "|" + IntegerToString(v2);
    if(GovernanceTimelineEngineV1_CountPipeFields(ln) != GOV_TL_V1_EXPECTED_PIPE_FIELDS)
        return false;
    if(StringLen(acc) > 0)
        acc += "\n";
    acc += ln;
    return true;
}

bool GovernanceTimelineEngineV1_BuildAll(const SGovReplayTimelineV1 &t, string &out_csv_block, string &out_err) {
    out_err = "";
    out_csv_block = "";
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        const ulong ep = t.epochs[i].epoch_id;
        const int gs = t.epochs[i].governance_state;
        const int rg = t.epochs[i].regime_state;
        const int qs = t.epochs[i].quarantine_state;
        const int sv = t.epochs[i].survivability_ms;
        const int tx = t.epochs[i].toxicity_ms;
        const int th = t.epochs[i].throttle_interval_ms;
        const int ex = t.epochs[i].execution_allowed;
        if(gs != GOV_REPLAY_V1_UNSET_INT) {
            if(!GovernanceTimelineEngineV1_AppendFrame(out_csv_block, "GS", ep, gs, 0))
                return false;
        }
        if(rg != GOV_REPLAY_V1_UNSET_INT) {
            if(!GovernanceTimelineEngineV1_AppendFrame(out_csv_block, "REG", ep, rg, 0))
                return false;
        }
        if(qs != GOV_REPLAY_V1_UNSET_INT) {
            if(!GovernanceTimelineEngineV1_AppendFrame(out_csv_block, "QUAR", ep, qs, 0))
                return false;
        }
        if(sv != GOV_REPLAY_V1_UNSET_INT) {
            if(!GovernanceTimelineEngineV1_AppendFrame(out_csv_block, "SURV", ep, sv, tx != GOV_REPLAY_V1_UNSET_INT ? tx : 0))
                return false;
        }
        if(th != GOV_REPLAY_V1_UNSET_INT) {
            if(!GovernanceTimelineEngineV1_AppendFrame(out_csv_block, "THR", ep, th, 0))
                return false;
        }
        if(ex != GOV_REPLAY_V1_UNSET_INT) {
            if(!GovernanceTimelineEngineV1_AppendFrame(out_csv_block, "EXEC", ep, ex, t.epochs[i].forced_flatten_required))
                return false;
        }
    }
    return true;
}

#endif // __AURUM_GOV_TIMELINE_ENGINE_V1_MQH__
