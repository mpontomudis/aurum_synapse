//+------------------------------------------------------------------+
//| GovernanceEvidenceIntegrationTypesV1.mqh                       |
//| Shared enums / bit masks — GOVERNANCE_EVIDENCE_INTEGRATION_V1   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVID_INTEGRATION_TYPES_V1_MQH__
#define __AURUM_GOV_EVID_INTEGRATION_TYPES_V1_MQH__

#define GOV_FUSION_V1_BIT_ROLLUP  0x0001
#define GOV_FUSION_V1_BIT_SURVIVE 0x0002
#define GOV_FUSION_V1_BIT_TOX     0x0004
#define GOV_FUSION_V1_BIT_CAUSAL  0x0008

enum ENUM_GOV_DOMINANT_EVIDENCE_SRC_V1 {
    GOV_DOM_V1_NONE = 0,
    GOV_DOM_V1_ROLLUP = 1,
    GOV_DOM_V1_SURVIVABILITY = 2,
    GOV_DOM_V1_TOXICITY = 3,
    GOV_DOM_V1_CAUSAL = 4
};

#endif // __AURUM_GOV_EVID_INTEGRATION_TYPES_V1_MQH__
