//+------------------------------------------------------------------+
//| GovernanceRegimeV1.mqh                                         |
//| Regime scores + band mapping — SKELETON.                         |
//| Normative: PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md §2.2, §8     |
//| TODO: REGIME_SCORE_MS, |Δ|≥30, dwell_regime=2.                   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_V1_MQH__
#define __AURUM_GOV_REGIME_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"

struct SRegimeEvalInputV1 {
    SGovL0SnapshotIntegerV1 l0;
};

struct SRegimeEvalOutputV1 {
    int                     regime_score_ms;
    ENUM_REGIME_STATE_V1    regime_state;
    int                     reserved0;
};

void GovernanceRegimeV1_InitOutput(SRegimeEvalOutputV1 &z) {
    z.regime_score_ms = 0;
    z.regime_state = REGIME_V1_INVALID;
    z.reserved0 = 0;
}

bool GovernanceRegimeV1_EvaluateShell(SRegimeEvalInputV1 &inp,
                                      SCGovPolicySnapshotV1 &pol,
                                      SRegimeEvalOutputV1 &out) {
    GovernanceRegimeV1_InitOutput(out);
    out.regime_state = REGIME_V1_INVALID;
    return true;
}

#endif // __AURUM_GOV_REGIME_V1_MQH__
