//+------------------------------------------------------------------+
//| GovEvidenceFromSurvivabilityV1.mqh                               |
//| Adapter: SURVIVABILITY_ANALYTICS_V1 → milli evidence.           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVID_FROM_SURVIVE_V1_MQH__
#define __AURUM_GOV_EVID_FROM_SURVIVE_V1_MQH__

#include "../SurvivabilityAnalyticsV1.mqh"
#include "GovernanceL0RuntimeEvidenceV1.mqh"
#include "GovernanceEvidenceNormalizerV1.mqh"

void GovEvidenceFromSurvivabilityV1_Apply(const SSurvivabilityMetricsV1 &m,
                                          SGovL0RuntimeEvidenceV1 &io) {
    io.survivability_score_ms = GovEvidenceNormV1_FromScore0_100(m.survivability_score);
    io.execution_quality_ms = GovEvidenceNormV1_FromUnitInterval(1.0 - MathMin(m.exposure_concentration, 1.0));
}

#endif // __AURUM_GOV_EVID_FROM_SURVIVE_V1_MQH__
