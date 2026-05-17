//+------------------------------------------------------------------+
//| GovEvidenceFromCausalValidationV1.mqh                           |
//| Adapter: CAUSAL_VALIDATION_LAYER_V1 → milli evidence.           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVID_FROM_CAUSAL_V1_MQH__
#define __AURUM_GOV_EVID_FROM_CAUSAL_V1_MQH__

#include "../CausalValidationLayerV1.mqh"
#include "GovernanceL0RuntimeEvidenceV1.mqh"
#include "GovernanceEvidenceNormalizerV1.mqh"

void GovEvidenceFromCausalValidationV1_Apply(const SCausalDiagnosticsV1 &d,
                                             SGovL0RuntimeEvidenceV1 &io) {
    io.causal_pressure_ms = GovEvidenceNormV1_FromScore0_100(d.causal_confidence);
    int struct_ms = 0;
    if(d.structural_heuristic_triggered)
        struct_ms = GovEvidenceNormV1_SaturatingAddMilli(struct_ms, 6000);
    if(d.synthetic_spiral_triggered)
        struct_ms = GovEvidenceNormV1_SaturatingAddMilli(struct_ms, 3500);
    if(d.deterioration_mode == DET_MODE_V1_SPIRAL)
        struct_ms = GovEvidenceNormV1_SaturatingAddMilli(struct_ms, 2500);
    io.structural_instability_ms = GovEvidenceNormV1_ClampMilli(struct_ms);
    io.governance_confidence_ms = GovEvidenceNormV1_FromScore0_100(d.causal_confidence);
}

#endif // __AURUM_GOV_EVID_FROM_CAUSAL_V1_MQH__
