//+------------------------------------------------------------------+
//|                          CausalValidationLayerV1.mqh            |
//|   CAUSAL_VALIDATION_LAYER_V1 — rule-based lifecycle explanation |
//|   Reads Rollup + SurvivabilityAnalyticsV1 + ToxicityAnalyticsV1. |
//|   Append-only: does not mutate upstream structs or history.       |
//+------------------------------------------------------------------+
#ifndef __AURUM_CAUSAL_VALIDATION_LAYER_V1_MQH__
#define __AURUM_CAUSAL_VALIDATION_LAYER_V1_MQH__

#include "ToxicityAnalyticsV1.mqh"

enum ENUM_CAUSAL_CLASS_V1 {
    CAUSAL_V1_INVALID = 0,
    CAUSAL_V1_ORDERLY_DETERIORATION,
    CAUSAL_V1_CASCADING_DEGRADATION,
    CAUSAL_V1_FAILED_RECOVERY_LOOP,
    CAUSAL_V1_TOXIC_CONTINUATION,
    CAUSAL_V1_PANIC_COLLAPSE,
    CAUSAL_V1_STRUCTURAL_FAILURE,
    CAUSAL_V1_TERMINAL_EXHAUSTION
};

enum ENUM_PANIC_CAUSAL_ROLE_V1 {
    PANIC_ROLE_V1_NONE = 0,
    PANIC_ROLE_V1_TERMINAL_EFFECT,
    PANIC_ROLE_V1_EARLY_ACCELERANT,
    PANIC_ROLE_V1_MIDCHAIN_ACCELERANT,
    PANIC_ROLE_V1_AMBIGUOUS
};

enum ENUM_COLLAPSE_SHAPE_V1 {
    COLLAPSE_SHAPE_V1_GRADUAL = 0,
    COLLAPSE_SHAPE_V1_SUDDEN,
    COLLAPSE_SHAPE_V1_MIXED
};

enum ENUM_DETERIORATION_MODE_V1 {
    DET_MODE_V1_NONE = 0,
    DET_MODE_V1_GRADUAL,
    DET_MODE_V1_ACCELERATING,
    DET_MODE_V1_UNSTABLE,
    DET_MODE_V1_SPIRAL
};

enum ENUM_RECOVERY_FAILURE_V1 {
    RECOV_FAIL_V1_NONE = 0,
    RECOV_FAIL_V1_INSUFFICIENT,
    RECOV_FAIL_V1_TEMPORARY,
    RECOV_FAIL_V1_STRUCTURALLY_UNSTABLE,
    RECOV_FAIL_V1_IMMEDIATE_RELAPSE
};

//+------------------------------------------------------------------+
//| Immutable causal interpretation for one campaign snapshot.      |
//+------------------------------------------------------------------+
struct SCausalDiagnosticsV1 {
    ENUM_CAUSAL_CLASS_V1          causal_class;
    int                           causal_confidence;
    string                        explanation_primary;
    string                        causal_chain;
    ENUM_PANIC_CAUSAL_ROLE_V1     panic_causal_role;
    ENUM_COLLAPSE_SHAPE_V1        collapse_shape;
    ENUM_DETERIORATION_MODE_V1    deterioration_mode;
    ENUM_RECOVERY_FAILURE_V1      recovery_failure;
    bool                          structural_heuristic_triggered;
    bool                          synthetic_spiral_triggered;
    bool                          orderly_terminal_exhaustion_gate;
};

//+------------------------------------------------------------------+
int CausalValidationLayerV1_ClampInt(const int v, const int lo, const int hi) {
    if(v < lo)
        return lo;
    if(v > hi)
        return hi;
    return v;
}

//+------------------------------------------------------------------+
double CausalValidationLayerV1_MeanSlice(const double &red[], const int a, const int b) {
    if(a > b)
        return 0.0;
    double s = 0.0;
    int k = 0;
    for(int i = a; i <= b; i++) {
        s += red[i];
        k++;
    }
    return (k > 0 ? s / (double)k : 0.0);
}

//+------------------------------------------------------------------+
bool CausalValidationLayerV1_DetectCascadingAcceleration(const double &red[], const int n) {
    if(n < 6)
        return false;
    const int h = n / 2;
    const double m1 = CausalValidationLayerV1_MeanSlice(red, 0, h - 1);
    const double m2 = CausalValidationLayerV1_MeanSlice(red, h, n - 1);
    if(m1 <= 1.0e-12)
        return false;
    return (m2 > m1 * 1.16);
}

//+------------------------------------------------------------------+
ENUM_DETERIORATION_MODE_V1 CausalValidationLayerV1_ClassifyDeteriorationMode(const bool spiral,
                                                                          const double instability,
                                                                          const bool cascading,
                                                                          const double &red[],
                                                                          const int n,
                                                                          const bool syntheticSpiral) {
    if(spiral)
        return DET_MODE_V1_SPIRAL;
    if(syntheticSpiral)
        return DET_MODE_V1_SPIRAL;
    if(cascading)
        return DET_MODE_V1_ACCELERATING;
    if(instability >= 0.34)
        return DET_MODE_V1_UNSTABLE;
    if(n >= 5) {
        const int h = n / 2;
        const double m1 = CausalValidationLayerV1_MeanSlice(red, 0, h - 1);
        const double m2 = CausalValidationLayerV1_MeanSlice(red, h, n - 1);
        if(m1 > 1.0e-12 && m2 > m1 * 1.10)
            return DET_MODE_V1_GRADUAL;
    }
    return DET_MODE_V1_NONE;
}

//+------------------------------------------------------------------+
ENUM_RECOVERY_FAILURE_V1 CausalValidationLayerV1_ClassifyRecoveryFailure(const bool fakeRec,
                                                                        const double failedInt,
                                                                        const ENUM_SURVIVABILITY_STATE_V1 sv,
                                                                        const double instability) {
    if(!fakeRec) {
        if(sv == SURVIVE_V1_RECOVERING && instability >= 0.30)
            return RECOV_FAIL_V1_STRUCTURALLY_UNSTABLE;
        return RECOV_FAIL_V1_NONE;
    }
    if(failedInt >= 0.55)
        return RECOV_FAIL_V1_IMMEDIATE_RELAPSE;
    if(failedInt >= 0.22)
        return RECOV_FAIL_V1_TEMPORARY;
    if(instability >= 0.28)
        return RECOV_FAIL_V1_STRUCTURALLY_UNSTABLE;
    return RECOV_FAIL_V1_INSUFFICIENT;
}

//+------------------------------------------------------------------+
ENUM_COLLAPSE_SHAPE_V1 CausalValidationLayerV1_ClassifyCollapseShape(const int n,
                                                                     const bool suddenTox,
                                                                     const double maxStepIntensity) {
    if(n <= 3 || suddenTox)
        return COLLAPSE_SHAPE_V1_SUDDEN;
    if(n >= 8 && maxStepIntensity < 2.35)
        return COLLAPSE_SHAPE_V1_GRADUAL;
    return COLLAPSE_SHAPE_V1_MIXED;
}

//+------------------------------------------------------------------+
ENUM_PANIC_CAUSAL_ROLE_V1 CausalValidationLayerV1_ClassifyPanicRole(const bool panic,
                                                                   const double &red[],
                                                                   const int n,
                                                                   const double sumRed) {
    if(!panic || n < 2 || sumRed <= 1.0e-12)
        return PANIC_ROLE_V1_NONE;
    const double r0 = red[0] / sumRed;
    if(n <= 3 && r0 >= 0.58)
        return PANIC_ROLE_V1_EARLY_ACCELERANT;
    double late = red[n - 1] / sumRed;
    if(n >= 2)
        late += red[n - 2] / sumRed;
    if(r0 >= 0.56 && late < 0.48)
        return PANIC_ROLE_V1_EARLY_ACCELERANT;
    if(late >= 0.52 && r0 < 0.48)
        return PANIC_ROLE_V1_TERMINAL_EFFECT;
    if(n >= 5 && r0 >= 0.38 && late >= 0.38)
        return PANIC_ROLE_V1_MIDCHAIN_ACCELERANT;
    return PANIC_ROLE_V1_AMBIGUOUS;
}

//+------------------------------------------------------------------+
int CausalValidationLayerV1_ChainTokenCount(const string chain) {
    if(chain == "")
        return 0;
    int c = 1;
    for(int i = 0; i < StringLen(chain); i++) {
        if(StringGetCharacter(chain, i) == '|')
            c++;
    }
    return c;
}

//+------------------------------------------------------------------+
int CausalValidationLayerV1_ComputeConfidence(const int n,
                                             const ENUM_CAUSAL_CLASS_V1 cls,
                                             const SToxicityMetricsV1 &tx,
                                             const SSurvivabilityMetricsV1 &sv,
                                             const string &chain) {
    int conf = 26;
    if(n >= 5)
        conf += 8;
    if(n >= 8)
        conf += 10;
    if(tx.toxicity_score >= 42 || sv.survivability_score <= 62)
        conf += 12;
    conf += CausalValidationLayerV1_ClampInt(CausalValidationLayerV1_ChainTokenCount(chain) * 4, 0, 24);
    if(tx.flag_fake_recovery || tx.flag_spiral_deterioration)
        conf += 14;
    if(tx.flag_panic_unwind && cls == CAUSAL_V1_PANIC_COLLAPSE)
        conf += 10;
    if(cls == CAUSAL_V1_TERMINAL_EXHAUSTION && tx.toxicity_score <= 22 && sv.survivability_score >= 75)
        conf += 12;
    if(cls == CAUSAL_V1_ORDERLY_DETERIORATION && tx.instability_persistence >= 0.20)
        conf += 6;
    return CausalValidationLayerV1_ClampInt(conf, 0, 100);
}

//+------------------------------------------------------------------+
string CausalValidationLayerV1_BuildChain(const ENUM_CAUSAL_CLASS_V1 cls,
                                       const ENUM_SURVIVABILITY_STATE_V1 sv,
                                       const ENUM_TOXICITY_STATE_V1 txSt,
                                       const ENUM_DETERIORATION_MODE_V1 det,
                                       const ENUM_RECOVERY_FAILURE_V1 rf,
                                       const ENUM_PANIC_CAUSAL_ROLE_V1 pr,
                                       const ENUM_COLLAPSE_SHAPE_V1 cs) {
    string s = "LIFECYCLE_SEQUENCE";
    if(sv == SURVIVE_V1_DEGRADED || sv == SURVIVE_V1_CRITICAL)
        s += "|SURVIVABILITY_DEGRADED_PRESSURE";
    else if(sv == SURVIVE_V1_PRESSURED)
        s += "|SURVIVABILITY_OPEN_TAIL_PRESSURE";
    else if(sv == SURVIVE_V1_RECOVERING)
        s += "|SURVIVABILITY_ORDERLY_DECELERATION";
    else if(sv == SURVIVE_V1_STABLE || sv == SURVIVE_V1_TERMINATED)
        s += "|SURVIVABILITY_TERMINAL_BAND";

    if(det == DET_MODE_V1_SPIRAL)
        s += "|UNSTABLE_REDUCTION|SPIRAL_PEAK_DEEPENING";
    else if(det == DET_MODE_V1_ACCELERATING)
        s += "|UNSTABLE_REDUCTION|CASCADING_STEP_INTENSITY";
    else if(det == DET_MODE_V1_UNSTABLE)
        s += "|UNSTABLE_REDUCTION|OSCILLATORY_CLOSURES";
    else if(det == DET_MODE_V1_GRADUAL)
        s += "|ORDERLY_EARLY_REDUCTION|GRADUAL_DETERIORATION_SLOPE";

    if(rf == RECOV_FAIL_V1_IMMEDIATE_RELAPSE || rf == RECOV_FAIL_V1_TEMPORARY)
        s += "|SHORT_RELIEF|RECOVERY_RELAPSE";
    else if(rf == RECOV_FAIL_V1_INSUFFICIENT)
        s += "|SHORT_RELIEF|RECOVERY_INSUFFICIENT";
    else if(rf == RECOV_FAIL_V1_STRUCTURALLY_UNSTABLE)
        s += "|RECOVERY_STRUCTURALLY_UNSTABLE";

    if(txSt == TOX_V1_TOXIC || txSt == TOX_V1_TERMINAL || txSt == TOX_V1_COLLAPSING)
        s += "|CONTAMINATION_PERSISTENCE";

    if(pr == PANIC_ROLE_V1_EARLY_ACCELERANT)
        s += "|PANIC_UNWIND_EARLY_ACCELERATION";
    else if(pr == PANIC_ROLE_V1_TERMINAL_EFFECT)
        s += "|PANIC_UNWIND_TERMINAL_GATE";
    else if(pr == PANIC_ROLE_V1_MIDCHAIN_ACCELERANT)
        s += "|PANIC_UNWIND_MIDCHAIN_ACCELERATION";
    else if(pr == PANIC_ROLE_V1_AMBIGUOUS)
        s += "|PANIC_UNWIND_MIXED_TIMELINE";

    if(cs == COLLAPSE_SHAPE_V1_SUDDEN)
        s += "|SUDDEN_EXPOSURE_COLLAPSE";
    else if(cs == COLLAPSE_SHAPE_V1_GRADUAL)
        s += "|GRADUAL_EXPOSURE_DRAWNDOWN";
    else
        s += "|MIXED_COLLAPSE_TEMPO";

    if(cls == CAUSAL_V1_PANIC_COLLAPSE || cls == CAUSAL_V1_STRUCTURAL_FAILURE)
        s += "|TERMINAL_COLLAPSE";
    else if(cls == CAUSAL_V1_TERMINAL_EXHAUSTION)
        s += "|ORDERLY_TERMINATION";

    return s;
}

//+------------------------------------------------------------------+
string CausalValidationLayerV1_PrimaryExplanation(const ENUM_CAUSAL_CLASS_V1 cls,
                                                 const ENUM_PANIC_CAUSAL_ROLE_V1 pr,
                                                 const bool spiral,
                                                 const bool fakeRec,
                                                 const ENUM_TOXICITY_STATE_V1 txSt,
                                                 const bool orderlyTerminalGate) {
    if(cls == CAUSAL_V1_PANIC_COLLAPSE) {
        if(pr == PANIC_ROLE_V1_TERMINAL_EFFECT)
            return "PANIC_UNWIND_AS_TERMINAL_EFFECT";
        if(pr == PANIC_ROLE_V1_EARLY_ACCELERANT)
            return "PANIC_UNWIND_ACCELERATED_FAILURE";
        return "PANIC_UNWIND_COMPRESSION_COLLAPSE";
    }
    if(cls == CAUSAL_V1_STRUCTURAL_FAILURE && spiral)
        return "TERMINAL_COLLAPSE_AFTER_SPIRAL";
    if(cls == CAUSAL_V1_STRUCTURAL_FAILURE)
        return "STRUCTURAL_EXPOSURE_DECAY";
    if(cls == CAUSAL_V1_FAILED_RECOVERY_LOOP)
        return "RECOVERY_RELAPSE_AFTER_SHORT_RELIEF";
    if(cls == CAUSAL_V1_CASCADING_DEGRADATION)
        return "CASCADING_LIQUIDATION_INTENSITY";
    if(cls == CAUSAL_V1_ORDERLY_DETERIORATION)
        return "STRUCTURAL_EXPOSURE_DECAY";
    if(cls == CAUSAL_V1_TOXIC_CONTINUATION)
        return "TOXIC_CONTINUATION_DOMINANT";
    if(cls == CAUSAL_V1_TERMINAL_EXHAUSTION && orderlyTerminalGate)
        return "ORDERLY_TERMINATION";
    if(cls == CAUSAL_V1_TERMINAL_EXHAUSTION && (txSt == TOX_V1_CLEAN || txSt == TOX_V1_WATCHLIST))
        return "ORDERLY_TERMINATION";
    if(cls == CAUSAL_V1_TERMINAL_EXHAUSTION)
        return "TERMINAL_EXHAUSTION_AFTER_STRESS";
    return "CAUSAL_UNCLASSIFIED";
}

//+------------------------------------------------------------------+
//| Structural stress without toxicity spiral flag (oscillatory /    |
//| repeated interior peaks + toxic band). Deterministic thresholds. |
//+------------------------------------------------------------------+
bool CausalValidationLayerV1_StructuralHeuristicToxicGeometry(const SToxicityMetricsV1 &tx,
                                                             const ENUM_TOXICITY_STATE_V1 txSt) {
    return (tx.deterioration_repetition >= 3 && tx.instability_persistence >= 0.48 && (int)txSt >= (int)TOX_V1_TOXIC);
}

//+------------------------------------------------------------------+
//| Structural oscillatory degradation continuity (no literal spiral |
//| flag). Thresholds aligned with StructuralHeuristicToxicGeometry. |
//+------------------------------------------------------------------+
bool CausalValidationLayerV1_IsSyntheticSpiral(const SToxicityMetricsV1 &tx,
                                              const ENUM_TOXICITY_STATE_V1 txSt) {
    return CausalValidationLayerV1_StructuralHeuristicToxicGeometry(tx, txSt);
}

//+------------------------------------------------------------------+
//| One-shot full notional close to flat: end-state exhaustion, not |
//| active panic/collapse (rollup semantics; toxicity may over-signal).|
//+------------------------------------------------------------------+
bool CausalValidationLayerV1_IsOrderlyTerminalExhaustion(const SRollupPositionCampaignV1 &camp,
                                                         const SRollupDealStepV1 &steps[],
                                                         const int n) {
    if(!camp.valid || n != 1)
        return false;
    if(camp.lifecycle_state != LIFECYCLE_V1_TERMINATED_FLAT)
        return false;
    if(camp.total_abs_volume <= 1.0e-12)
        return false;
    if(MathAbs(steps[0].exposure_remaining) > 1.0e-9)
        return false;
    if(MathAbs(MathAbs(steps[0].d_volume) - camp.total_abs_volume) > 1.0e-9)
        return false;
    return true;
}

//+------------------------------------------------------------------+
ENUM_CAUSAL_CLASS_V1 CausalValidationLayerV1_ClassifyCausal(const SRollupPositionCampaignV1 &camp,
                                                           const int n,
                                                           const ENUM_TOXICITY_STATE_V1 txSt,
                                                           const SToxicityMetricsV1 &tx,
                                                           const ENUM_SURVIVABILITY_STATE_V1 sv,
                                                           const bool cascading,
                                                           const bool spiral,
                                                           const bool fakeRec,
                                                           const bool suddenShape,
                                                           const bool structuralHeuristicToxicGeometry,
                                                           const bool orderlyTerminalExhaustion) {
    if(!camp.valid)
        return CAUSAL_V1_INVALID;
    if(orderlyTerminalExhaustion)
        return CAUSAL_V1_TERMINAL_EXHAUSTION;
    if(txSt == TOX_V1_COLLAPSING || (tx.flag_panic_unwind && (n <= 3 || suddenShape)))
        return CAUSAL_V1_PANIC_COLLAPSE;
    // Structural failure: (1) toxicity spiral flag, (2) interior peaks + instability without fake,
    // (3) toxic-band + high detRep + high instability even if fake-recovery heuristic also fires.
    if(spiral || (tx.instability_persistence >= 0.38 && tx.deterioration_repetition >= 2 && !fakeRec) ||
       structuralHeuristicToxicGeometry)
        return CAUSAL_V1_STRUCTURAL_FAILURE;
    if(fakeRec)
        return CAUSAL_V1_FAILED_RECOVERY_LOOP;
    if(cascading)
        return CAUSAL_V1_CASCADING_DEGRADATION;
    const bool survStress = (sv == SURVIVE_V1_DEGRADED || sv == SURVIVE_V1_CRITICAL || sv == SURVIVE_V1_PRESSURED);
    const bool toxMild = (txSt == TOX_V1_WATCHLIST || txSt == TOX_V1_UNSTABLE);
    if(survStress && toxMild && !fakeRec && !spiral && !cascading && txSt != TOX_V1_COLLAPSING)
        return CAUSAL_V1_ORDERLY_DETERIORATION;
    if(txSt == TOX_V1_TOXIC || txSt == TOX_V1_TERMINAL)
        return CAUSAL_V1_TOXIC_CONTINUATION;
    if(survStress)
        return CAUSAL_V1_ORDERLY_DETERIORATION;
    return CAUSAL_V1_TERMINAL_EXHAUSTION;
}

//+------------------------------------------------------------------+
//| Deterministic fingerprint for replay equality checks.            |
//+------------------------------------------------------------------+
string CausalValidationLayerV1_DiagnosticFingerprint(const SCausalDiagnosticsV1 &d) {
    return IntegerToString((int)d.causal_class) + "|" + IntegerToString(d.causal_confidence) + "|" + d.explanation_primary + "|" +
           d.causal_chain + "|" + IntegerToString((int)d.panic_causal_role) + "|" + IntegerToString((int)d.collapse_shape) + "|" +
           IntegerToString((int)d.deterioration_mode) + "|" + IntegerToString((int)d.recovery_failure) + "|" +
           (d.structural_heuristic_triggered ? "1" : "0") + "|" + (d.synthetic_spiral_triggered ? "1" : "0") + "|" +
           (d.orderly_terminal_exhaustion_gate ? "1" : "0");
}

//+------------------------------------------------------------------+
//| Main entry: append-only causal interpretation.                    |
//+------------------------------------------------------------------+
bool CausalValidationLayerV1_AnalyzeCampaign(const SRollupPositionCampaignV1 &camp,
                                          const SRollupDealStepV1 &steps[],
                                          SCausalDiagnosticsV1 &outDiag) {
    SCausalDiagnosticsV1 z;
    z.causal_class = CAUSAL_V1_INVALID;
    z.causal_confidence = 0;
    z.explanation_primary = "";
    z.causal_chain = "";
    z.panic_causal_role = PANIC_ROLE_V1_NONE;
    z.collapse_shape = COLLAPSE_SHAPE_V1_MIXED;
    z.deterioration_mode = DET_MODE_V1_NONE;
    z.recovery_failure = RECOV_FAIL_V1_NONE;
    z.structural_heuristic_triggered = false;
    z.synthetic_spiral_triggered = false;
    z.orderly_terminal_exhaustion_gate = false;
    outDiag = z;

    if(!camp.valid)
        return false;
    const int n = ArraySize(steps);
    if(n < 1 || n != camp.deal_count)
        return false;

    SSurvivabilityMetricsV1 sm;
    ENUM_SURVIVABILITY_STATE_V1 sv = SURVIVE_V1_INVALID;
    string sex = "";
    if(!SurvivabilityAnalyticsV1_AnalyzeCampaign(camp, steps, sm, sv, sex))
        return false;

    SToxicityMetricsV1 tx;
    ENUM_TOXICITY_STATE_V1 txSt = TOX_V1_INVALID;
    string tex = "";
    if(!ToxicityAnalyticsV1_AnalyzeCampaign(camp, steps, tx, txSt, tex))
        return false;

    double red[];
    if(!SurvivabilityAnalyticsV1_StepReductions(camp, steps, red))
        return false;

    double sumRed = 0.0;
    for(int i = 0; i < n; i++)
        sumRed += red[i];
    const double meanRed = sumRed / (double)n + 1.0e-12;
    double maxStepIntensity = 0.0;
    for(int j = 0; j < n; j++) {
        const double avj = MathAbs(steps[j].d_volume);
        const double inten = avj / meanRed;
        if(inten > maxStepIntensity)
            maxStepIntensity = inten;
    }

    const bool spiral = tx.flag_spiral_deterioration;
    const bool fakeRec = tx.flag_fake_recovery;
    const bool cascading = CausalValidationLayerV1_DetectCascadingAcceleration(red, n);
    const bool suddenShape = (txSt == TOX_V1_COLLAPSING) || (n <= 3 && tx.flag_panic_unwind);

    const bool orderlyTerminalExhaustion = CausalValidationLayerV1_IsOrderlyTerminalExhaustion(camp, steps, n);

    const ENUM_COLLAPSE_SHAPE_V1 cs =
        CausalValidationLayerV1_ClassifyCollapseShape(n, (txSt == TOX_V1_COLLAPSING), maxStepIntensity);
    const bool syntheticSpiral = CausalValidationLayerV1_IsSyntheticSpiral(tx, txSt);
    const ENUM_DETERIORATION_MODE_V1 det = CausalValidationLayerV1_ClassifyDeteriorationMode(
        spiral, tx.instability_persistence, cascading, red, n, syntheticSpiral);
    const ENUM_RECOVERY_FAILURE_V1 rf =
        CausalValidationLayerV1_ClassifyRecoveryFailure(fakeRec, tx.failed_recovery_intensity, sv, tx.instability_persistence);
    const ENUM_PANIC_CAUSAL_ROLE_V1 pr = CausalValidationLayerV1_ClassifyPanicRole(tx.flag_panic_unwind, red, n, sumRed);

    const bool structuralHeuristic = CausalValidationLayerV1_StructuralHeuristicToxicGeometry(tx, txSt);
    const ENUM_CAUSAL_CLASS_V1 cls = CausalValidationLayerV1_ClassifyCausal(camp, n, txSt, tx, sv, cascading, spiral, fakeRec, suddenShape,
                                                                            structuralHeuristic, orderlyTerminalExhaustion);

    const string chain = CausalValidationLayerV1_BuildChain(cls, sv, txSt, det, rf, pr, cs);
    const string primary = CausalValidationLayerV1_PrimaryExplanation(cls, pr, spiral, fakeRec, txSt, orderlyTerminalExhaustion);
    const int conf = CausalValidationLayerV1_ComputeConfidence(n, cls, tx, sm, chain);

    outDiag.causal_class = cls;
    outDiag.causal_confidence = conf;
    outDiag.explanation_primary = primary;
    outDiag.causal_chain = chain;
    outDiag.panic_causal_role = pr;
    outDiag.collapse_shape = cs;
    outDiag.deterioration_mode = det;
    outDiag.recovery_failure = rf;
    outDiag.structural_heuristic_triggered = structuralHeuristic;
    outDiag.synthetic_spiral_triggered = syntheticSpiral;
    outDiag.orderly_terminal_exhaustion_gate = orderlyTerminalExhaustion;
    return true;
}

#endif // __AURUM_CAUSAL_VALIDATION_LAYER_V1_MQH__
