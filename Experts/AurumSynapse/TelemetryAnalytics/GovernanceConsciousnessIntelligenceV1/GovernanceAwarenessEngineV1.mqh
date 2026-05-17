//+------------------------------------------------------------------+
//| GovernanceAwarenessEngineV1.mqh                                 |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — longitudinal awareness  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_AWARE_V1_MQH__
#define __AURUM_GOV_CON_AWARE_V1_MQH__

#include "GovernanceConsciousnessDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceResilienceIntelligenceV1/GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceTemporalIntelligenceV1/GovernanceTemporalDatasetV1.mqh"
#include "../GovernanceEcologyIntelligenceV1/GovernanceEcologyDatasetV1.mqh"

bool GovAwareV1_Compute(const SGovReplayTimelineV1 &tl, const SGovResilienceProfileV1 &rp, const SGovTemporalSummaryV1 &tmp, const SGovEcologySummaryV1 &eco, SGovAwarenessProfileV1 &out, string &out_err) {
    out_err = "";
    GovConDsV1_InitAware(out);
    const int n = GovClampInt32(ArraySize(tl.epochs), 0, GOV_REPLAY_V1_MAX_EPOCHS);
    int surv_spread = 0;
    if(n >= 2) {
        int smin = tl.epochs[0].survivability_ms;
        int smax = tl.epochs[0].survivability_ms;
        for(int k = 1; k < n; k++) {
            const int s = GovClampInt32(tl.epochs[k].survivability_ms, 0, 100000);
            smin = MathMin(smin, s);
            smax = MathMax(smax, s);
        }
        surv_spread = GovSaturatingAdd32(smax, -smin);
    }
    out.survivability_awareness_milli = GovClampInt32(GovSaturatingAdd32(surv_spread * 100, rp.summary.survivability_resilience_0_1000 * 800), 0, 1000000000);
    int tox_rise = 0;
    for(int k = 1; k < n; k++) {
        if(GovClampInt32(tl.epochs[k].toxicity_ms, 0, 100000) > GovClampInt32(tl.epochs[k - 1].toxicity_ms, 0, 100000))
            tox_rise++;
    }
    out.collapse_awareness_milli = GovClampInt32(GovSaturatingAdd32(tox_rise * 90000 / GovClampInt32(n, 1, 1000000), eco.collapse_exposure_milli / 2), 0, 1000000000);
    out.resilience_awareness_milli = GovClampInt32(GovSaturatingAdd32(rp.summary.collapse_resistance_0_1000 * 900, rp.summary.recovery_elasticity_0_1000 * 700), 0, 1000000000);
    out.ecological_awareness_milli = GovClampInt32(GovSaturatingAdd32(eco.ecosystem_resilience_milli / 2, eco.biodiversity_index_milli / 2), 0, 1000000000);
    out.temporal_awareness_milli = GovClampInt32(GovSaturatingAdd32(tmp.cumulative_temporal_pressure_milli / 3, tmp.decay_composite_milli / 2), 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_CON_AWARE_V1_MQH__
