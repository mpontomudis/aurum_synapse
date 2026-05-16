//+------------------------------------------------------------------+
//|                                ToxicityAnalyticsV1.mqh           |
//|     TOXICITY_ANALYTICS_V1 — deterministic lifecycle diagnostics  |
//|     Reads POSITION_ROLLUP_V1 + SURVIVABILITY_ANALYTICS_V1 only.  |
//|     No ML, no governance, no join/serialization/survive edits. |
//+------------------------------------------------------------------+
#ifndef __AURUM_TOXICITY_ANALYTICS_V1_MQH__
#define __AURUM_TOXICITY_ANALYTICS_V1_MQH__

#include "SurvivabilityAnalyticsV1.mqh"

enum ENUM_TOXICITY_STATE_V1 {
    TOX_V1_INVALID = 0,
    TOX_V1_CLEAN,
    TOX_V1_WATCHLIST,
    TOX_V1_UNSTABLE,
    TOX_V1_TOXIC,
    TOX_V1_COLLAPSING,
    TOX_V1_TERMINAL
};

//+------------------------------------------------------------------+
//| Append-only diagnostic bundle (does not mutate rollup/survival). |
//+------------------------------------------------------------------+
struct SToxicityMetricsV1 {
    double instability_persistence;
    int    deterioration_repetition;
    double failed_recovery_intensity;
    double liquidation_chaos;
    double contamination_depth;
    int    toxicity_score;
    bool   flag_fake_recovery;
    bool   flag_spiral_deterioration;
    bool   flag_panic_unwind;
};

//+------------------------------------------------------------------+
int ToxicityAnalyticsV1_ClampInt(const int v, const int lo, const int hi) {
    if(v < lo)
        return lo;
    if(v > hi)
        return hi;
    return v;
}

//+------------------------------------------------------------------+
double ToxicityAnalyticsV1_Clamp01(const double x) {
    if(x < 0.0)
        return 0.0;
    if(x > 1.0)
        return 1.0;
    return x;
}

//+------------------------------------------------------------------+
int ToxicityAnalyticsV1_CountInteriorLocalMaxima(const double &red[], const int n) {
    int c = 0;
    if(n < 3)
        return 0;
    for(int i = 1; i <= n - 2; i++) {
        if(red[i] > red[i - 1] && red[i] > red[i + 1])
            c++;
    }
    return c;
}

//+------------------------------------------------------------------+
//| Second liquidation wave strictly deeper than first interior peak. |
//+------------------------------------------------------------------+
bool ToxicityAnalyticsV1_DetectSpiralDeterioration(const double &red[], const int n, double &outDepth) {
    outDepth = 0.0;
    if(n < 6)
        return false;
    double peaks[];
    ArrayResize(peaks, 0);
    for(int i = 1; i <= n - 2; i++) {
        if(red[i] > red[i - 1] && red[i] > red[i + 1]) {
            const int p = ArraySize(peaks);
            ArrayResize(peaks, p + 1);
            peaks[p] = red[i];
        }
    }
    const int pc = ArraySize(peaks);
    if(pc < 2)
        return false;
    if(peaks[pc - 1] > peaks[0] * 1.07) {
        outDepth = ToxicityAnalyticsV1_Clamp01((peaks[pc - 1] - peaks[0]) / (peaks[0] + 1.0e-12));
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| "Healthy" mean reduction in outer thirds then relapse before tail.|
//+------------------------------------------------------------------+
bool ToxicityAnalyticsV1_DetectFakeRecovery(const double &red[], const int n,
                                           const double firstThirdMean,
                                           const double lastThirdMean) {
    if(n < 7)
        return false;
    if(firstThirdMean <= 1.0e-12)
        return false;
    const bool easingLook = (lastThirdMean < firstThirdMean * 0.78);
    if(!easingLook)
        return false;

    int t = 2;
    double mn = red[2];
    const int hi = n - 4;
    if(hi < 2)
        return false;
    for(int i = 2; i <= hi; i++) {
        if(red[i] <= mn) {
            mn = red[i];
            t = i;
        }
    }
    if(!(red[0] > mn * 1.22))
        return false;
    double mxAfter = 0.0;
    for(int j = t + 1; j <= n - 2; j++) {
        if(red[j] > mxAfter)
            mxAfter = red[j];
    }
    if(mxAfter < mn * 1.18)
        return false;

    double s1 = 0.0, c1 = 0.0, s2 = 0.0, c2 = 0.0;
    for(int a = 0; a < t; a++) {
        s1 += red[a];
        c1 += 1.0;
    }
    for(int b = t; b < n; b++) {
        s2 += red[b];
        c2 += 1.0;
    }
    if(c1 < 1.0 || c2 < 1.0)
        return false;
    if((s1 / c1) <= (s2 / c2) * 1.02)
        return false;
    return true;
}

//+------------------------------------------------------------------+
bool ToxicityAnalyticsV1_DetectPanicUnwind(const double &red[], const int n,
                                          const double sumRed,
                                          const double maxStepIntensity,
                                          const double maxConc) {
    if(n < 2)
        return false;
    if(maxStepIntensity >= 2.05 && n <= 4)
        return true;
    if(maxConc >= 0.89)
        return true;
    if(sumRed > 1.0e-12 && red[0] / sumRed >= 0.78)
        return true;
    return false;
}

//+------------------------------------------------------------------+
double ToxicityAnalyticsV1_InstabilityPersistence(const double &red[], const int n, const double sumRed) {
    if(n < 2)
        return 0.0;
    const double mu = sumRed / (double)n + 1.0e-12;
    int hit = 0;
    for(int i = 1; i < n; i++) {
        const double d = red[i] - red[i - 1];
        if(MathAbs(d) > mu * 0.44)
            hit++;
    }
    return ToxicityAnalyticsV1_Clamp01((double)hit / (double)(n - 1));
}

//+------------------------------------------------------------------+
int ToxicityAnalyticsV1_ComputeToxicityScore(const double instability,
                                          const int deteriorationRep,
                                          const double failedRecov,
                                          const double liqChaos,
                                          const double contamDepth) {
    int score = 0;
    score += (int)(instability * 38.0 + 0.5);
    score += ToxicityAnalyticsV1_ClampInt(deteriorationRep, 0, 5) * 8;
    score += (int)(failedRecov * 24.0 + 0.5);
    score += (int)(liqChaos * 28.0 + 0.5);
    score += (int)(contamDepth * 18.0 + 0.5);
    return ToxicityAnalyticsV1_ClampInt(score, 0, 100);
}

//+------------------------------------------------------------------+
ENUM_TOXICITY_STATE_V1 ToxicityAnalyticsV1_ClassifyState(const SRollupPositionCampaignV1 &camp,
                                                        const int n,
                                                        const double maxStepIntensity,
                                                        const double maxConc,
                                                        const ENUM_SURVIVABILITY_STATE_V1 sv,
                                                        const int toxScore,
                                                        const bool fakeRec,
                                                        const bool spiral,
                                                        const bool panic,
                                                        const double liqChaos,
                                                        const double instability,
                                                        const int detRep,
                                                        string &outExplain) {
    outExplain = "";
    if(!camp.valid) {
        outExplain = "INVALID_CAMPAIGN";
        return TOX_V1_INVALID;
    }

    const bool collapsing = (n <= 3 && maxConc >= 0.92) ||
                            (n <= 4 && maxStepIntensity >= 2.95 && maxConc >= 0.88);
    if(collapsing) {
        outExplain = "DISORDERLY_DEMOLITION_PATH";
        return TOX_V1_COLLAPSING;
    }

    const bool flat = (camp.lifecycle_state == LIFECYCLE_V1_TERMINATED_FLAT);
    const bool toxicTerminal = flat && panic && (maxStepIntensity >= 1.85 || maxConc >= 0.84);
    if(toxicTerminal) {
        outExplain = "PANIC_TERMINAL_UNWIND";
        return TOX_V1_TERMINAL;
    }

    const bool toxicStruct = (fakeRec && toxScore >= 38) || spiral || (detRep >= 3) || (toxScore >= 66) ||
                             (fakeRec && detRep >= 1);
    if(toxicStruct) {
        outExplain = (spiral ? "SPIRAL_CONTAMINATION" : (fakeRec ? "FAKE_RECOVERY_RELAPSE" : "STRUCTURAL_TOXICITY"));
        return TOX_V1_TOXIC;
    }

    if(instability >= 0.36 || detRep >= 2 || toxScore >= 40) {
        outExplain = "UNSTABLE_REDUCTION_STRUCTURE";
        return TOX_V1_UNSTABLE;
    }

    if(toxScore >= 16 || sv == SURVIVE_V1_DEGRADED || sv == SURVIVE_V1_CRITICAL ||
       (sv == SURVIVE_V1_PRESSURED && n >= 5)) {
        outExplain = "ELEVATED_BEHAVIOR_RISK";
        return TOX_V1_WATCHLIST;
    }

    outExplain = "HEALTHY_LIFECYCLE_GEOMETRY";
    return TOX_V1_CLEAN;
}

//+------------------------------------------------------------------+
//| Read-only: fills toxicity metrics + state; does not alter steps. |
//+------------------------------------------------------------------+
bool ToxicityAnalyticsV1_AnalyzeCampaign(const SRollupPositionCampaignV1 &camp,
                                        const SRollupDealStepV1 &steps[],
                                        SToxicityMetricsV1 &outTox,
                                        ENUM_TOXICITY_STATE_V1 &outState,
                                        string &outExplain) {
    outExplain = "";
    SToxicityMetricsV1 z;
    z.instability_persistence = 0.0;
    z.deterioration_repetition = 0;
    z.failed_recovery_intensity = 0.0;
    z.liquidation_chaos = 0.0;
    z.contamination_depth = 0.0;
    z.toxicity_score = 0;
    z.flag_fake_recovery = false;
    z.flag_spiral_deterioration = false;
    z.flag_panic_unwind = false;
    outTox = z;
    outState = TOX_V1_INVALID;

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

    double red[];
    if(!SurvivabilityAnalyticsV1_StepReductions(camp, steps, red))
        return false;

    double maxConc = 0.0;
    double sumRed = 0.0;
    const double eps = 1.0e-12;
    for(int i = 0; i < n; i++) {
        const double av = MathAbs(steps[i].d_volume);
        if(camp.total_abs_volume > eps)
            maxConc = (maxConc > av / camp.total_abs_volume ? maxConc : av / camp.total_abs_volume);
        sumRed += red[i];
    }
    const double meanRed = sumRed / (double)n + eps;
    double maxStepIntensity = 0.0;
    for(int j = 0; j < n; j++) {
        const double avj = MathAbs(steps[j].d_volume);
        const double inten = avj / meanRed;
        if(inten > maxStepIntensity)
            maxStepIntensity = inten;
    }

    const double instability = ToxicityAnalyticsV1_InstabilityPersistence(red, n, sumRed);
    const int detRep = ToxicityAnalyticsV1_CountInteriorLocalMaxima(red, n);

    double spiralDepth = 0.0;
    const bool spiral = ToxicityAnalyticsV1_DetectSpiralDeterioration(red, n, spiralDepth);
    const bool fake = ToxicityAnalyticsV1_DetectFakeRecovery(red, n, sm.first_third_mean_reduction, sm.last_third_mean_reduction);
    const bool panic = ToxicityAnalyticsV1_DetectPanicUnwind(red, n, sumRed, maxStepIntensity, maxConc);

    double failed = 0.0;
    if(fake) {
        double mxA = 0.0;
        int t = 2;
        double mn = red[2];
        const int hi = n - 4;
        for(int i = 2; i <= hi; i++) {
            if(red[i] <= mn) {
                mn = red[i];
                t = i;
            }
        }
        for(int j = t + 1; j <= n - 2; j++) {
            if(red[j] > mxA)
                mxA = red[j];
        }
        failed = ToxicityAnalyticsV1_Clamp01((mxA - mn) / (sumRed + eps));
    }

    const double liqChaos = ToxicityAnalyticsV1_Clamp01(MathMin(maxStepIntensity / 3.35, 1.0) * 0.55 + MathMin(maxConc, 1.0) * 0.35 +
                                                        (n <= 3 ? 0.10 : 0.0));

    double depth = 0.0;
    if(spiral)
        depth += 0.40;
    if(fake)
        depth += 0.34;
    if(panic)
        depth += 0.26;
    depth = ToxicityAnalyticsV1_Clamp01(depth + spiralDepth * 0.15);

    const int score = ToxicityAnalyticsV1_ComputeToxicityScore(instability, detRep, failed, liqChaos, depth);

    outTox.instability_persistence = instability;
    outTox.deterioration_repetition = detRep;
    outTox.failed_recovery_intensity = failed;
    outTox.liquidation_chaos = liqChaos;
    outTox.contamination_depth = depth;
    outTox.toxicity_score = score;
    outTox.flag_fake_recovery = fake;
    outTox.flag_spiral_deterioration = spiral;
    outTox.flag_panic_unwind = panic;

    outState = ToxicityAnalyticsV1_ClassifyState(camp, n, maxStepIntensity, maxConc, sv, score, fake, spiral, panic, liqChaos, instability, detRep, outExplain);
    return true;
}

#endif // __AURUM_TOXICITY_ANALYTICS_V1_MQH__
