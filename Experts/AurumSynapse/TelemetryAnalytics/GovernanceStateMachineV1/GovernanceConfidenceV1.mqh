//+------------------------------------------------------------------+
//| GovernanceConfidenceV1.mqh                                     |
//| CONF_EWMA / CONF_PUBLISHED — policy §4.2–§4.3 (integer).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CONFIDENCE_V1_MQH__
#define __AURUM_GOV_CONFIDENCE_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"
#include "GovernancePolicyPrimitivesV1.mqh"

struct SConfidenceEvalInputV1 {
    SGovL0SnapshotIntegerV1 l0;
};

struct SConfidenceEvalOutputV1 {
    int                  conf_raw_ms;
    int                  conf_ewma_ms;
    int                  conf_published_ms;
    ENUM_CONF_STATE_V1 conf_state;
};

void GovernanceConfidenceV1_InitOutput(SConfidenceEvalOutputV1 &z) {
    z.conf_raw_ms = 0;
    z.conf_ewma_ms = 0;
    z.conf_published_ms = 0;
    z.conf_state = CONF_V1_INVALID;
}

//+------------------------------------------------------------------+
void GovernanceConfidenceV1_MapPublishedToState(const int pub_ms, ENUM_CONF_STATE_V1 &out_state) {
    const int p = GovClampInt32(pub_ms, 0, 1000);
    if(p < 250)
        out_state = CONF_V1_CRITICAL;
    else if(p < 450)
        out_state = CONF_V1_LOW;
    else if(p < 700)
        out_state = CONF_V1_MEDIUM;
    else
        out_state = CONF_V1_HIGH;
}

//+------------------------------------------------------------------+
bool GovernanceConfidenceV1_StepEwmaPublish(SCGovPolicySnapshotV1 &pol,
                                           const int conf_raw_ms_in,
                                           int &io_ewma_ms,
                                           int &io_pub_ms,
                                           int &io_publish_dwell_ctr,
                                           SConfidenceEvalOutputV1 &out) {
    GovernanceConfidenceV1_InitOutput(out);
    const int an = GovClampInt32(pol.gov_conf_alpha_num, 1, 1000);
    const int ad = GovClampInt32(pol.gov_conf_alpha_den, 1, 1000);
    const int stab = GovClampInt32(pol.gov_conf_stab_delta_ms, 1, 1000);
    const int pd = GovClampInt32(pol.gov_conf_publish_dwell, 1, 1000);

    const int raw = GovClampInt32(conf_raw_ms_in, 0, 1000);
    out.conf_raw_ms = raw;

    if(io_ewma_ms < 0) {
        io_ewma_ms = raw;
        io_pub_ms = raw;
    } else {
        const long num = (long)an * (long)io_ewma_ms + (long)(ad - an) * (long)raw;
        io_ewma_ms = (int)GovFloorDivSigned64(num, (long)ad);
        io_ewma_ms = GovClampInt32(io_ewma_ms, 0, 1000);
    }
    out.conf_ewma_ms = io_ewma_ms;

    if(MathAbs(io_ewma_ms - io_pub_ms) >= stab) {
        io_publish_dwell_ctr++;
        if(io_publish_dwell_ctr >= pd) {
            io_pub_ms = io_ewma_ms;
            io_publish_dwell_ctr = 0;
        }
    } else
        io_publish_dwell_ctr = 0;

    out.conf_published_ms = io_pub_ms;
    GovernanceConfidenceV1_MapPublishedToState(out.conf_published_ms, out.conf_state);
    return true;
}

//+------------------------------------------------------------------+
bool GovernanceConfidenceV1_EvaluateShell(SConfidenceEvalInputV1 &inp,
                                          SCGovPolicySnapshotV1 &pol,
                                          SConfidenceEvalOutputV1 &out) {
    GovernanceConfidenceV1_InitOutput(out);
    return true;
}

#endif // __AURUM_GOV_CONFIDENCE_V1_MQH__
