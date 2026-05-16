//+------------------------------------------------------------------+
//|                                   TestPositionRollupV1.mq5       |
//|     POSITION_ROLLUP_V1 — deterministic formalization harness     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "Phase 4 — PositionRollupV1 formalization tests (synthetic CSV only)"

#include "../TelemetryAnalytics/PositionRollupV1.mqh"

string DealHeaderLine(void) {
    return "d_ticket,d_symbol,d_magic,d_time_utc,d_volume,d_profit,d_type,d_entry,d_position_id,d_price,d_commission,d_swap,d_reason";
}

bool Fail(const string msg) {
    Print("[POSITION_ROLLUP_V1_TEST] FAIL ", msg);
    return false;
}

bool TestSingleDealFullFlat(void) {
    string deals = DealHeaderLine() + "\n";
    deals += "900001,XAUUSD,1,1735689600,1.00000000,0,0,0,700099,0,0,0,0\n";
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(deals, steps, camp, edges, err))
        return Fail("single_build " + err);
    if(!camp.valid || camp.deal_count != 1)
        return Fail("single_count");
    if(camp.lifecycle_state != LIFECYCLE_V1_TERMINATED_FLAT)
        return Fail("single_not_flat");
    if(steps[0].exposure_state_after != EXPOSURE_V1_ZERO)
        return Fail("single_exposure");
    if(ArraySize(edges) != 0)
        return Fail("single_edges");
    return true;
}

bool TestMultiPartialCase007Shape(void) {
    string deals = DealHeaderLine() + "\n";
    deals += "910703,XAUUSD,20260505,1735690250,0.30000000,42,0,1,800007,2650.4,-1.1,-0.3,4\n";
    deals += "910701,XAUUSD,20260505,1735689725,0.30000000,42,0,1,800007,2650.4,-1.1,-0.3,4\n";
    deals += "910702,XAUUSD,20260505,1735690010,0.40000000,42,0,1,800007,2650.4,-1.1,-0.3,4\n";

    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(deals, steps, camp, edges, err))
        return Fail("partial_build " + err);
    if(camp.deal_count != 3 || camp.lifecycle_group_id != (ulong)800007)
        return Fail("partial_ids");
    if(steps[0].d_ticket != (ulong)910701 || steps[1].d_ticket != (ulong)910702 || steps[2].d_ticket != (ulong)910703)
        return Fail("partial_sort_order");
    if(MathAbs(steps[0].exposure_remaining - 0.7) > 1.0e-6)
        return Fail("partial_rem0");
    if(MathAbs(steps[1].exposure_remaining - 0.3) > 1.0e-6)
        return Fail("partial_rem1");
    if(MathAbs(steps[2].exposure_remaining - 0.0) > 1.0e-9)
        return Fail("partial_rem2");
    if(camp.lifecycle_state != LIFECYCLE_V1_TERMINATED_FLAT)
        return Fail("partial_not_flat");
    if(ArraySize(edges) != 2)
        return Fail("partial_edge_count");
    if(edges[0].from_seq != 0 || edges[0].to_seq != 1 || edges[1].from_seq != 1 || edges[1].to_seq != 2)
        return Fail("partial_edges");
    return true;
}

bool TestReplayDeterminism(void) {
    string deals = DealHeaderLine() + "\n";
    deals += "910703,XAUUSD,20260505,1735690250,0.3,0,0,1,800007,0,0,0,0\n";
    deals += "910701,XAUUSD,20260505,1735689725,0.3,0,0,1,800007,0,0,0,0\n";
    deals += "910702,XAUUSD,20260505,1735690010,0.4,0,0,1,800007,0,0,0,0\n";
    SRollupDealStepV1 a[];
    SRollupPositionCampaignV1 ca;
    SRollupGraphEdgeV1 ea[];
    string e1 = "";
    SRollupDealStepV1 b[];
    SRollupPositionCampaignV1 cb;
    SRollupGraphEdgeV1 eb[];
    string e2 = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(deals, a, ca, ea, e1) || !PositionRollupV1_BuildFromDealsUtf8Lf(deals, b, cb, eb, e2))
        return Fail("replay_build");
    if(PositionRollupV1_CampaignFingerprint(ca) != PositionRollupV1_CampaignFingerprint(cb))
        return Fail("replay_campaign_fp");
    for(int i = 0; i < 3; i++) {
        if(PositionRollupV1_StepFingerprint(a[i]) != PositionRollupV1_StepFingerprint(b[i]))
            return Fail("replay_step_fp");
    }
    return true;
}

bool TestPositionContinuity(void) {
    string deals = DealHeaderLine() + "\n";
    deals += "1,X,0,10,0.5,0,0,0,99,0,0,0,0\n";
    deals += "2,X,0,20,0.5,0,0,0,99,0,0,0,0\n";
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(deals, steps, camp, edges, err))
        return Fail("cont_build");
    for(int i = 0; i < ArraySize(steps); i++) {
        if(steps[i].d_position_id != (ulong)99)
            return Fail("cont_pos");
    }
    return true;
}

bool TestExposureMonotone(void) {
    string deals = DealHeaderLine() + "\n";
    deals += "910703,XAUUSD,20260505,1735690250,0.30000000,0,0,1,800007,0,0,0,0\n";
    deals += "910701,XAUUSD,20260505,1735689725,0.30000000,0,0,1,800007,0,0,0,0\n";
    deals += "910702,XAUUSD,20260505,1735690010,0.40000000,0,0,1,800007,0,0,0,0\n";
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(deals, steps, camp, edges, err))
        return Fail("mono_build");
    double prev = 1.0e100;
    for(int i = 0; i < ArraySize(steps); i++) {
        if(steps[i].exposure_remaining > prev + 1.0e-9)
            return Fail("mono_not_decreasing");
        prev = steps[i].exposure_remaining;
    }
    return true;
}

bool TestSortIdempotent(void) {
    string deals = DealHeaderLine() + "\n";
    deals += "B,X,0,2,0.2,0,0,0,1,0,0,0,0\n";
    deals += "A,X,0,1,0.1,0,0,0,1,0,0,0,0\n";
    deals += "C,X,0,3,0.3,0,0,0,1,0,0,0,0\n";
    SRollupDealStepV1 s1[];
    SRollupPositionCampaignV1 c1;
    SRollupGraphEdgeV1 e1[];
    string err1 = "";
    SRollupDealStepV1 s2[];
    SRollupPositionCampaignV1 c2;
    SRollupGraphEdgeV1 e2[];
    string err2 = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(deals, s1, c1, e1, err1) || !PositionRollupV1_BuildFromDealsUtf8Lf(deals, s2, c2, e2, err2))
        return Fail("sort_build");
    if(s1[0].d_ticket != s2[0].d_ticket || s1[2].d_ticket != s2[2].d_ticket)
        return Fail("sort_order_drift");
    return true;
}

bool TestGraphNormalization(void) {
    string deals = DealHeaderLine() + "\n";
    for(int k = 1; k <= 5; k++) {
        deals += IntegerToString(k) + ",X,0," + IntegerToString(100 + k) + ",0.1,0,0,0,5000,0,0,0,0\n";
    }
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(deals, steps, camp, edges, err))
        return Fail("graph_build");
    if(ArraySize(edges) != 4)
        return Fail("graph_edge_count");
    for(int e = 0; e < 4; e++) {
        if(edges[e].to_seq - edges[e].from_seq != 1)
            return Fail("graph_not_linear");
    }
    return true;
}

bool TestAppendReplayBuffer(void) {
    SRollupReplayBufferV1 buf;
    PositionRollupV1_ReplayReset(buf);
    SRollupDealStepV1 dummy;
    dummy.lifecycle_seq = 0;
    dummy.d_ticket = 1;
    dummy.d_position_id = 9;
    dummy.d_time_utc = 1;
    dummy.d_volume = 0.1;
    dummy.d_entry = 0;
    dummy.d_type = 0;
    dummy.cumulative_volume_closed = 0.1;
    dummy.exposure_remaining = 0.9;
    dummy.exposure_state_after = EXPOSURE_V1_NONZERO;
    PositionRollupV1_ReplayPush(buf, dummy);
    dummy.lifecycle_seq = 1;
    dummy.d_ticket = 2;
    dummy.cumulative_volume_closed = 0.2;
    dummy.exposure_remaining = 0.8;
    PositionRollupV1_ReplayPush(buf, dummy);
    if(buf.count != 2)
        return Fail("replay_buf_count");
    if(buf.steps[0].d_ticket != (ulong)1 || buf.steps[1].d_ticket != (ulong)2)
        return Fail("replay_buf_order");
    return true;
}

bool TestRejectMultiPosition(void) {
    string deals = DealHeaderLine() + "\n";
    deals += "1,X,0,10,0.1,0,0,0,1,0,0,0,0\n";
    deals += "2,X,0,20,0.1,0,0,0,2,0,0,0,0\n";
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(PositionRollupV1_BuildFromDealsUtf8Lf(deals, steps, camp, edges, err))
        return Fail("multi_pos_should_fail");
    if(StringFind(err, "multi_position_id") < 0)
        return Fail("multi_pos_wrong_err");
    return true;
}

int OnInit() {
    if(!TestSingleDealFullFlat())
        return INIT_FAILED;
    if(!TestMultiPartialCase007Shape())
        return INIT_FAILED;
    if(!TestReplayDeterminism())
        return INIT_FAILED;
    if(!TestPositionContinuity())
        return INIT_FAILED;
    if(!TestExposureMonotone())
        return INIT_FAILED;
    if(!TestSortIdempotent())
        return INIT_FAILED;
    if(!TestGraphNormalization())
        return INIT_FAILED;
    if(!TestAppendReplayBuffer())
        return INIT_FAILED;
    if(!TestRejectMultiPosition())
        return INIT_FAILED;

    Print("[POSITION_ROLLUP_V1_TEST] STATUS=PASS suite=formalization_v1");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}
