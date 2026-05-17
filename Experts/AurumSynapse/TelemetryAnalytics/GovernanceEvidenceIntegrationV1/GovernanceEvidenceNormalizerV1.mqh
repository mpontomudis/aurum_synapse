//+------------------------------------------------------------------+
//| GovernanceEvidenceNormalizerV1.mqh                             |
//| Deterministic clamp / scale to 0..10000 milli convention.       |
//| No locale, no float authority beyond observation conversion.     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVIDENCE_NORMALIZER_V1_MQH__
#define __AURUM_GOV_EVIDENCE_NORMALIZER_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

#define GOV_EVID_MILLI_MAX 10000

//+------------------------------------------------------------------+
int GovEvidenceNormV1_ClampMilli(const int v) {
    return GovClampInt32(v, 0, GOV_EVID_MILLI_MAX);
}

//+------------------------------------------------------------------+
//| Deterministic [0,1] double observation → milli (rounded half-up).|
//+------------------------------------------------------------------+
int GovEvidenceNormV1_FromUnitInterval(const double x) {
    if(x <= 0.0)
        return 0;
    if(x >= 1.0)
        return GOV_EVID_MILLI_MAX;
    const double scaled = x * (double)GOV_EVID_MILLI_MAX + 0.5;
    if(scaled >= (double)GOV_EVID_MILLI_MAX)
        return GOV_EVID_MILLI_MAX;
    return GovClampInt32((int)scaled, 0, GOV_EVID_MILLI_MAX);
}

//+------------------------------------------------------------------+
//| 0..100 integer score → 0..10000 milli (score * 100).             |
//+------------------------------------------------------------------+
int GovEvidenceNormV1_FromScore0_100(const int score_0_100) {
    const long v = (long)GovClampInt32(score_0_100, 0, 100) * 100L;
    return GovClampInt32((int)v, 0, GOV_EVID_MILLI_MAX);
}

//+------------------------------------------------------------------+
int GovEvidenceNormV1_SaturatingAddMilli(const int a, const int b) {
    const long s = (long)a + (long)b;
    if(s > (long)GOV_EVID_MILLI_MAX)
        return GOV_EVID_MILLI_MAX;
    if(s < 0L)
        return 0;
    return (int)s;
}

#endif // __AURUM_GOV_EVIDENCE_NORMALIZER_V1_MQH__
