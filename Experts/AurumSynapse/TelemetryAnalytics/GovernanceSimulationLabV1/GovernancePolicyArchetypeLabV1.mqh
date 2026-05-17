//+------------------------------------------------------------------+
//| GovernancePolicyArchetypeLabV1.mqh                           |
//| Deterministic arch → stress lane mapping (no policy mutation).  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ARCH_LAB_V1_MQH__
#define __AURUM_GOV_ARCH_LAB_V1_MQH__

#include "GovernanceSimulationDatasetV1.mqh"

int GovArchLabV1_ToStress(const int arch_id) {
    if(arch_id == GOV_ARCH_V1_SURV_FIRST)
        return GOV_STRS_V1_NONE;
    if(arch_id == GOV_ARCH_V1_AGGR_CONT)
        return GOV_STRS_V1_QUAR_ESCAL;
    if(arch_id == GOV_ARCH_V1_QUAR_HEAVY)
        return GOV_STRS_V1_QUAR_ESCAL;
    if(arch_id == GOV_ARCH_V1_THR_HEAVY)
        return GOV_STRS_V1_CHRONIC_TOX;
    if(arch_id == GOV_ARCH_V1_REC_CONSERV)
        return GOV_STRS_V1_EXEC_SUPP;
    if(arch_id == GOV_ARCH_V1_FLAT_AGGR)
        return GOV_STRS_V1_FLAT_BURST;
    return GOV_STRS_V1_NONE;
}

#endif // __AURUM_GOV_ARCH_LAB_V1_MQH__
