//+------------------------------------------------------------------+
//| GovernanceConsciousnessExportV1.mqh                             |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — UTF-8 LF export         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_EXP_V1_MQH__
#define __AURUM_GOV_CON_EXP_V1_MQH__

#include "GovernanceConsciousnessDatasetV1.mqh"

string GovConExpV1_J5(const int a, const int b, const int c, const int d, const int e) {
    return IntegerToString(a) + "|" + IntegerToString(b) + "|" + IntegerToString(c) + "|" + IntegerToString(d) + "|" + IntegerToString(e);
}

string GovConExpV1_J4(const int a, const int b, const int c, const int d) {
    return IntegerToString(a) + "|" + IntegerToString(b) + "|" + IntegerToString(c) + "|" + IntegerToString(d);
}

bool GovConExpV1_Bundle(const SGovConsciousnessSummaryV1 &sum, const SGovIdentityProfileV1 &idp, const SGovCoherenceProfileV1 &coh, const SGovMemoryIntegrityV1 &mem, const SGovAwarenessProfileV1 &aw, const SGovCollapseAwarenessV1 &clp, const SGovSelfConsistencyV1 &sc, const SGovContinuityAwarenessV1 &ca, string &out_utf8, string &out_err) {
    out_err = "";
    const string ln0 = "GOV_CONSCIOUSNESS_V1|" + IntegerToString(sum.consciousness_window_id) + "|" + sum.replay_hash + "|" + sum.policy_fingerprint + "|" + IntegerToString(sum.consciousness_stability_milli) + "|" + IntegerToString(sum.integrity_index_milli) + "|" + IntegerToString(sum.coherence_index_milli) + "|" + IntegerToString(sum.awareness_index_milli) + "|" + IntegerToString(sum.memory_index_milli) + "|" + IntegerToString(sum.self_consistency_index_milli) + "|" + IntegerToString(sum.continuity_index_milli);
    const string ln1 = "GOV_IDENTITY_V1|" + GovConExpV1_J4(idp.identity_integrity_milli, idp.identity_fragmentation_milli, idp.identity_persistence_epochs, idp.identity_recovery_strength_milli) + "|" + IntegerToString(idp.governance_identity_id) + "|" + idp.replay_identity_fingerprint + "|" + idp.policy_identity_fingerprint;
    const string ln2 = "GOV_COHERENCE_V1|" + GovConExpV1_J5(coh.strategic_coherence_milli, coh.resilience_coherence_milli, coh.temporal_coherence_milli, coh.ecological_coherence_milli, coh.civilization_coherence_milli) + "|" + IntegerToString(coh.contradiction_pressure_milli) + "|" + IntegerToString(coh.instability_oscillation_milli) + "|" + IntegerToString(coh.fragmented_behavior_milli);
    const string ln3 = "GOV_MEMORY_V1|" + GovConExpV1_J5(mem.replay_continuity_milli, mem.epoch_continuity_milli, mem.governance_memory_persistence_milli, mem.collapse_memory_retention_milli, mem.recovery_memory_stability_milli);
    const string ln4 = "GOV_AWARENESS_V1|" + GovConExpV1_J5(aw.survivability_awareness_milli, aw.collapse_awareness_milli, aw.resilience_awareness_milli, aw.ecological_awareness_milli, aw.temporal_awareness_milli);
    const string ln5 = "GOV_COLLAPSE_AWARE_V1|" + GovConExpV1_J5(clp.collapse_trajectory_awareness_milli, clp.survivability_decay_awareness_milli, clp.ecological_collapse_awareness_milli, clp.civilization_instability_awareness_milli, clp.temporal_degradation_awareness_milli);
    const string ln6 = "GOV_SELF_CONSIST_V1|" + GovConExpV1_J5(sc.contradiction_score_milli, sc.recovery_consistency_milli, sc.intervention_consistency_milli, sc.containment_consistency_milli, sc.regime_continuity_consistency_milli);
    const string ln7 = "GOV_CONTINUITY_AWARE_V1|" + GovConExpV1_J5(ca.continuity_persistence_milli, ca.long_horizon_awareness_milli, ca.replay_continuity_stability_milli, ca.governance_survival_continuity_milli, ca.civilization_continuity_awareness_milli);
    out_utf8 = ln0 + "\n" + ln1 + "\n" + ln2 + "\n" + ln3 + "\n" + ln4 + "\n" + ln5 + "\n" + ln6 + "\n" + ln7;
    return true;
}

#endif // __AURUM_GOV_CON_EXP_V1_MQH__
