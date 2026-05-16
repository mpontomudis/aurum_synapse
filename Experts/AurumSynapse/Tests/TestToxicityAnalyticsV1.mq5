//+------------------------------------------------------------------+
//|                            TestToxicityAnalyticsV1.mq5         |
//|     TOXICITY_ANALYTICS_V1 — deterministic offline harness         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "Phase 6 — ToxicityAnalyticsV1 offline tests"

#include "../TelemetryAnalytics/ToxicityAnalyticsV1.mqh"

string Hdr(void) {
    return "d_ticket,d_symbol,d_magic,d_time_utc,d_volume,d_profit,d_type,d_entry,d_position_id,d_price,d_commission,d_swap,d_reason";
}

bool BuildAndTox(const string dealsUtf8,
                SToxicityMetricsV1 &outM,
                ENUM_TOXICITY_STATE_V1 &outS,
                string &outEx) {
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(dealsUtf8, steps, camp, edges, err))
        return false;
    return ToxicityAnalyticsV1_AnalyzeCampaign(camp, steps, outM, outS, outEx);
}

bool Fail(const string m) {
    Print("[TOX_V1_TEST] FAIL ", m);
    return false;
}

bool T_CleanLifecycle(void) {
    string d = Hdr() + "\n900001,X,0,1,1.0,0,0,0,1,0,0,0,0\n";
    SToxicityMetricsV1 m;
    ENUM_TOXICITY_STATE_V1 s = TOX_V1_INVALID;
    string ex = "";
    if(!BuildAndTox(d, m, s, ex))
        return Fail("clean_build");
    if(s != TOX_V1_CLEAN && s != TOX_V1_WATCHLIST)
        return Fail("clean_state");
    if(m.toxicity_score > 35)
        return Fail("clean_score_high");
    if(m.flag_fake_recovery || m.flag_spiral_deterioration || m.flag_panic_unwind)
        return Fail("clean_flags");
    return true;
}

bool T_UnstableContinuation(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.30,0,0,0,501,0,0,0,0\n";
    d += "2,X,0,20,0.02,0,0,0,501,0,0,0,0\n";
    d += "3,X,0,30,0.28,0,0,0,501,0,0,0,0\n";
    d += "4,X,0,40,0.02,0,0,0,501,0,0,0,0\n";
    d += "5,X,0,50,0.28,0,0,0,501,0,0,0,0\n";
    d += "6,X,0,60,0.10,0,0,0,501,0,0,0,0\n";
    SToxicityMetricsV1 m;
    ENUM_TOXICITY_STATE_V1 s = TOX_V1_INVALID;
    string ex = "";
    if(!BuildAndTox(d, m, s, ex))
        return Fail("unstable_build");
    if(m.instability_persistence < 0.25)
        return Fail("unstable_instability_low");
    if(s != TOX_V1_UNSTABLE && s != TOX_V1_TOXIC && s != TOX_V1_WATCHLIST)
        return Fail("unstable_state");
    return true;
}

bool T_FakeRecoveryLoop(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.38,0,0,0,701,0,0,0,0\n";
    d += "2,X,0,20,0.22,0,0,0,701,0,0,0,0\n";
    d += "3,X,0,30,0.12,0,0,0,701,0,0,0,0\n";
    d += "4,X,0,40,0.08,0,0,0,701,0,0,0,0\n";
    d += "5,X,0,50,0.05,0,0,0,701,0,0,0,0\n";
    d += "6,X,0,60,0.10,0,0,0,701,0,0,0,0\n";
    d += "7,X,0,70,0.04,0,0,0,701,0,0,0,0\n";
    d += "8,X,0,80,0.01,0,0,0,701,0,0,0,0\n";
    SToxicityMetricsV1 m;
    ENUM_TOXICITY_STATE_V1 s = TOX_V1_INVALID;
    string ex = "";
    if(!BuildAndTox(d, m, s, ex))
        return Fail("fake_build");
    if(!m.flag_fake_recovery)
        return Fail("fake_flag");
    if(m.failed_recovery_intensity <= 1.0e-6)
        return Fail("fake_intensity");
    if(s != TOX_V1_TOXIC && s != TOX_V1_UNSTABLE)
        return Fail("fake_state");
    return true;
}

bool T_SpiralDeterioration(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.12,0,0,0,702,0,0,0,0\n";
    d += "2,X,0,20,0.11,0,0,0,702,0,0,0,0\n";
    d += "3,X,0,30,0.20,0,0,0,702,0,0,0,0\n";
    d += "4,X,0,40,0.07,0,0,0,702,0,0,0,0\n";
    d += "5,X,0,50,0.25,0,0,0,702,0,0,0,0\n";
    d += "6,X,0,60,0.08,0,0,0,702,0,0,0,0\n";
    d += "7,X,0,70,0.09,0,0,0,702,0,0,0,0\n";
    d += "8,X,0,80,0.08,0,0,0,702,0,0,0,0\n";
    SToxicityMetricsV1 m;
    ENUM_TOXICITY_STATE_V1 s = TOX_V1_INVALID;
    string ex = "";
    if(!BuildAndTox(d, m, s, ex))
        return Fail("spiral_build");
    if(!m.flag_spiral_deterioration)
        return Fail("spiral_flag");
    if(s != TOX_V1_TOXIC && s != TOX_V1_UNSTABLE)
        return Fail("spiral_state");
    return true;
}

bool T_PanicLiquidation(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.95,0,0,0,88,0,0,0,0\n";
    d += "2,X,0,20,0.05,0,0,0,88,0,0,0,0\n";
    SToxicityMetricsV1 m;
    ENUM_TOXICITY_STATE_V1 s = TOX_V1_INVALID;
    string ex = "";
    if(!BuildAndTox(d, m, s, ex))
        return Fail("panic_build");
    if(!m.flag_panic_unwind)
        return Fail("panic_flag");
    if(s != TOX_V1_COLLAPSING && s != TOX_V1_TERMINAL && s != TOX_V1_TOXIC)
        return Fail("panic_state");
    return true;
}

bool T_TerminalToxicity(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.88,0,0,0,900,0,0,0,0\n";
    d += "2,X,0,20,0.03,0,0,0,900,0,0,0,0\n";
    d += "3,X,0,30,0.03,0,0,0,900,0,0,0,0\n";
    d += "4,X,0,40,0.03,0,0,0,900,0,0,0,0\n";
    d += "5,X,0,50,0.03,0,0,0,900,0,0,0,0\n";
    SToxicityMetricsV1 m;
    ENUM_TOXICITY_STATE_V1 s = TOX_V1_INVALID;
    string ex = "";
    if(!BuildAndTox(d, m, s, ex))
        return Fail("term_build");
    if(s != TOX_V1_TERMINAL && s != TOX_V1_COLLAPSING && s != TOX_V1_TOXIC)
        return Fail("term_state");
    return true;
}

bool T_ToxicityScoreConsistency(void) {
    string d = Hdr() + "\n1,X,0,1,0.2,0,0,0,9,0,0,0,0\n2,X,0,2,0.2,0,0,0,9,0,0,0,0\n3,X,0,3,0.6,0,0,0,9,0,0,0,0\n";
    SToxicityMetricsV1 a, b;
    ENUM_TOXICITY_STATE_V1 sa = TOX_V1_INVALID, sb = TOX_V1_INVALID;
    string ea = "", eb = "";
    if(!BuildAndTox(d, a, sa, ea) || !BuildAndTox(d, b, sb, eb))
        return Fail("score_build");
    if(a.toxicity_score != b.toxicity_score)
        return Fail("score_inconsistent");
    return true;
}

bool T_ReplayDeterminism(void) {
    string d = Hdr() + "\n1,X,0,1,0.5,0,0,0,5,0,0,0,0\n2,X,0,2,0.5,0,0,0,5,0,0,0,0\n";
    SToxicityMetricsV1 m1, m2;
    ENUM_TOXICITY_STATE_V1 s1 = TOX_V1_INVALID, s2 = TOX_V1_INVALID;
    string e1 = "", e2 = "";
    if(!BuildAndTox(d, m1, s1, e1) || !BuildAndTox(d, m2, s2, e2))
        return Fail("replay_build");
    if(m1.toxicity_score != m2.toxicity_score || s1 != s2 || e1 != e2)
        return Fail("replay_drift");
    if(MathAbs(m1.liquidation_chaos - m2.liquidation_chaos) > 1.0e-15)
        return Fail("replay_chaos");
    return true;
}

bool T_AppendOnlyDiagnostics(void) {
    string d = Hdr() + "\n1,X,0,1,0.4,0,0,0,3,0,0,0,0\n2,X,0,2,0.6,0,0,0,3,0,0,0,0\n";
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(d, steps, camp, edges, err))
        return Fail("append_build");
    const double vol0 = steps[0].d_volume;
    SToxicityMetricsV1 m;
    ENUM_TOXICITY_STATE_V1 s = TOX_V1_INVALID;
    string ex = "";
    if(!ToxicityAnalyticsV1_AnalyzeCampaign(camp, steps, m, s, ex))
        return Fail("append_tox");
    if(MathAbs(steps[0].d_volume - vol0) > 1.0e-12)
        return Fail("steps_mutated");
    return true;
}

bool T_InvalidCampaign(void) {
    SRollupPositionCampaignV1 camp;
    camp.valid = false;
    SRollupDealStepV1 steps[];
    SToxicityMetricsV1 m;
    ENUM_TOXICITY_STATE_V1 s = TOX_V1_CLEAN;
    string ex = "x";
    if(ToxicityAnalyticsV1_AnalyzeCampaign(camp, steps, m, s, ex))
        return Fail("invalid_should_fail");
    return true;
}

int OnInit() {
    if(!T_CleanLifecycle())
        return INIT_FAILED;
    if(!T_UnstableContinuation())
        return INIT_FAILED;
    if(!T_FakeRecoveryLoop())
        return INIT_FAILED;
    if(!T_SpiralDeterioration())
        return INIT_FAILED;
    if(!T_PanicLiquidation())
        return INIT_FAILED;
    if(!T_TerminalToxicity())
        return INIT_FAILED;
    if(!T_ToxicityScoreConsistency())
        return INIT_FAILED;
    if(!T_ReplayDeterminism())
        return INIT_FAILED;
    if(!T_AppendOnlyDiagnostics())
        return INIT_FAILED;
    if(!T_InvalidCampaign())
        return INIT_FAILED;

    Print("[TOX_V1_TEST] STATUS=PASS suite=toxicity_analytics_v1");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}
