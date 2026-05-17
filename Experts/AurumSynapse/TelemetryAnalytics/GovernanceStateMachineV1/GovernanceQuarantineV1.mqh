//+------------------------------------------------------------------+
//| GovernanceQuarantineV1.mqh                                     |
//| Quarantine severity — SKELETON.                                |
//| Normative: PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md §6            |
//| TODO: rules Q1–Q5 order, max candidate, dwell_q_on/off.          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_QUARANTINE_V1_MQH__
#define __AURUM_GOV_QUARANTINE_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"
#include "GovernancePolicyPrimitivesV1.mqh"

struct SQuarantineEvalInputV1 {
    SGovL0SnapshotIntegerV1 l0;
    uchar                    gs_wire_hint;
};

struct SQuarantineEvalOutputV1 {
    uchar severity;
    uchar reserved0;
    ushort reserved1;
};

void GovernanceQuarantineV1_InitOutput(SQuarantineEvalOutputV1 &z) {
    z.severity = 0;
    z.reserved0 = 0;
    z.reserved1 = 0;
}

bool GovernanceQuarantineV1_EvaluateShell(SQuarantineEvalInputV1 &inp,
                                          SCGovPolicySnapshotV1 &pol,
                                          SQuarantineEvalOutputV1 &out) {
    GovernanceQuarantineV1_InitOutput(out);
    out.severity = (uchar)GovClampInt32((int)inp.l0.quarantine_severity_0_4, 0, 4);
    return true;
}

#endif // __AURUM_GOV_QUARANTINE_V1_MQH__
