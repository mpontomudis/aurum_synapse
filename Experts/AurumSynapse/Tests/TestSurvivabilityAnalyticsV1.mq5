//+------------------------------------------------------------------+
//|                            TestSurvivabilityAnalyticsV1.mq5      |
//|     SURVIVABILITY_ANALYTICS_V1 — deterministic harness           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "Phase 5 — SurvivabilityAnalyticsV1 offline tests"

#include "../TelemetryAnalytics/SurvivabilityAnalyticsV1.mqh"

string Hdr(void) {
    return "d_ticket,d_symbol,d_magic,d_time_utc,d_volume,d_profit,d_type,d_entry,d_position_id,d_price,d_commission,d_swap,d_reason";
}

bool BuildAndAnalyze(const string dealsUtf8,
                    SSurvivabilityMetricsV1 &outM,
                    ENUM_SURVIVABILITY_STATE_V1 &outS,
                    string &outEx) {
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(dealsUtf8, steps, camp, edges, err))
        return false;
    return SurvivabilityAnalyticsV1_AnalyzeCampaign(camp, steps, outM, outS, outEx);
}

bool Fail(const string m) {
    Print("[SURVIVE_V1_TEST] FAIL ", m);
    return false;
}

bool T_StableSingleShot(void) {
    string d = Hdr() + "\n900001,X,0,1,1.0,0,0,0,1,0,0,0,0\n";
    SSurvivabilityMetricsV1 m;
    ENUM_SURVIVABILITY_STATE_V1 s = SURVIVE_V1_INVALID;
    string ex = "";
    if(!BuildAndAnalyze(d, m, s, ex))
        return Fail("stable_build");
    if(s != SURVIVE_V1_STABLE && s != SURVIVE_V1_TERMINATED)
        return Fail("stable_state");
    if(m.survivability_score < 80)
        return Fail("stable_score_low");
    return true;
}

bool T_DegradedConcentrated(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.9,0,0,0,77,0,0,0,0\n";
    d += "2,X,0,20,0.05,0,0,0,77,0,0,0,0\n";
    d += "3,X,0,30,0.05,0,0,0,77,0,0,0,0\n";
    SSurvivabilityMetricsV1 m;
    ENUM_SURVIVABILITY_STATE_V1 s = SURVIVE_V1_INVALID;
    string ex = "";
    if(!BuildAndAnalyze(d, m, s, ex))
        return Fail("degraded_build");
    if(s != SURVIVE_V1_DEGRADED && s != SURVIVE_V1_CRITICAL)
        return Fail("degraded_state");
    if(m.exposure_concentration < 0.7)
        return Fail("degraded_conc");
    return true;
}

bool T_CriticalSpike(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.95,0,0,0,88,0,0,0,0\n";
    d += "2,X,0,20,0.05,0,0,0,88,0,0,0,0\n";
    SSurvivabilityMetricsV1 m;
    ENUM_SURVIVABILITY_STATE_V1 s = SURVIVE_V1_INVALID;
    string ex = "";
    if(!BuildAndAnalyze(d, m, s, ex))
        return Fail("critical_build");
    if(s != SURVIVE_V1_CRITICAL)
        return Fail("critical_state");
    return true;
}

bool T_RecoveryEasing(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.4,0,0,0,99,0,0,0,0\n";
    d += "2,X,0,20,0.35,0,0,0,99,0,0,0,0\n";
    d += "3,X,0,30,0.15,0,0,0,99,0,0,0,0\n";
    d += "4,X,0,40,0.05,0,0,0,99,0,0,0,0\n";
    d += "5,X,0,50,0.05,0,0,0,99,0,0,0,0\n";
    SSurvivabilityMetricsV1 m;
    ENUM_SURVIVABILITY_STATE_V1 s = SURVIVE_V1_INVALID;
    string ex = "";
    if(!BuildAndAnalyze(d, m, s, ex))
        return Fail("recovery_build");
    if(s != SURVIVE_V1_RECOVERING && s != SURVIVE_V1_TERMINATED)
        return Fail("recovery_state");
    if(m.last_third_mean_reduction >= m.first_third_mean_reduction)
        return Fail("recovery_means");
    return true;
}

bool T_OrderlyTerminal(void) {
    string d = Hdr() + "\n";
    d += "910703,X,0,30,0.3,0,0,1,800,0,0,0,0\n";
    d += "910701,X,0,10,0.3,0,0,1,800,0,0,0,0\n";
    d += "910702,X,0,20,0.4,0,0,1,800,0,0,0,0\n";
    SSurvivabilityMetricsV1 m;
    ENUM_SURVIVABILITY_STATE_V1 s = SURVIVE_V1_INVALID;
    string ex = "";
    if(!BuildAndAnalyze(d, m, s, ex))
        return Fail("orderly_build");
    if(s != SURVIVE_V1_TERMINATED && s != SURVIVE_V1_RECOVERING)
        return Fail("orderly_state");
    if(MathAbs(m.current_exposure_load) > 1.0e-8)
        return Fail("orderly_not_flat");
    return true;
}

bool T_ReplayDeterminism(void) {
    string d = Hdr() + "\n1,X,0,1,0.5,0,0,0,5,0,0,0,0\n2,X,0,2,0.5,0,0,0,5,0,0,0,0\n";
    SSurvivabilityMetricsV1 m1, m2;
    ENUM_SURVIVABILITY_STATE_V1 s1 = SURVIVE_V1_INVALID, s2 = SURVIVE_V1_INVALID;
    string e1 = "", e2 = "";
    if(!BuildAndAnalyze(d, m1, s1, e1) || !BuildAndAnalyze(d, m2, s2, e2))
        return Fail("replay_build");
    if(m1.survivability_score != m2.survivability_score || s1 != s2 || e1 != e2)
        return Fail("replay_drift");
    return true;
}

bool T_ScoreConsistency(void) {
    string d = Hdr() + "\n1,X,0,1,0.2,0,0,0,9,0,0,0,0\n2,X,0,2,0.2,0,0,0,9,0,0,0,0\n3,X,0,3,0.6,0,0,0,9,0,0,0,0\n";
    SSurvivabilityMetricsV1 a, b;
    ENUM_SURVIVABILITY_STATE_V1 sa = SURVIVE_V1_INVALID, sb = SURVIVE_V1_INVALID;
    string ea = "", eb = "";
    if(!BuildAndAnalyze(d, a, sa, ea) || !BuildAndAnalyze(d, b, sb, eb))
        return Fail("score_build");
    if(a.survivability_score != b.survivability_score)
        return Fail("score_inconsistent");
    return true;
}

bool T_ReadOnlySteps(void) {
    string d = Hdr() + "\n1,X,0,1,0.4,0,0,0,3,0,0,0,0\n2,X,0,2,0.6,0,0,0,3,0,0,0,0\n";
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(d, steps, camp, edges, err))
        return Fail("ro_build");
    const double vol0 = steps[0].d_volume;
    SSurvivabilityMetricsV1 m;
    ENUM_SURVIVABILITY_STATE_V1 s = SURVIVE_V1_INVALID;
    string ex = "";
    if(!SurvivabilityAnalyticsV1_AnalyzeCampaign(camp, steps, m, s, ex))
        return Fail("an_build");
    if(MathAbs(steps[0].d_volume - vol0) > 1.0e-12)
        return Fail("steps_mutated");
    return true;
}

bool T_StressDecay(void) {
    string d = Hdr() + "\n";
    for(int k = 1; k <= 6; k++)
        d += IntegerToString(k) + ",X,0," + IntegerToString(k) + ",0.1,0,0,0,50,0,0,0,0\n";
    SSurvivabilityMetricsV1 m;
    ENUM_SURVIVABILITY_STATE_V1 s = SURVIVE_V1_INVALID;
    string ex = "";
    if(!BuildAndAnalyze(d, m, s, ex))
        return Fail("stress_build");
    if(m.cumulative_exposure_pressure < 0.59 || m.cumulative_exposure_pressure > 0.61)
        return Fail("stress_pressure");
    if(m.exposure_decay_rate <= 0.0)
        return Fail("stress_decay");
    return true;
}

bool T_InvalidCampaign(void) {
    SRollupPositionCampaignV1 camp;
    camp.valid = false;
    SRollupDealStepV1 steps[];
    SSurvivabilityMetricsV1 m;
    ENUM_SURVIVABILITY_STATE_V1 s = SURVIVE_V1_PRESSURED;
    string ex = "x";
    if(SurvivabilityAnalyticsV1_AnalyzeCampaign(camp, steps, m, s, ex))
        return Fail("invalid_should_fail");
    return true;
}

int OnInit() {
    if(!T_StableSingleShot())
        return INIT_FAILED;
    if(!T_DegradedConcentrated())
        return INIT_FAILED;
    if(!T_CriticalSpike())
        return INIT_FAILED;
    if(!T_RecoveryEasing())
        return INIT_FAILED;
    if(!T_OrderlyTerminal())
        return INIT_FAILED;
    if(!T_ReplayDeterminism())
        return INIT_FAILED;
    if(!T_ScoreConsistency())
        return INIT_FAILED;
    if(!T_ReadOnlySteps())
        return INIT_FAILED;
    if(!T_StressDecay())
        return INIT_FAILED;
    if(!T_InvalidCampaign())
        return INIT_FAILED;

    Print("[SURVIVE_V1_TEST] STATUS=PASS suite=survivability_analytics_v1");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}
