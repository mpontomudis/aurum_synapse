//+------------------------------------------------------------------+
//| GovEvidenceFromToxicityV1.mqh                                  |
//| Adapter: TOXICITY_ANALYTICS_V1 → milli evidence.                |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVID_FROM_TOX_V1_MQH__
#define __AURUM_GOV_EVID_FROM_TOX_V1_MQH__

#include "../ToxicityAnalyticsV1.mqh"
#include "GovernanceL0RuntimeEvidenceV1.mqh"
#include "GovernanceEvidenceNormalizerV1.mqh"

void GovEvidenceFromToxicityV1_Apply(const SToxicityMetricsV1 &tx,
                                     SGovL0RuntimeEvidenceV1 &io) {
    io.toxicity_score_ms = GovEvidenceNormV1_FromScore0_100(tx.toxicity_score);
    io.volatility_toxicity_ms = GovEvidenceNormV1_FromUnitInterval(tx.instability_persistence);
    io.recovery_instability_ms = GovEvidenceNormV1_FromUnitInterval(tx.failed_recovery_intensity);
}

#endif // __AURUM_GOV_EVID_FROM_TOX_V1_MQH__
