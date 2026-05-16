//+------------------------------------------------------------------+
//|                       TestCausalValidationLayerV1.mq5           |
//|   CAUSAL_VALIDATION_LAYER_V1 — deterministic offline harness    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "Phase 7 — CausalValidationLayerV1 offline tests"

#include "../TelemetryAnalytics/CausalValidationLayerV1.mqh"

string Hdr(void) {
    return "d_ticket,d_symbol,d_magic,d_time_utc,d_volume,d_profit,d_type,d_entry,d_position_id,d_price,d_commission,d_swap,d_reason";
}

bool BuildCausal(const string dealsUtf8, SCausalDiagnosticsV1 &outD) {
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(dealsUtf8, steps, camp, edges, err))
        return false;
    return CausalValidationLayerV1_AnalyzeCampaign(camp, steps, outD);
}

bool Fail(const string m) {
    Print("[CAUSAL_V1_TEST] FAIL ", m);
    return false;
}

string CausalV1_ClassName(const ENUM_CAUSAL_CLASS_V1 c) {
    if(c == CAUSAL_V1_ORDERLY_DETERIORATION)
        return "ORDERLY_DETERIORATION";
    if(c == CAUSAL_V1_CASCADING_DEGRADATION)
        return "CASCADING_DEGRADATION";
    if(c == CAUSAL_V1_FAILED_RECOVERY_LOOP)
        return "FAILED_RECOVERY_LOOP";
    if(c == CAUSAL_V1_TOXIC_CONTINUATION)
        return "TOXIC_CONTINUATION";
    if(c == CAUSAL_V1_PANIC_COLLAPSE)
        return "PANIC_COLLAPSE";
    if(c == CAUSAL_V1_STRUCTURAL_FAILURE)
        return "STRUCTURAL_FAILURE";
    if(c == CAUSAL_V1_TERMINAL_EXHAUSTION)
        return "TERMINAL_EXHAUSTION";
    if(c == CAUSAL_V1_INVALID)
        return "INVALID";
    return "UNKNOWN_CLASS";
}

string CausalV1_ToxStateName(const ENUM_TOXICITY_STATE_V1 s) {
    if(s == TOX_V1_CLEAN)
        return "CLEAN";
    if(s == TOX_V1_WATCHLIST)
        return "WATCHLIST";
    if(s == TOX_V1_UNSTABLE)
        return "UNSTABLE";
    if(s == TOX_V1_TOXIC)
        return "TOXIC";
    if(s == TOX_V1_COLLAPSING)
        return "COLLAPSING";
    if(s == TOX_V1_TERMINAL)
        return "TERMINAL";
    return "TOX_INVALID";
}

string CausalV1_SurvStateName(const ENUM_SURVIVABILITY_STATE_V1 s) {
    if(s == SURVIVE_V1_STABLE)
        return "STABLE";
    if(s == SURVIVE_V1_PRESSURED)
        return "PRESSURED";
    if(s == SURVIVE_V1_DEGRADED)
        return "DEGRADED";
    if(s == SURVIVE_V1_CRITICAL)
        return "CRITICAL";
    if(s == SURVIVE_V1_RECOVERING)
        return "RECOVERING";
    if(s == SURVIVE_V1_TERMINATED)
        return "TERMINATED";
    return "SURV_INVALID";
}

string CausalV1_PanicRoleName(const ENUM_PANIC_CAUSAL_ROLE_V1 r) {
    if(r == PANIC_ROLE_V1_NONE)
        return "NONE";
    if(r == PANIC_ROLE_V1_TERMINAL_EFFECT)
        return "TERMINAL_EFFECT";
    if(r == PANIC_ROLE_V1_EARLY_ACCELERANT)
        return "EARLY_ACCELERANT";
    if(r == PANIC_ROLE_V1_MIDCHAIN_ACCELERANT)
        return "MIDCHAIN_ACCELERANT";
    if(r == PANIC_ROLE_V1_AMBIGUOUS)
        return "AMBIGUOUS";
    return "PANIC_ROLE_UNKNOWN";
}

void CausalV1_PrintForensicStructScenario(const string dealsUtf8, const SCausalDiagnosticsV1 &g) {
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(dealsUtf8, steps, camp, edges, err)) {
        Print("[CAUSAL_FORENSIC] expected=STRUCTURAL_FAILURE actual=", CausalV1_ClassName(g.causal_class), " rollup_err=", err);
        return;
    }
    SSurvivabilityMetricsV1 sm;
    ENUM_SURVIVABILITY_STATE_V1 sv = SURVIVE_V1_INVALID;
    string sex = "";
    SurvivabilityAnalyticsV1_AnalyzeCampaign(camp, steps, sm, sv, sex);
    SToxicityMetricsV1 tx;
    ENUM_TOXICITY_STATE_V1 txSt = TOX_V1_INVALID;
    string tex = "";
    ToxicityAnalyticsV1_AnalyzeCampaign(camp, steps, tx, txSt, tex);

    Print("[CAUSAL_FORENSIC] expected=STRUCTURAL_FAILURE actual=", CausalV1_ClassName(g.causal_class));
    Print("[CAUSAL_FORENSIC] deterioration_mode=", IntegerToString((int)g.deterioration_mode),
          " recovery_failure=", IntegerToString((int)g.recovery_failure),
          " collapse_shape=", IntegerToString((int)g.collapse_shape),
          " panic_role=", CausalV1_PanicRoleName(g.panic_causal_role));
    Print("[CAUSAL_FORENSIC] toxicity_state=", CausalV1_ToxStateName(txSt),
          " survivability_state=", CausalV1_SurvStateName(sv));
    Print("[CAUSAL_FORENSIC] flag_fake_recovery=", (tx.flag_fake_recovery ? "1" : "0"),
          " flag_spiral_deterioration=", (tx.flag_spiral_deterioration ? "1" : "0"),
          " flag_panic_unwind=", (tx.flag_panic_unwind ? "1" : "0"));
    Print("[CAUSAL_FORENSIC] structural_heuristic_triggered=", (g.structural_heuristic_triggered ? "1" : "0"));
    Print("[CAUSAL_FORENSIC] synthetic_spiral_triggered=", (g.synthetic_spiral_triggered ? "1" : "0"));
    Print("[CAUSAL_FORENSIC] instability_persistence=", DoubleToString(tx.instability_persistence, 6),
          " deterioration_repetition=", IntegerToString(tx.deterioration_repetition));
    Print("[CAUSAL_FORENSIC] toxicity_score=", IntegerToString(tx.toxicity_score),
          " survivability_score=", IntegerToString(sm.survivability_score));
    Print("[CAUSAL_FORENSIC] explanation_primary=", g.explanation_primary);
    Print("[CAUSAL_FORENSIC] causal_chain=", g.causal_chain);
}

void CausalV1_PrintForensicTermScenario(const string dealsUtf8, const SCausalDiagnosticsV1 &g) {
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    string err = "";
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(dealsUtf8, steps, camp, edges, err)) {
        Print("[CAUSAL_FORENSIC_TERM] expected=TERMINAL_EXHAUSTION actual=", CausalV1_ClassName(g.causal_class), " rollup_err=", err);
        return;
    }
    SSurvivabilityMetricsV1 sm;
    ENUM_SURVIVABILITY_STATE_V1 sv = SURVIVE_V1_INVALID;
    string sex = "";
    SurvivabilityAnalyticsV1_AnalyzeCampaign(camp, steps, sm, sv, sex);
    SToxicityMetricsV1 tx;
    ENUM_TOXICITY_STATE_V1 txSt = TOX_V1_INVALID;
    string tex = "";
    ToxicityAnalyticsV1_AnalyzeCampaign(camp, steps, tx, txSt, tex);

    Print("[CAUSAL_FORENSIC_TERM] expected=TERMINAL_EXHAUSTION actual=", CausalV1_ClassName(g.causal_class));
    Print("[CAUSAL_FORENSIC_TERM] deterioration_mode=", IntegerToString((int)g.deterioration_mode),
          " recovery_failure=", IntegerToString((int)g.recovery_failure),
          " collapse_shape=", IntegerToString((int)g.collapse_shape),
          " panic_role=", CausalV1_PanicRoleName(g.panic_causal_role));
    Print("[CAUSAL_FORENSIC_TERM] toxicity_state=", CausalV1_ToxStateName(txSt),
          " survivability_state=", CausalV1_SurvStateName(sv));
    Print("[CAUSAL_FORENSIC_TERM] flag_fake_recovery=", (tx.flag_fake_recovery ? "1" : "0"),
          " flag_spiral_deterioration=", (tx.flag_spiral_deterioration ? "1" : "0"),
          " flag_panic_unwind=", (tx.flag_panic_unwind ? "1" : "0"));
    Print("[CAUSAL_FORENSIC_TERM] structural_heuristic_triggered=", (g.structural_heuristic_triggered ? "1" : "0"),
          " synthetic_spiral_triggered=", (g.synthetic_spiral_triggered ? "1" : "0"));
    Print("[CAUSAL_FORENSIC_TERM] orderly_terminal_exhaustion_gate=", (g.orderly_terminal_exhaustion_gate ? "1" : "0"));
    Print("[CAUSAL_FORENSIC_TERM] instability_persistence=", DoubleToString(tx.instability_persistence, 6),
          " deterioration_repetition=", IntegerToString(tx.deterioration_repetition));
    Print("[CAUSAL_FORENSIC_TERM] toxicity_score=", IntegerToString(tx.toxicity_score),
          " survivability_score=", IntegerToString(sm.survivability_score));
    Print("[CAUSAL_FORENSIC_TERM] explanation_primary=", g.explanation_primary);
    Print("[CAUSAL_FORENSIC_TERM] causal_chain=", g.causal_chain);
}

bool T_OrderlyDeterioration(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.77,0,0,0,601,0,0,0,0\n";
    d += "2,X,0,20,0.046,0,0,0,601,0,0,0,0\n";
    d += "3,X,0,30,0.046,0,0,0,601,0,0,0,0\n";
    d += "4,X,0,40,0.046,0,0,0,601,0,0,0,0\n";
    d += "5,X,0,50,0.046,0,0,0,601,0,0,0,0\n";
    d += "6,X,0,60,0.036,0,0,0,601,0,0,0,0\n";
    SCausalDiagnosticsV1 g;
    if(!BuildCausal(d, g))
        return Fail("orderly_build");
    if(g.causal_class != CAUSAL_V1_ORDERLY_DETERIORATION)
        return Fail("orderly_class");
    if(g.deterioration_mode == DET_MODE_V1_SPIRAL)
        return Fail("orderly_spiral_unexpected");
    return true;
}

bool T_CascadingDegradation(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.05,0,0,0,602,0,0,0,0\n";
    d += "2,X,0,20,0.05,0,0,0,602,0,0,0,0\n";
    d += "3,X,0,30,0.05,0,0,0,602,0,0,0,0\n";
    d += "4,X,0,40,0.05,0,0,0,602,0,0,0,0\n";
    d += "5,X,0,50,0.35,0,0,0,602,0,0,0,0\n";
    d += "6,X,0,60,0.45,0,0,0,602,0,0,0,0\n";
    SCausalDiagnosticsV1 g;
    if(!BuildCausal(d, g))
        return Fail("cascade_build");
    if(g.causal_class != CAUSAL_V1_CASCADING_DEGRADATION)
        return Fail("cascade_class");
    if(g.deterioration_mode != DET_MODE_V1_ACCELERATING)
        return Fail("cascade_det_mode");
    return true;
}

bool T_FailedRecoveryLoop(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.38,0,0,0,701,0,0,0,0\n";
    d += "2,X,0,20,0.22,0,0,0,701,0,0,0,0\n";
    d += "3,X,0,30,0.12,0,0,0,701,0,0,0,0\n";
    d += "4,X,0,40,0.08,0,0,0,701,0,0,0,0\n";
    d += "5,X,0,50,0.05,0,0,0,701,0,0,0,0\n";
    d += "6,X,0,60,0.10,0,0,0,701,0,0,0,0\n";
    d += "7,X,0,70,0.04,0,0,0,701,0,0,0,0\n";
    d += "8,X,0,80,0.01,0,0,0,701,0,0,0,0\n";
    SCausalDiagnosticsV1 g;
    if(!BuildCausal(d, g))
        return Fail("failrec_build");
    if(g.causal_class != CAUSAL_V1_FAILED_RECOVERY_LOOP)
        return Fail("failrec_class");
    if(g.recovery_failure == RECOV_FAIL_V1_NONE)
        return Fail("failrec_rf");
    if(g.explanation_primary != "RECOVERY_RELAPSE_AFTER_SHORT_RELIEF")
        return Fail("failrec_primary");
    return true;
}

bool T_PanicUnwindCollapse(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.95,0,0,0,88,0,0,0,0\n";
    d += "2,X,0,20,0.05,0,0,0,88,0,0,0,0\n";
    SCausalDiagnosticsV1 g;
    if(!BuildCausal(d, g))
        return Fail("panic_build");
    if(g.causal_class != CAUSAL_V1_PANIC_COLLAPSE)
        return Fail("panic_class");
    if(g.panic_causal_role != PANIC_ROLE_V1_EARLY_ACCELERANT)
        return Fail("panic_role");
    if(StringFind(g.causal_chain, "PANIC_UNWIND") < 0)
        return Fail("panic_chain");
    return true;
}

bool T_StructuralFailureChain(void) {
    string d = Hdr() + "\n";
    d += "1,X,0,10,0.12,0,0,0,702,0,0,0,0\n";
    d += "2,X,0,20,0.11,0,0,0,702,0,0,0,0\n";
    d += "3,X,0,30,0.20,0,0,0,702,0,0,0,0\n";
    d += "4,X,0,40,0.07,0,0,0,702,0,0,0,0\n";
    d += "5,X,0,50,0.25,0,0,0,702,0,0,0,0\n";
    d += "6,X,0,60,0.08,0,0,0,702,0,0,0,0\n";
    d += "7,X,0,70,0.09,0,0,0,702,0,0,0,0\n";
    d += "8,X,0,80,0.08,0,0,0,702,0,0,0,0\n";
    SCausalDiagnosticsV1 g;
    if(!BuildCausal(d, g))
        return Fail("struct_build");
    if(g.causal_class != CAUSAL_V1_STRUCTURAL_FAILURE) {
        CausalV1_PrintForensicStructScenario(d, g);
        return Fail("struct_class");
    }
    if(g.deterioration_mode != DET_MODE_V1_SPIRAL) {
        CausalV1_PrintForensicStructScenario(d, g);
        return Fail("struct_det");
    }
    if(StringFind(g.causal_chain, "SPIRAL_PEAK_DEEPENING") < 0) {
        CausalV1_PrintForensicStructScenario(d, g);
        return Fail("struct_chain");
    }
    return true;
}

bool T_TerminalExhaustion(void) {
    string d = Hdr() + "\n900001,X,0,1,1.0,0,0,0,1,0,0,0,0\n";
    SCausalDiagnosticsV1 g;
    if(!BuildCausal(d, g))
        return Fail("term_build");
    if(g.causal_class != CAUSAL_V1_TERMINAL_EXHAUSTION) {
        CausalV1_PrintForensicTermScenario(d, g);
        return Fail("term_class");
    }
    if(g.explanation_primary != "ORDERLY_TERMINATION") {
        CausalV1_PrintForensicTermScenario(d, g);
        return Fail("term_primary");
    }
    return true;
}

bool T_ExplanationConsistency(void) {
    string d = Hdr() + "\n1,X,0,1,0.5,0,0,0,5,0,0,0,0\n2,X,0,2,0.5,0,0,0,5,0,0,0,0\n";
    SCausalDiagnosticsV1 a, b;
    if(!BuildCausal(d, a) || !BuildCausal(d, b))
        return Fail("expl_build");
    if(a.explanation_primary != b.explanation_primary)
        return Fail("expl_primary_drift");
    if(a.causal_chain != b.causal_chain)
        return Fail("expl_chain_drift");
    return true;
}

bool T_ConfidenceDeterminism(void) {
    string d = Hdr() + "\n1,X,0,1,0.3,0,0,0,9,0,0,0,0\n2,X,0,2,0.3,0,0,0,9,0,0,0,0\n3,X,0,3,0.4,0,0,0,9,0,0,0,0\n";
    SCausalDiagnosticsV1 x, y;
    if(!BuildCausal(d, x) || !BuildCausal(d, y))
        return Fail("conf_build");
    if(x.causal_confidence != y.causal_confidence)
        return Fail("conf_drift");
    return true;
}

bool T_DeterministicReplay(void) {
    string d = Hdr() + "\n1,X,0,10,0.88,0,0,0,900,0,0,0,0\n";
    d += "2,X,0,20,0.03,0,0,0,900,0,0,0,0\n";
    d += "3,X,0,30,0.03,0,0,0,900,0,0,0,0\n";
    d += "4,X,0,40,0.03,0,0,0,900,0,0,0,0\n";
    d += "5,X,0,50,0.03,0,0,0,900,0,0,0,0\n";
    SCausalDiagnosticsV1 g1, g2;
    if(!BuildCausal(d, g1) || !BuildCausal(d, g2))
        return Fail("replay_build");
    if(CausalValidationLayerV1_DiagnosticFingerprint(g1) != CausalValidationLayerV1_DiagnosticFingerprint(g2))
        return Fail("replay_fp");
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
    const double v0 = steps[0].d_volume;
    SCausalDiagnosticsV1 g;
    if(!CausalValidationLayerV1_AnalyzeCampaign(camp, steps, g))
        return Fail("append_causal");
    if(MathAbs(steps[0].d_volume - v0) > 1.0e-12)
        return Fail("steps_mutated");
    return true;
}

bool T_InvalidCampaign(void) {
    SRollupPositionCampaignV1 camp;
    camp.valid = false;
    SRollupDealStepV1 steps[];
    SCausalDiagnosticsV1 g;
    if(CausalValidationLayerV1_AnalyzeCampaign(camp, steps, g))
        return Fail("invalid_should_fail");
    return true;
}

int OnInit() {
    if(!T_OrderlyDeterioration())
        return INIT_FAILED;
    if(!T_CascadingDegradation())
        return INIT_FAILED;
    if(!T_FailedRecoveryLoop())
        return INIT_FAILED;
    if(!T_PanicUnwindCollapse())
        return INIT_FAILED;
    if(!T_StructuralFailureChain())
        return INIT_FAILED;
    if(!T_TerminalExhaustion())
        return INIT_FAILED;
    if(!T_ExplanationConsistency())
        return INIT_FAILED;
    if(!T_ConfidenceDeterminism())
        return INIT_FAILED;
    if(!T_DeterministicReplay())
        return INIT_FAILED;
    if(!T_AppendOnlyDiagnostics())
        return INIT_FAILED;
    if(!T_InvalidCampaign())
        return INIT_FAILED;

    Print("[CAUSAL_V1_TEST] STATUS=PASS suite=causal_validation_layer_v1");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}
