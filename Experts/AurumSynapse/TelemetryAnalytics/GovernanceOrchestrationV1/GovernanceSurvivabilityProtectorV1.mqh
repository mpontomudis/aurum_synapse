//+------------------------------------------------------------------+
//| GovernanceSurvivabilityProtectorV1.mqh                         |
//| Capital survivability protection (integer-only triggers).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EXEC_SURV_PROTECT_V1_MQH__
#define __AURUM_GOV_EXEC_SURV_PROTECT_V1_MQH__

#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceL0RuntimeEvidenceV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceCampaignMemoryV1.mqh"
#include "../GovernanceEvidenceIntegrationV1/GovernanceRegimeClassifierV1.mqh"
#include "../SurvivabilityAnalyticsV1.mqh"

struct SGovSurvivabilityProtectOutputV1 {
    uchar survivability_emergency;
    uchar forced_flatten_required;
    int   risk_compression_milli;
};

void GovernanceSurvivabilityProtectorV1_InitOut(SGovSurvivabilityProtectOutputV1 &z) {
    z.survivability_emergency = 0;
    z.forced_flatten_required = 0;
    z.risk_compression_milli = 1000;
}

void GovernanceSurvivabilityProtectorV1_Evaluate(const uchar governance_state,
                                                const ENUM_GOV_MARKET_REGIME_V1 mr,
                                                const ENUM_SURVIVABILITY_STATE_V1 sv,
                                                const SGovL0RuntimeEvidenceV1 &rt,
                                                const SGovernanceCampaignMemoryV1 &mem,
                                                SGovSurvivabilityProtectOutputV1 &out) {
    GovernanceSurvivabilityProtectorV1_InitOut(out);
    const int surv_ms = GovClampInt32(rt.survivability_score_ms, 0, 1000000);
    const int ew = GovClampInt32(mem.survivability_decay_ewma, 0, 100);
    if(sv == SURVIVE_V1_CRITICAL || sv == SURVIVE_V1_TERMINATED || surv_ms < 1500 || ew < 12)
        out.survivability_emergency = 1;
    if(mr == GOV_MR_V1_STRUCTURAL_BREAKDOWN && surv_ms < 3500)
        out.survivability_emergency = 1;
    if(mem.lockdown_entry_count >= 2 && mem.survivability_decay_ewma < 25)
        out.survivability_emergency = 1;

    if(out.survivability_emergency != 0 &&
       (governance_state == (uchar)GOV_STATE_LOCKDOWN || mr == GOV_MR_V1_STRUCTURAL_BREAKDOWN || mem.lockdown_entry_count >= 2))
        out.forced_flatten_required = 1;

    out.risk_compression_milli = 1000;
    if(out.survivability_emergency != 0)
        out.risk_compression_milli = 600;
    if(sv == SURVIVE_V1_CRITICAL)
        out.risk_compression_milli = GovClampInt32(out.risk_compression_milli * 750 / 1000, 0, 1000000);
    if(mem.structural_toxic_persistence >= 6)
        out.risk_compression_milli = GovClampInt32(out.risk_compression_milli * 850 / 1000, 0, 1000000);
}

#endif // __AURUM_GOV_EXEC_SURV_PROTECT_V1_MQH__
