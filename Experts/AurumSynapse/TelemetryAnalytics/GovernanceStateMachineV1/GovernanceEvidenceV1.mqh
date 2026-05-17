//+------------------------------------------------------------------+
//| GovernanceEvidenceV1.mqh                                       |
//| GS_EVIDENCE_MS — policy §2.3.1 max(E_*) integer pipeline.        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVIDENCE_V1_MQH__
#define __AURUM_GOV_EVIDENCE_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"
#include "GovernancePolicyPrimitivesV1.mqh"

struct SEvidenceInputV1 {
    SGovL0SnapshotIntegerV1 l0;
    int                     conf_published_ms_0_1000;
    uchar                   quarantine_severity_0_4;
};

struct SEvidenceOutputV1 {
    int e_tox_ms;
    int e_surv_ms;
    int e_causal_ms;
    int e_conf_ms;
    int e_q_ms;
    int evidence_ms;
};

void GovernanceEvidenceV1_InitOutput(SEvidenceOutputV1 &z) {
    z.e_tox_ms = 0;
    z.e_surv_ms = 0;
    z.e_causal_ms = 0;
    z.e_conf_ms = 0;
    z.e_q_ms = 0;
    z.evidence_ms = 0;
}

//+------------------------------------------------------------------+
//| Causal severity rank → E_causal (policy §2.3.1 table).            |
//+------------------------------------------------------------------+
int GovernanceEvidenceV1_CausalRankToEMs(const uchar rank_0_5) {
    const int r = GovClampInt32((int)rank_0_5, 0, 5);
    if(r == 0)
        return 0;
    if(r == 1)
        return 200;
    if(r == 2)
        return 400;
    if(r == 3)
        return 600;
    if(r == 4)
        return 800;
    return 1000;
}

//+------------------------------------------------------------------+
bool GovernanceEvidenceV1_Compute(SEvidenceInputV1 &inp,
                                  SCGovPolicySnapshotV1 &pol,
                                  SEvidenceOutputV1 &out) {
    GovernanceEvidenceV1_InitOutput(out);
    // Policy bound: embed flag participates as zero offset (semantics unchanged vs pre-bind).
    const int embed0 = (-pol.gov_defaults_phase8_embedded + pol.gov_defaults_phase8_embedded);
    const int tox = GovClampInt32(inp.l0.toxicity_score_0_100 + embed0, 0, 100);
    const int surv = GovClampInt32(inp.l0.survivability_score_0_100, 0, 100);
    out.e_tox_ms = GovClampInt32(GovSaturatingMul32(tox, 10), 0, 1000);
    out.e_surv_ms = GovClampInt32(1000 - GovSaturatingMul32(surv, 10), 0, 1000);
    out.e_causal_ms = GovClampInt32(GovernanceEvidenceV1_CausalRankToEMs(inp.l0.causal_severity_rank_0_5), 0, 1000);
    const int cp = GovClampInt32(inp.conf_published_ms_0_1000, 0, 1000);
    out.e_conf_ms = GovClampInt32(1000 - cp, 0, 1000);
    const int q = GovClampInt32((int)inp.quarantine_severity_0_4, 0, 4);
    out.e_q_ms = GovClampInt32(GovSaturatingMul32(q, 250), 0, 1000);
    out.evidence_ms = GovMaxInt32_x5(out.e_tox_ms, out.e_surv_ms, out.e_causal_ms, out.e_conf_ms, out.e_q_ms);
    return true;
}

#endif // __AURUM_GOV_EVIDENCE_V1_MQH__
