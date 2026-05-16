//+------------------------------------------------------------------+
//|                               SurvivabilityAnalyticsV1.mqh       |
//|     SURVIVABILITY_ANALYTICS_V1 — deterministic observability     |
//|     Inputs: POSITION_ROLLUP_V1 campaign + ordered steps only.    |
//|     No ML, no execution mutation, no join/serialization changes.  |
//+------------------------------------------------------------------+
#ifndef __AURUM_SURVIVABILITY_ANALYTICS_V1_MQH__
#define __AURUM_SURVIVABILITY_ANALYTICS_V1_MQH__

#include "PositionRollupV1.mqh"

enum ENUM_SURVIVABILITY_STATE_V1 {
    SURVIVE_V1_INVALID = 0,
    SURVIVE_V1_STABLE,
    SURVIVE_V1_PRESSURED,
    SURVIVE_V1_DEGRADED,
    SURVIVE_V1_CRITICAL,
    SURVIVE_V1_RECOVERING,
    SURVIVE_V1_TERMINATED
};

//+------------------------------------------------------------------+
//| Deterministic survivability observability bundle (append-only    |
//| semantics: callers pass immutable snapshots from rollup).       |
//+------------------------------------------------------------------+
struct SSurvivabilityMetricsV1 {
    double current_exposure_load;
    double cumulative_exposure_pressure;
    double exposure_decay_rate;
    double exposure_concentration;
    double staged_liquidation_intensity;
    double max_liquidation_spike_ratio;
    double first_third_mean_reduction;
    double last_third_mean_reduction;
    int    survivability_score;
};

//+------------------------------------------------------------------+
int SurvivabilityAnalyticsV1_ClampInt(const int v, const int lo, const int hi) {
    if(v < lo)
        return lo;
    if(v > hi)
        return hi;
    return v;
}

//+------------------------------------------------------------------+
//| Per-step absolute reduction in exposure_remaining (>= 0).         |
//+------------------------------------------------------------------+
bool SurvivabilityAnalyticsV1_StepReductions(const SRollupPositionCampaignV1 &camp,
                                             const SRollupDealStepV1 &steps[],
                                             double &outRed[]) {
    ArrayResize(outRed, 0);
    if(!camp.valid)
        return false;
    const int n = ArraySize(steps);
    if(n < 1)
        return false;
    ArrayResize(outRed, n);
    double prevRem = camp.total_abs_volume;
    for(int i = 0; i < n; i++) {
        const double r = prevRem - steps[i].exposure_remaining;
        if(r < -1.0e-9) {
            ArrayResize(outRed, 0);
            return false;
        }
        outRed[i] = (r > 0.0 ? r : 0.0);
        prevRem = steps[i].exposure_remaining;
    }
    return true;
}

//+------------------------------------------------------------------+
//| Mean reduction over index range [a..b] inclusive.               |
//+------------------------------------------------------------------+
double SurvivabilityAnalyticsV1_MeanReductionSlice(const double &red[], const int a, const int b) {
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
//| Deterministic survivability score (0–100) — weighted integer     |
//| composition from rollup geometry only.                         |
//+------------------------------------------------------------------+
int SurvivabilityAnalyticsV1_ComputeScore(const SRollupPositionCampaignV1 &camp,
                                         const SRollupDealStepV1 &steps[],
                                         const double maxConc,
                                         const double maxSpike,
                                         const double firstThirdMean,
                                         const double lastThirdMean) {
    int score = 55;
    const int n = ArraySize(steps);

    if(n == 1 && camp.lifecycle_state == LIFECYCLE_V1_TERMINATED_FLAT && maxSpike <= 1.01)
        score += 40;

    if(n >= 3 && camp.lifecycle_state == LIFECYCLE_V1_TERMINATED_FLAT) {
        if(firstThirdMean > 1.0e-12 && lastThirdMean < firstThirdMean * 0.75)
            score += 20;
    }

    if(maxConc > 0.75)
        score -= 30;
    else if(maxConc > 0.55)
        score -= 15;

    if(maxSpike > 2.5)
        score -= 35;
    else if(maxSpike > 1.8)
        score -= 20;

    if(camp.lifecycle_state == LIFECYCLE_V1_ACTIVE_NONZERO)
        score -= 15;

    if(n >= 4) {
        const double staged = (double)(n - 1) / (double)n;
        if(staged >= 0.55 && staged <= 0.85 && maxConc <= 0.55)
            score += 10;
    }

    return SurvivabilityAnalyticsV1_ClampInt(score, 0, 100);
}

//+------------------------------------------------------------------+
//| Rule-based summary state (explainable, deterministic).          |
//+------------------------------------------------------------------+
ENUM_SURVIVABILITY_STATE_V1 SurvivabilityAnalyticsV1_ClassifyState(const SRollupPositionCampaignV1 &camp,
                                                                 const SRollupDealStepV1 &steps[],
                                                                 const double maxConc,
                                                                 const double maxSpike,
                                                                 const double firstThirdMean,
                                                                 const double lastThirdMean,
                                                                 string &outExplain) {
    outExplain = "";
    if(!camp.valid) {
        outExplain = "INVALID_CAMPAIGN";
        return SURVIVE_V1_INVALID;
    }

    const int n = ArraySize(steps);

    if(camp.lifecycle_state == LIFECYCLE_V1_ACTIVE_NONZERO) {
        outExplain = "OPEN_EXPOSURE_TAIL";
        return SURVIVE_V1_PRESSURED;
    }

    if(maxSpike >= 2.5) {
        outExplain = "LIQUIDATION_SPIKE_HIGH";
        return SURVIVE_V1_CRITICAL;
    }

    if(maxConc >= 0.75) {
        outExplain = "CONCENTRATED_REDUCTION";
        return SURVIVE_V1_DEGRADED;
    }

    if(n >= 3 && camp.lifecycle_state == LIFECYCLE_V1_TERMINATED_FLAT) {
        if(firstThirdMean > 1.0e-12 && lastThirdMean < firstThirdMean * 0.75) {
            outExplain = "ORDERLY_DECELERATION_TO_FLAT";
            return SURVIVE_V1_RECOVERING;
        }
    }

    if(n == 1 && camp.lifecycle_state == LIFECYCLE_V1_TERMINATED_FLAT && maxSpike <= 1.01) {
        outExplain = "SINGLE_SHOT_FLAT";
        return SURVIVE_V1_STABLE;
    }

    if(camp.lifecycle_state == LIFECYCLE_V1_TERMINATED_FLAT) {
        outExplain = "MULTI_STEP_TERMINAL_FLAT";
        return SURVIVE_V1_TERMINATED;
    }

    outExplain = "ACTIVE_NONTERMINAL";
    return SURVIVE_V1_PRESSURED;
}

//+------------------------------------------------------------------+
//| Main entry: fills metrics + summary state + short explain tag.   |
//| Does not mutate `steps` or `camp` (read-only pass).             |
//+------------------------------------------------------------------+
bool SurvivabilityAnalyticsV1_AnalyzeCampaign(const SRollupPositionCampaignV1 &camp,
                                            const SRollupDealStepV1 &steps[],
                                            SSurvivabilityMetricsV1 &outMetrics,
                                            ENUM_SURVIVABILITY_STATE_V1 &outState,
                                            string &outExplain) {
    outExplain = "";
    SSurvivabilityMetricsV1 m;
    m.current_exposure_load = 0.0;
    m.cumulative_exposure_pressure = 0.0;
    m.exposure_decay_rate = 0.0;
    m.exposure_concentration = 0.0;
    m.staged_liquidation_intensity = 0.0;
    m.max_liquidation_spike_ratio = 0.0;
    m.first_third_mean_reduction = 0.0;
    m.last_third_mean_reduction = 0.0;
    m.survivability_score = 0;
    outMetrics = m;
    outState = SURVIVE_V1_INVALID;
    if(!camp.valid)
        return false;
    const int n = ArraySize(steps);
    if(n < 1 || n != camp.deal_count)
        return false;

    double red[];
    if(!SurvivabilityAnalyticsV1_StepReductions(camp, steps, red))
        return false;

    double maxConc = 0.0;
    double maxSpike = 0.0;
    double sumRed = 0.0;
    int sigSteps = 0;
    const double eps = 1.0e-9;

    double prevRem = camp.total_abs_volume;
    for(int i = 0; i < n; i++) {
        const double av = MathAbs(steps[i].d_volume);
        if(camp.total_abs_volume > eps)
            maxConc = (maxConc > av / camp.total_abs_volume ? maxConc : av / camp.total_abs_volume);
        const double denom = prevRem + eps;
        const double spike = av / denom;
        maxSpike = (maxSpike > spike ? maxSpike : spike);
        prevRem = steps[i].exposure_remaining;
        sumRed += red[i];
        if(red[i] > 1.0e-6)
            sigSteps++;
    }

    double firstMean = 0.0;
    double lastMean = 0.0;
    if(n >= 3) {
        const int t0 = 0;
        const int t1 = (n - 1) / 3;
        const int t2 = n - (n / 3);
        firstMean = SurvivabilityAnalyticsV1_MeanReductionSlice(red, t0, t1);
        lastMean = SurvivabilityAnalyticsV1_MeanReductionSlice(red, t2, n - 1);
    }

    outMetrics.current_exposure_load = steps[n - 1].exposure_remaining;
    outMetrics.cumulative_exposure_pressure = sumRed;
    outMetrics.exposure_decay_rate = (n > 0 ? sumRed / (double)n : 0.0);
    outMetrics.exposure_concentration = maxConc;
    outMetrics.staged_liquidation_intensity = (n > 0 ? (double)sigSteps / (double)n : 0.0);
    outMetrics.max_liquidation_spike_ratio = maxSpike;
    outMetrics.first_third_mean_reduction = firstMean;
    outMetrics.last_third_mean_reduction = lastMean;
    outMetrics.survivability_score = SurvivabilityAnalyticsV1_ComputeScore(camp, steps, maxConc, maxSpike, firstMean, lastMean);

    outState = SurvivabilityAnalyticsV1_ClassifyState(camp, steps, maxConc, maxSpike, firstMean, lastMean, outExplain);
    return true;
}

#endif // __AURUM_SURVIVABILITY_ANALYTICS_V1_MQH__
