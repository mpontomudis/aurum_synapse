//+------------------------------------------------------------------+
//| GovernanceVisualizationContractsV1.mqh                      |
//| Frozen visualization substrate (contracts only; no UI code).   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_VIS_CONTRACTS_V1_MQH__
#define __AURUM_GOV_VIS_CONTRACTS_V1_MQH__

#define GOV_VIS_V1_SCHEMA_MAJOR 1
#define GOV_VIS_V1_SCHEMA_MINOR 0

enum ENUM_GOV_VIS_PANEL_V1 {
    GOV_VIS_PANEL_V1_TIMELINE = 0,
    GOV_VIS_PANEL_V1_HEATMAP = 1,
    GOV_VIS_PANEL_V1_CAUSAL_TRACE = 2,
    GOV_VIS_PANEL_V1_POLICY_DELTA = 3,
    GOV_VIS_PANEL_V1_CONTAINMENT = 4
};

enum ENUM_GOV_VIS_AXIS_V1 {
    GOV_VIS_AXIS_V1_EPOCH = 0,
    GOV_VIS_AXIS_V1_CAMPAIGN = 1,
    GOV_VIS_AXIS_V1_METRIC = 2
};

#endif // __AURUM_GOV_VIS_CONTRACTS_V1_MQH__
