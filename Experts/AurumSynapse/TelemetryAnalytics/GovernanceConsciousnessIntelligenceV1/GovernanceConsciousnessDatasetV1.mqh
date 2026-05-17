//+------------------------------------------------------------------+
//| GovernanceConsciousnessDatasetV1.mqh                          |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — datasets               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_DS_V1_MQH__
#define __AURUM_GOV_CON_DS_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

struct SGovIdentityProfileV1 {
    int identity_integrity_milli;
    int identity_fragmentation_milli;
    int identity_persistence_epochs;
    int identity_recovery_strength_milli;
    int governance_identity_id;
    string replay_identity_fingerprint;
    string policy_identity_fingerprint;
};

struct SGovCoherenceProfileV1 {
    int strategic_coherence_milli;
    int resilience_coherence_milli;
    int temporal_coherence_milli;
    int ecological_coherence_milli;
    int civilization_coherence_milli;
    int contradiction_pressure_milli;
    int instability_oscillation_milli;
    int fragmented_behavior_milli;
};

struct SGovMemoryIntegrityV1 {
    int replay_continuity_milli;
    int epoch_continuity_milli;
    int governance_memory_persistence_milli;
    int collapse_memory_retention_milli;
    int recovery_memory_stability_milli;
};

struct SGovAwarenessProfileV1 {
    int survivability_awareness_milli;
    int collapse_awareness_milli;
    int resilience_awareness_milli;
    int ecological_awareness_milli;
    int temporal_awareness_milli;
};

struct SGovCollapseAwarenessV1 {
    int collapse_trajectory_awareness_milli;
    int survivability_decay_awareness_milli;
    int ecological_collapse_awareness_milli;
    int civilization_instability_awareness_milli;
    int temporal_degradation_awareness_milli;
};

struct SGovSelfConsistencyV1 {
    int contradiction_score_milli;
    int recovery_consistency_milli;
    int intervention_consistency_milli;
    int containment_consistency_milli;
    int regime_continuity_consistency_milli;
};

struct SGovContinuityAwarenessV1 {
    int continuity_persistence_milli;
    int long_horizon_awareness_milli;
    int replay_continuity_stability_milli;
    int governance_survival_continuity_milli;
    int civilization_continuity_awareness_milli;
};

struct SGovConsciousnessSummaryV1 {
    int consciousness_window_id;
    string replay_hash;
    string policy_fingerprint;
    int consciousness_stability_milli;
    int integrity_index_milli;
    int coherence_index_milli;
    int awareness_index_milli;
    int memory_index_milli;
    int self_consistency_index_milli;
    int continuity_index_milli;
};

struct SGovConsciousnessComparisonV1 {
    int d_consciousness_stability_milli;
    int d_integrity_index_milli;
    int d_coherence_index_milli;
    int d_awareness_index_milli;
    int d_memory_index_milli;
    int d_self_consistency_index_milli;
    int d_continuity_index_milli;
};

void GovConDsV1_InitIdentity(SGovIdentityProfileV1 &o) {
    o.identity_integrity_milli = 0;
    o.identity_fragmentation_milli = 0;
    o.identity_persistence_epochs = 0;
    o.identity_recovery_strength_milli = 0;
    o.governance_identity_id = 0;
    o.replay_identity_fingerprint = "";
    o.policy_identity_fingerprint = "";
}

void GovConDsV1_InitCoherence(SGovCoherenceProfileV1 &o) {
    o.strategic_coherence_milli = 0;
    o.resilience_coherence_milli = 0;
    o.temporal_coherence_milli = 0;
    o.ecological_coherence_milli = 0;
    o.civilization_coherence_milli = 0;
    o.contradiction_pressure_milli = 0;
    o.instability_oscillation_milli = 0;
    o.fragmented_behavior_milli = 0;
}

void GovConDsV1_InitMemory(SGovMemoryIntegrityV1 &o) {
    o.replay_continuity_milli = 0;
    o.epoch_continuity_milli = 0;
    o.governance_memory_persistence_milli = 0;
    o.collapse_memory_retention_milli = 0;
    o.recovery_memory_stability_milli = 0;
}

void GovConDsV1_InitAware(SGovAwarenessProfileV1 &o) {
    o.survivability_awareness_milli = 0;
    o.collapse_awareness_milli = 0;
    o.resilience_awareness_milli = 0;
    o.ecological_awareness_milli = 0;
    o.temporal_awareness_milli = 0;
}

void GovConDsV1_InitCollapseAware(SGovCollapseAwarenessV1 &o) {
    o.collapse_trajectory_awareness_milli = 0;
    o.survivability_decay_awareness_milli = 0;
    o.ecological_collapse_awareness_milli = 0;
    o.civilization_instability_awareness_milli = 0;
    o.temporal_degradation_awareness_milli = 0;
}

void GovConDsV1_InitSelfCons(SGovSelfConsistencyV1 &o) {
    o.contradiction_score_milli = 0;
    o.recovery_consistency_milli = 0;
    o.intervention_consistency_milli = 0;
    o.containment_consistency_milli = 0;
    o.regime_continuity_consistency_milli = 0;
}

void GovConDsV1_InitContAware(SGovContinuityAwarenessV1 &o) {
    o.continuity_persistence_milli = 0;
    o.long_horizon_awareness_milli = 0;
    o.replay_continuity_stability_milli = 0;
    o.governance_survival_continuity_milli = 0;
    o.civilization_continuity_awareness_milli = 0;
}

void GovConDsV1_InitSummary(SGovConsciousnessSummaryV1 &o) {
    o.consciousness_window_id = 0;
    o.replay_hash = "";
    o.policy_fingerprint = "";
    o.consciousness_stability_milli = 0;
    o.integrity_index_milli = 0;
    o.coherence_index_milli = 0;
    o.awareness_index_milli = 0;
    o.memory_index_milli = 0;
    o.self_consistency_index_milli = 0;
    o.continuity_index_milli = 0;
}

void GovConDsV1_InitCmp(SGovConsciousnessComparisonV1 &o) {
    o.d_consciousness_stability_milli = 0;
    o.d_integrity_index_milli = 0;
    o.d_coherence_index_milli = 0;
    o.d_awareness_index_milli = 0;
    o.d_memory_index_milli = 0;
    o.d_self_consistency_index_milli = 0;
    o.d_continuity_index_milli = 0;
}

#endif // __AURUM_GOV_CON_DS_V1_MQH__
