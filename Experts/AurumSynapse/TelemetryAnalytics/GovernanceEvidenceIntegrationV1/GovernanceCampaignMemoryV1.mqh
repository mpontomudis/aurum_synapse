//+------------------------------------------------------------------+
//| GovernanceCampaignMemoryV1.mqh                               |
//| Deterministic rolling governance memory (NOT ML).              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CAMPAIGN_MEMORY_V1_MQH__
#define __AURUM_GOV_CAMPAIGN_MEMORY_V1_MQH__

#include "../ToxicityAnalyticsV1.mqh"
#include "GovernanceL0RuntimeEvidenceV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovernanceCampaignMemoryV1 {
    ulong last_lifecycle_id;
    int   consecutive_toxic_campaigns;
    int   lockdown_entry_count;
    int   recovery_failure_streak;
    int   structural_toxic_persistence;
    int   survivability_decay_ewma;
    uchar last_governance_state_wire;
    uchar last_market_regime_wire;
    uchar last_exec_quarantine_level;
    uchar last_survivability_emergency_flag;
    int   quarantine_escalation_count;
    int   toxic_regime_persist_epochs;
    int   survivability_emergency_escalation;
};

void GovernanceCampaignMemoryV1_Init(SGovernanceCampaignMemoryV1 &m) {
    m.last_lifecycle_id = 0;
    m.consecutive_toxic_campaigns = 0;
    m.lockdown_entry_count = 0;
    m.recovery_failure_streak = 0;
    m.structural_toxic_persistence = 0;
    m.survivability_decay_ewma = 0;
    m.last_governance_state_wire = 0;
    m.last_market_regime_wire = 0;
    m.last_exec_quarantine_level = 0;
    m.last_survivability_emergency_flag = 0;
    m.quarantine_escalation_count = 0;
    m.toxic_regime_persist_epochs = 0;
    m.survivability_emergency_escalation = 0;
}

//+------------------------------------------------------------------+
void GovernanceCampaignMemoryV1_OnCampaignEpoch(SGovernanceCampaignMemoryV1 &m,
                                                const SGovL0RuntimeEvidenceV1 &e,
                                                const ENUM_TOXICITY_STATE_V1 txSt) {
    if(e.lifecycle_id != m.last_lifecycle_id) {
        m.last_lifecycle_id = e.lifecycle_id;
        m.recovery_failure_streak = 0;
    }

    if(txSt == TOX_V1_UNSTABLE || txSt == TOX_V1_TOXIC || txSt == TOX_V1_COLLAPSING || txSt == TOX_V1_TERMINAL)
        m.consecutive_toxic_campaigns = GovSaturatingAdd32(m.consecutive_toxic_campaigns, 1);
    else if(txSt == TOX_V1_CLEAN || txSt == TOX_V1_WATCHLIST)
        m.consecutive_toxic_campaigns = 0;

    if(e.structural_instability_ms >= 5000)
        m.structural_toxic_persistence = GovSaturatingAdd32(m.structural_toxic_persistence, 1);
    else
        m.structural_toxic_persistence = GovSaturatingAdd32(m.structural_toxic_persistence, -1);
    m.structural_toxic_persistence = GovClampInt32(m.structural_toxic_persistence, 0, 1000000);

    const int surv = GovClampInt32(e.survivability_score_ms / 100, 0, 100);
    m.survivability_decay_ewma = GovClampInt32((7 * m.survivability_decay_ewma + 3 * surv) / 10, 0, 100);

    if(e.recovery_instability_ms >= 6000)
        m.recovery_failure_streak = GovSaturatingAdd32(m.recovery_failure_streak, 1);
    else
        m.recovery_failure_streak = GovSaturatingAdd32(m.recovery_failure_streak, -1);
    m.recovery_failure_streak = GovClampInt32(m.recovery_failure_streak, 0, 1000000);
}

#endif // __AURUM_GOV_CAMPAIGN_MEMORY_V1_MQH__
