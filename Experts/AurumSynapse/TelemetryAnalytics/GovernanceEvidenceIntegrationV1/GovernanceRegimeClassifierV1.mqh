//+------------------------------------------------------------------+
//| GovernanceRegimeClassifierV1.mqh                               |
//| Market regime from fused evidence only (integer thresholds).    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_CLASSIFIER_V1_MQH__
#define __AURUM_GOV_REGIME_CLASSIFIER_V1_MQH__

#include "GovernanceL0RuntimeEvidenceV1.mqh"
#include "GovernanceEvidenceNormalizerV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

enum ENUM_GOV_MARKET_REGIME_V1 {
    GOV_MR_V1_INVALID = 0,
    GOV_MR_V1_NORMAL = 1,
    GOV_MR_V1_FRAGILE = 2,
    GOV_MR_V1_TOXIC = 3,
    GOV_MR_V1_STRUCTURAL_BREAKDOWN = 4,
    GOV_MR_V1_RECOVERY_WINDOW = 5
};

//+------------------------------------------------------------------+
//| Hysteresis: pass prior regime + dwell counter (epochs).         |
//+------------------------------------------------------------------+
ENUM_GOV_MARKET_REGIME_V1 GovernanceRegimeClassifierV1_Classify(const SGovL0RuntimeEvidenceV1 &e,
                                                                const ENUM_GOV_MARKET_REGIME_V1 prior,
                                                                int &io_dwell_fragile,
                                                                int &io_dwell_toxic) {
    const int tox = GovEvidenceNormV1_ClampMilli(e.toxicity_score_ms);
    const int str = GovEvidenceNormV1_ClampMilli(e.structural_instability_ms);
    const int surv = GovEvidenceNormV1_ClampMilli(e.survivability_score_ms);

    ENUM_GOV_MARKET_REGIME_V1 raw = GOV_MR_V1_NORMAL;
    if(str >= 7000 || tox >= 8500)
        raw = GOV_MR_V1_STRUCTURAL_BREAKDOWN;
    else if(tox >= 6500)
        raw = GOV_MR_V1_TOXIC;
    else if(tox >= 4000 || surv <= 2500)
        raw = GOV_MR_V1_FRAGILE;
    else if(surv >= 7500 && tox <= 2500)
        raw = GOV_MR_V1_RECOVERY_WINDOW;
    else
        raw = GOV_MR_V1_NORMAL;

    if(raw == GOV_MR_V1_FRAGILE) {
        io_dwell_fragile = GovClampInt32(io_dwell_fragile + 1, 0, 1000000);
        io_dwell_toxic = 0;
    } else if(raw == GOV_MR_V1_TOXIC || raw == GOV_MR_V1_STRUCTURAL_BREAKDOWN) {
        io_dwell_toxic = GovClampInt32(io_dwell_toxic + 1, 0, 1000000);
        io_dwell_fragile = 0;
    } else {
        io_dwell_fragile = 0;
        io_dwell_toxic = 0;
    }

    if(raw == GOV_MR_V1_FRAGILE && prior == GOV_MR_V1_NORMAL && io_dwell_fragile < 2)
        return GOV_MR_V1_NORMAL;
    if((raw == GOV_MR_V1_TOXIC || raw == GOV_MR_V1_STRUCTURAL_BREAKDOWN) && prior == GOV_MR_V1_FRAGILE && io_dwell_toxic < 2)
        return GOV_MR_V1_FRAGILE;

    return raw;
}

#endif // __AURUM_GOV_REGIME_CLASSIFIER_V1_MQH__
