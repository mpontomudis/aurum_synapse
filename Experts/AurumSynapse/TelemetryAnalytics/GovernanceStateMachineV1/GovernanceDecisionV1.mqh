//+------------------------------------------------------------------+
//| GovernanceDecisionV1.mqh                                       |
//| Map GS → decision vector from immutable policy snapshot only.    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_DECISION_V1_MQH__
#define __AURUM_GOV_DECISION_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"
#include "GovernancePolicyPrimitivesV1.mqh"

//+------------------------------------------------------------------+
bool GovDecisionV1_FromPolicy(const uchar gs,
                              SCGovPolicySnapshotV1 &pol,
                              const int causal_explanation_code,
                              SGovernanceDecisionOutputV1 &out) {
    GovernanceTypesV1_InitDecision(out);
    uchar g = gs;
    int ix = (int)g - 1;
    if(ix < 0 || ix >= GOV_V1_GS_SLOT_COUNT) {
        g = (uchar)GOV_STATE_LOCKDOWN;
        ix = (int)GOV_STATE_LOCKDOWN - 1;
    }
    out.target_gs = g;
    out.risk_mult_milli = GovClampInt32(pol.gov_gs_risk_milli[ix], 0, 1000000);
    out.execution_allowed = pol.gov_gs_exec_allowed[ix] != 0 ? (uchar)1 : (uchar)0;
    out.recovery_allowed = pol.gov_gs_recovery_allowed[ix] != 0 ? (uchar)1 : (uchar)0;
    out.averaging_allowed = pol.gov_gs_avg_allowed[ix] != 0 ? (uchar)1 : (uchar)0;
    out.max_campaign_depth = GovClampInt32(pol.gov_gs_max_campaign_depth[ix], 0, 1000000);
    out.throttle_level_ms = GovClampInt32(pol.gov_gs_throttle_ms[ix], 0, 1000000);
    out.confidence_attn_milli = GovClampInt32(pol.gov_gs_conf_attn_milli[ix], 0, 1000000);
    out.causal_explanation_code = causal_explanation_code;
    return true;
}

#endif // __AURUM_GOV_DECISION_V1_MQH__
