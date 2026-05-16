//+------------------------------------------------------------------+
//|                                      PositionRollupV1.mqh        |
//|     POSITION_ROLLUP_V1 — formal lifecycle / exposure abstraction |
//|     Deterministic; position_id–first; append-only campaign view. |
//|     Does NOT modify AS_JOINED_V1 serialization or golden files. |
//+------------------------------------------------------------------+
#ifndef __AURUM_POSITION_ROLLUP_V1_MQH__
#define __AURUM_POSITION_ROLLUP_V1_MQH__

#include "JoinValidationPrototype.mqh"

//--- Formal lifecycle states (campaign-level semantics; not MT5 ENUM_DEAL_ENTRY mirror).
enum ENUM_LIFECYCLE_STATE_V1 {
    LIFECYCLE_V1_INVALID = 0,
    LIFECYCLE_V1_ACTIVE_NONZERO,
    LIFECYCLE_V1_TERMINATED_FLAT
};

enum ENUM_EXPOSURE_STATE_V1 {
    EXPOSURE_V1_UNKNOWN = 0,
    EXPOSURE_V1_NONZERO,
    EXPOSURE_V1_ZERO
};

//+------------------------------------------------------------------+
//| One deal row in canonical lifecycle order (after sort).          |
//+------------------------------------------------------------------+
struct SRollupDealStepV1 {
    int     lifecycle_seq;
    ulong   d_ticket;
    ulong   d_position_id;
    long    d_time_utc;
    double  d_volume;
    int     d_entry;
    int     d_type;
    double  cumulative_volume_closed;
    double  exposure_remaining;
    ENUM_EXPOSURE_STATE_V1 exposure_state_after;
};

//+------------------------------------------------------------------+
//| Linear chain edge (normalized partial-close graph = single path).|
//+------------------------------------------------------------------+
struct SRollupGraphEdgeV1 {
    int from_seq;
    int to_seq;
};

//+------------------------------------------------------------------+
//| Immutable campaign summary after full scan (one d_position_id).  |
//+------------------------------------------------------------------+
struct SRollupPositionCampaignV1 {
    ulong                   lifecycle_group_id;
    ulong                   root_position_id;
    int                     deal_count;
    long                    lifecycle_open_time_utc;
    long                    lifecycle_close_time_utc;
    double                  total_abs_volume;
    ENUM_LIFECYCLE_STATE_V1 lifecycle_state;
    ENUM_EXPOSURE_STATE_V1  terminal_exposure_state;
    bool                    valid;
};

//+------------------------------------------------------------------+
//| Append-only replay buffer (immutable snapshots; push only).      |
//+------------------------------------------------------------------+
struct SRollupReplayBufferV1 {
    SRollupDealStepV1 steps[];
    int               count;
};

void PositionRollupV1_ReplayReset(SRollupReplayBufferV1 &buf) {
    ArrayResize(buf.steps, 0);
    buf.count = 0;
}

bool PositionRollupV1_ReplayPush(SRollupReplayBufferV1 &buf, const SRollupDealStepV1 &step) {
    const int n = buf.count;
    buf.count++;
    ArrayResize(buf.steps, buf.count);
    buf.steps[n] = step;
    return true;
}

//+------------------------------------------------------------------+
//| Sum abs(d_volume) for ordered deal lines (deterministic).        |
//+------------------------------------------------------------------+
bool PositionRollupV1_TotalAbsVolumeFromSortedDealLines(const string &sortedDealLines[], double &outTotal) {
    outTotal = 0.0;
    const int n = ArraySize(sortedDealLines);
    if(n < 1)
        return false;
    for(int i = 0; i < n; i++) {
        ulong t = 0;
        ulong pos = 0;
        string sym = "";
        long mag = 0, utc = 0;
        double vol = 0, pr = 0, price = 0, cm = 0, sw = 0;
        int typ = 0, ent = 0, reas = 0;
        if(!JoinValidation_ParseDealDataRowColumns(sortedDealLines[i], t, sym, mag, utc, vol, pr, typ, ent, pos, price, cm, sw, reas))
            return false;
        outTotal += MathAbs(vol);
    }
    return true;
}

//+------------------------------------------------------------------+
//| Build linear graph: seq i → i+1 (n−1 edges, no branches).        |
//+------------------------------------------------------------------+
bool PositionRollupV1_BuildLinearChainEdges(const int dealCount, SRollupGraphEdgeV1 &outEdges[]) {
    ArrayResize(outEdges, 0);
    if(dealCount < 2)
        return true;
    ArrayResize(outEdges, dealCount - 1);
    for(int e = 0; e < dealCount - 1; e++) {
        outEdges[e].from_seq = e;
        outEdges[e].to_seq = e + 1;
    }
    return true;
}

//+------------------------------------------------------------------+
//| Core: UTF-8 deals body → sorted same-position campaign rollup. |
//| Preconditions: ≥1 data row; all rows share d_position_id.        |
//| Exposure model: staged reduction toward flat —                 |
//|   exposure_remaining[k] = total_abs_volume − sum(|vol|[0..k]).   |
//|   (Survivability-ready monotone path; not MT5 net PnL.)          |
//+------------------------------------------------------------------+
bool PositionRollupV1_BuildFromDealsUtf8Lf(const string dealsUtf8Lf,
                                        SRollupDealStepV1 &outSteps[],
                                        SRollupPositionCampaignV1 &outCampaign,
                                        SRollupGraphEdgeV1 &outEdges[],
                                        string &outError) {
    outError = "";
    ArrayResize(outSteps, 0);
    outCampaign.valid = false;
    ArrayResize(outEdges, 0);

    string dealLines[];
    if(!JoinValidation_CollectDealsCsvDataLines(dealsUtf8Lf, dealLines)) {
        outError = "collect_deals";
        return false;
    }
    const int n = ArraySize(dealLines);
    if(n < 1) {
        outError = "no_deal_rows";
        return false;
    }
    if(!JoinValidation_AllDealCsvLinesSharePositionId(dealLines)) {
        outError = "multi_position_id";
        return false;
    }
    if(!JoinValidation_SortDealCsvDataLinesByTimeThenTicket(dealLines)) {
        outError = "sort";
        return false;
    }

    string cols0[];
    if(StringSplit(dealLines[0], ',', cols0) < 9) {
        outError = "parse_position_id";
        return false;
    }
    const ulong positionId = (ulong)StringToInteger(cols0[8]);

    double totalAbs = 0.0;
    if(!PositionRollupV1_TotalAbsVolumeFromSortedDealLines(dealLines, totalAbs)) {
        outError = "volume_sum";
        return false;
    }

    ArrayResize(outSteps, n);
    double cumulative = 0.0;
    long tOpen = 0;
    long tClose = 0;
    for(int i = 0; i < n; i++) {
        ulong tk = 0;
        ulong pos = 0;
        string sym = "";
        long mag = 0, utc = 0;
        double vol = 0, pr = 0, price = 0, cm = 0, sw = 0;
        int typ = 0, ent = 0, reas = 0;
        if(!JoinValidation_ParseDealDataRowColumns(dealLines[i], tk, sym, mag, utc, vol, pr, typ, ent, pos, price, cm, sw, reas)) {
            outError = "parse_row";
            return false;
        }
        if(pos != positionId) {
            outError = "position_drift";
            return false;
        }
        cumulative += MathAbs(vol);
        const double remaining = totalAbs - cumulative;
        if(i == 0)
            tOpen = utc;
        tClose = utc;

        outSteps[i].lifecycle_seq = i;
        outSteps[i].d_ticket = tk;
        outSteps[i].d_position_id = pos;
        outSteps[i].d_time_utc = utc;
        outSteps[i].d_volume = vol;
        outSteps[i].d_entry = ent;
        outSteps[i].d_type = typ;
        outSteps[i].cumulative_volume_closed = cumulative;
        outSteps[i].exposure_remaining = remaining;
        if(remaining > 1.0e-12)
            outSteps[i].exposure_state_after = EXPOSURE_V1_NONZERO;
        else
            outSteps[i].exposure_state_after = EXPOSURE_V1_ZERO;
    }

    outCampaign.lifecycle_group_id = positionId;
    outCampaign.root_position_id = positionId;
    outCampaign.deal_count = n;
    outCampaign.lifecycle_open_time_utc = tOpen;
    outCampaign.lifecycle_close_time_utc = tClose;
    outCampaign.total_abs_volume = totalAbs;
    if(outSteps[n - 1].exposure_state_after == EXPOSURE_V1_ZERO) {
        outCampaign.lifecycle_state = LIFECYCLE_V1_TERMINATED_FLAT;
        outCampaign.terminal_exposure_state = EXPOSURE_V1_ZERO;
    } else {
        outCampaign.lifecycle_state = LIFECYCLE_V1_ACTIVE_NONZERO;
        outCampaign.terminal_exposure_state = EXPOSURE_V1_NONZERO;
    }
    outCampaign.valid = true;

    PositionRollupV1_BuildLinearChainEdges(n, outEdges);
    return true;
}

//+------------------------------------------------------------------+
//| Deterministic fingerprint for replay equality (no floats in key).|
//+------------------------------------------------------------------+
string PositionRollupV1_CampaignFingerprint(const SRollupPositionCampaignV1 &c) {
    if(!c.valid)
        return "INVALID";
    return IntegerToString((long)c.lifecycle_group_id) + "|" + IntegerToString(c.deal_count) + "|" +
           IntegerToString((int)c.lifecycle_state) + "|" + IntegerToString((int)c.terminal_exposure_state) + "|" +
           IntegerToString((int)(c.total_abs_volume * 100000000.0 + 0.5));
}

//+------------------------------------------------------------------+
//| Step row fingerprint (ticket|seq|remaining scaled).              |
//+------------------------------------------------------------------+
string PositionRollupV1_StepFingerprint(const SRollupDealStepV1 &s) {
    return IntegerToString((long)s.d_ticket) + "|" + IntegerToString(s.lifecycle_seq) + "|" +
           IntegerToString((int)(s.exposure_remaining * 100000000.0 + 0.5));
}

#endif // __AURUM_POSITION_ROLLUP_V1_MQH__
