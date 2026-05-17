//+------------------------------------------------------------------+
//| GovernanceEvidenceIntegrationV1.mqh                             |
//| GOVERNANCE_EVIDENCE_INTEGRATION_V1 — orchestration + L0 bridge  |
//| Consumes immutable analytics snapshots only (read-only).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVIDENCE_INTEGRATION_V1_MQH__
#define __AURUM_GOV_EVIDENCE_INTEGRATION_V1_MQH__

#include "../PositionRollupV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "GovernanceEvidenceNormalizerV1.mqh"
#include "GovernanceEvidenceFusionV1.mqh"
#include "GovernanceRegimeClassifierV1.mqh"
#include "GovernanceCampaignMemoryV1.mqh"
#include "GovernanceEvidenceAttribTelemetryV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceShadowTickV1.mqh"

struct SGovShadowTickAuxOutV1 {
    int                         causal_explanation_code;
    ENUM_GOV_MARKET_REGIME_V1 market_regime_after;
    ENUM_TOXICITY_STATE_V1      tox_state;
    ENUM_SURVIVABILITY_STATE_V1 surv_state;
    string                      evidence_fp8_hex8;
    SGovL0RuntimeEvidenceV1     rt;
};

void SGovShadowTickAuxOutV1_Init(SGovShadowTickAuxOutV1 &a) {
    a.causal_explanation_code = 0;
    a.market_regime_after = GOV_MR_V1_INVALID;
    a.tox_state = TOX_V1_INVALID;
    a.surv_state = SURVIVE_V1_INVALID;
    a.evidence_fp8_hex8 = "";
    // rt left undefined until Build fills via assignment
}

//+------------------------------------------------------------------+
ulong GovEvidenceIntegrationV1_FingerprintMix(const SGovL0RuntimeEvidenceV1 &e) {
    ulong h = 2166136261;
    h ^= e.lifecycle_id;
    h ^= (ulong)(long)e.toxicity_score_ms * (ulong)1315423911;
    h ^= (ulong)(long)e.survivability_score_ms * (ulong)374761393;
    h ^= (ulong)(long)e.causal_pressure_ms * (ulong)2654435761;
    h ^= (ulong)(long)e.structural_instability_ms * (ulong)2246822519;
    h ^= (ulong)(long)e.volatility_toxicity_ms * (ulong)3266489917;
    h ^= (ulong)(long)e.campaign_duration_epochs * (ulong)668265263;
    return h;
}

bool GovEvidenceIntegrationV1_FingerprintHex8(const SGovL0RuntimeEvidenceV1 &e, string &out8) {
    const ulong v = GovEvidenceIntegrationV1_FingerprintMix(e);
    const string hex = "0123456789abcdef";
    out8 = "";
    for(int i = 7; i >= 0; i--) {
        const int nibble = (int)((v >> (i * 4)) & 15);
        out8 += StringSubstr(hex, nibble, 1);
    }
    return (StringLen(out8) == 8);
}

//+------------------------------------------------------------------+
void GovEvidenceIntegrationV1_MapRuntimeEvidenceToL0(const SGovL0RuntimeEvidenceV1 &in_ev,
                                                      const SGovernanceCampaignMemoryV1 &mem,
                                                      const ulong gov_epoch,
                                                      SGovL0SnapshotIntegerV1 &l0) {
    GovernanceTypesV1_InitSnapshot(l0);
    l0.gov_epoch = gov_epoch;
    l0.lifecycle_campaign_id = in_ev.lifecycle_id;
    l0.toxicity_score_0_100 = GovClampInt32(in_ev.toxicity_score_ms / 100, 0, 100);
    l0.survivability_score_0_100 = GovClampInt32(in_ev.survivability_score_ms / 100, 0, 100);
    l0.conf_raw_ms_0_1000 = GovClampInt32(in_ev.governance_confidence_ms / 10, 0, 1000);
    l0.regime_score_ms_0_1000 = GovClampInt32(in_ev.execution_quality_ms / 10, 0, 1000);
    l0.eq_ms_0_1000 = GovClampInt32(in_ev.execution_quality_ms / 10, 0, 1000);
    l0.instability_persistence_ms = GovClampInt32(in_ev.volatility_toxicity_ms / 10, 0, 1000);
    l0.recovery_instability_ms_0_1000 = GovClampInt32(in_ev.recovery_instability_ms / 10, 0, 1000);
    l0.execution_degradation_ms_0_1000 = GovClampInt32((GOV_EVID_MILLI_MAX - in_ev.execution_quality_ms) / 10, 0, 1000);
    l0.campaign_pressure_ms_0_1000 = GovClampInt32(in_ev.drawdown_pressure_ms / 10, 0, 1000);
    l0.drawdown_pressure_ms_0_1000 = GovClampInt32(in_ev.drawdown_pressure_ms / 10, 0, 1000);
    l0.consecutive_toxic_lifecycle = GovClampInt32(mem.consecutive_toxic_campaigns, 0, 1000000);
    const int rank = GovClampInt32(in_ev.causal_pressure_ms / 2000, 0, 5);
    l0.causal_severity_rank_0_5 = (uchar)rank;
    l0.fake_recovery_flag_0_1 = (uchar)((in_ev.recovery_instability_ms >= 5000) ? 1 : 0);
    l0.deterioration_repetition = GovClampInt32(mem.structural_toxic_persistence, 0, 1000000);
}

//+------------------------------------------------------------------+
bool GovEvidenceIntegrationV1_BuildFromDealsUtf8(const string dealsUtf8Lf,
                                                const ulong evidence_epoch,
                                                SGovL0RuntimeEvidenceV1 &outRt,
                                                ushort &out_path,
                                                ENUM_GOV_DOMINANT_EVIDENCE_SRC_V1 &out_dom,
                                                int &out_tox_bits,
                                                int &out_surv_src,
                                                int &out_causal_code,
                                                ENUM_TOXICITY_STATE_V1 &out_tx,
                                                ENUM_SURVIVABILITY_STATE_V1 &out_sv,
                                                string &out_err) {
    out_err = "";
    SRollupDealStepV1 steps[];
    SRollupPositionCampaignV1 camp;
    SRollupGraphEdgeV1 edges[];
    if(!PositionRollupV1_BuildFromDealsUtf8Lf(dealsUtf8Lf, steps, camp, edges, out_err))
        return false;
    return GovernanceEvidenceFusionV1_FuseFromCampaign(camp, steps, evidence_epoch, outRt, out_path, out_dom,
                                                       out_tox_bits, out_surv_src, out_causal_code, out_tx, out_sv);
}

//+------------------------------------------------------------------+
bool GovEvidenceIntegrationV1_ShadowTickFromDealsUtf8(SGovernanceShadowContextV1 &ctx,
                                                      SGovernanceCampaignMemoryV1 &mem,
                                                      ENUM_GOV_MARKET_REGIME_V1 &io_prior_regime,
                                                      int &io_dwell_fragile,
                                                      int &io_dwell_toxic,
                                                      const string dealsUtf8Lf,
                                                      const string l0_fingerprint_sha256_hex,
                                                      string &out_telemetry_line,
                                                      string &out_gov_events_lines,
                                                      string &out_attrib_line,
                                                      SGovShadowTickAuxOutV1 &aux) {
    out_attrib_line = "";
    SGovShadowTickAuxOutV1_Init(aux);
    string err = "";
    SGovL0RuntimeEvidenceV1 rt;
    ushort path = 0;
    ENUM_GOV_DOMINANT_EVIDENCE_SRC_V1 dom = GOV_DOM_V1_NONE;
    int tb = 0, ss = 0, cc = 0;
    ENUM_TOXICITY_STATE_V1 tx = TOX_V1_INVALID;
    ENUM_SURVIVABILITY_STATE_V1 sv = SURVIVE_V1_INVALID;
    const ulong ep = ctx.next_epoch;
    if(!GovEvidenceIntegrationV1_BuildFromDealsUtf8(dealsUtf8Lf, ep, rt, path, dom, tb, ss, cc, tx, sv, err))
        return false;

    GovernanceCampaignMemoryV1_OnCampaignEpoch(mem, rt, tx);

    rt.consecutive_toxic_campaigns = GovClampInt32(mem.consecutive_toxic_campaigns, 0, 1000000);

    ENUM_GOV_MARKET_REGIME_V1 regime = GovernanceRegimeClassifierV1_Classify(rt, io_prior_regime, io_dwell_fragile, io_dwell_toxic);
    io_prior_regime = regime;

    string fp8 = "";
    if(!GovEvidenceIntegrationV1_FingerprintHex8(rt, fp8))
        return false;
    if(!GovEvidenceAttribTelemetryV1_FormatLine(rt, path, dom, tb, ss, cc, regime, fp8, tx, out_attrib_line))
        return false;

    SGovL0SnapshotIntegerV1 l0;
    GovEvidenceIntegrationV1_MapRuntimeEvidenceToL0(rt, mem, ep, l0);
    l0.causal_explanation_code = GovClampInt32(cc, -1000000, 1000000);

    if(!GovernanceShadowTickV1(ctx, l0, l0_fingerprint_sha256_hex, out_telemetry_line, out_gov_events_lines))
        return false;

    if(StringLen(out_attrib_line) > 0) {
        if(StringLen(out_gov_events_lines) > 0)
            out_gov_events_lines += "\n";
        out_gov_events_lines += out_attrib_line;
    }
    aux.causal_explanation_code = l0.causal_explanation_code;
    aux.market_regime_after = regime;
    aux.tox_state = tx;
    aux.surv_state = sv;
    aux.evidence_fp8_hex8 = fp8;
    aux.rt = rt;
    return true;
}

#endif // __AURUM_GOV_EVIDENCE_INTEGRATION_V1_MQH__
