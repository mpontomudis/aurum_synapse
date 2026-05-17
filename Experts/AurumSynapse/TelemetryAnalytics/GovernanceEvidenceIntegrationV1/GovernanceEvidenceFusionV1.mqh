//+------------------------------------------------------------------+
//| GovernanceEvidenceFusionV1.mqh                                 |
//| Deterministic fusion: precedence TOX > CAUSAL > SURV > ROLLUP   |
//| for dominance; explain codes are integer enumerants (no ML).      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVIDENCE_FUSION_V1_MQH__
#define __AURUM_GOV_EVIDENCE_FUSION_V1_MQH__

#include "GovernanceEvidenceIntegrationTypesV1.mqh"
#include "../PositionRollupV1.mqh"
#include "../SurvivabilityAnalyticsV1.mqh"
#include "../ToxicityAnalyticsV1.mqh"
#include "../CausalValidationLayerV1.mqh"
#include "GovernanceL0RuntimeEvidenceV1.mqh"
#include "GovernanceEvidenceNormalizerV1.mqh"
#include "GovEvidenceFromRollupV1.mqh"
#include "GovEvidenceFromSurvivabilityV1.mqh"
#include "GovEvidenceFromToxicityV1.mqh"
#include "GovEvidenceFromCausalValidationV1.mqh"

//+------------------------------------------------------------------+
bool GovernanceEvidenceFusionV1_FuseFromCampaign(const SRollupPositionCampaignV1 &camp,
                                                 const SRollupDealStepV1 &steps[],
                                                 const ulong evidence_epoch,
                                                 SGovL0RuntimeEvidenceV1 &out,
                                                 ushort &out_fusion_path,
                                                 ENUM_GOV_DOMINANT_EVIDENCE_SRC_V1 &out_dom,
                                                 int &out_dom_toxicity_factor_bits,
                                                 int &out_surv_collapse_src,
                                                 int &out_causal_escalation_code,
                                                 ENUM_TOXICITY_STATE_V1 &out_tx_state,
                                                 ENUM_SURVIVABILITY_STATE_V1 &out_sv_state) {
    GovernanceL0RuntimeEvidenceV1_Init(out);
    out_fusion_path = 0;
    out_dom = GOV_DOM_V1_NONE;
    out_dom_toxicity_factor_bits = 0;
    out_surv_collapse_src = 0;
    out_causal_escalation_code = 0;
    out_tx_state = TOX_V1_INVALID;
    out_sv_state = SURVIVE_V1_INVALID;
    out.evidence_timestamp_epoch = evidence_epoch;

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

    SCausalDiagnosticsV1 cd;
    if(!CausalValidationLayerV1_AnalyzeCampaign(camp, steps, cd))
        return false;

    out_tx_state = txSt;
    out_sv_state = sv;

    out_fusion_path = (ushort)(GOV_FUSION_V1_BIT_ROLLUP | GOV_FUSION_V1_BIT_SURVIVE | GOV_FUSION_V1_BIT_TOX | GOV_FUSION_V1_BIT_CAUSAL);

    GovEvidenceFromRollupV1_Apply(camp, out);
    GovEvidenceFromSurvivabilityV1_Apply(sm, out);
    GovEvidenceFromToxicityV1_Apply(tx, out);
    GovEvidenceFromCausalValidationV1_Apply(cd, out);

    out.toxicity_score_ms = GovEvidenceNormV1_ClampMilli(out.toxicity_score_ms);
    out.survivability_score_ms = GovEvidenceNormV1_ClampMilli(out.survivability_score_ms);
    out.execution_quality_ms = GovEvidenceNormV1_ClampMilli(out.execution_quality_ms);
    out.recovery_instability_ms = GovEvidenceNormV1_ClampMilli(out.recovery_instability_ms);
    out.causal_pressure_ms = GovEvidenceNormV1_ClampMilli(out.causal_pressure_ms);
    out.volatility_toxicity_ms = GovEvidenceNormV1_ClampMilli(out.volatility_toxicity_ms);
    out.structural_instability_ms = GovEvidenceNormV1_ClampMilli(out.structural_instability_ms);
    out.drawdown_pressure_ms = GovEvidenceNormV1_ClampMilli(out.drawdown_pressure_ms);
    out.governance_confidence_ms = GovEvidenceNormV1_ClampMilli(out.governance_confidence_ms);

    out_surv_collapse_src = (int)sv;
    out_causal_escalation_code = (int)cd.causal_class;

    out_dom_toxicity_factor_bits = 0;
    if(tx.flag_spiral_deterioration)
        out_dom_toxicity_factor_bits |= 1;
    if(tx.flag_fake_recovery)
        out_dom_toxicity_factor_bits |= 2;
    if(tx.flag_panic_unwind)
        out_dom_toxicity_factor_bits |= 4;

    const int press_tox = GovEvidenceNormV1_SaturatingAddMilli(out.toxicity_score_ms, out.volatility_toxicity_ms);
    const int press_cau = GovEvidenceNormV1_SaturatingAddMilli(out.causal_pressure_ms, out.structural_instability_ms);
    const int press_sur = GovEvidenceNormV1_ClampMilli(GOV_EVID_MILLI_MAX - out.survivability_score_ms);

    if(press_tox >= press_cau && press_tox >= press_sur)
        out_dom = GOV_DOM_V1_TOXICITY;
    else if(press_cau >= press_sur)
        out_dom = GOV_DOM_V1_CAUSAL;
    else if(press_sur >= press_tox)
        out_dom = GOV_DOM_V1_SURVIVABILITY;
    else
        out_dom = GOV_DOM_V1_ROLLUP;

    return true;
}

#endif // __AURUM_GOV_EVIDENCE_FUSION_V1_MQH__
