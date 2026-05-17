//+------------------------------------------------------------------+
//| GovernanceConsciousnessComparatorV1.mqh                         |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — diff                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_CMP_V1_MQH__
#define __AURUM_GOV_CON_CMP_V1_MQH__

#include "GovernanceConsciousnessDatasetV1.mqh"

bool GovConCmpV1_Diff(const SGovConsciousnessSummaryV1 &a, const SGovConsciousnessSummaryV1 &b, SGovConsciousnessComparisonV1 &out, string &out_err) {
    out_err = "";
    GovConDsV1_InitCmp(out);
    out.d_consciousness_stability_milli = GovSaturatingAdd32(a.consciousness_stability_milli, -b.consciousness_stability_milli);
    out.d_integrity_index_milli = GovSaturatingAdd32(a.integrity_index_milli, -b.integrity_index_milli);
    out.d_coherence_index_milli = GovSaturatingAdd32(a.coherence_index_milli, -b.coherence_index_milli);
    out.d_awareness_index_milli = GovSaturatingAdd32(a.awareness_index_milli, -b.awareness_index_milli);
    out.d_memory_index_milli = GovSaturatingAdd32(a.memory_index_milli, -b.memory_index_milli);
    out.d_self_consistency_index_milli = GovSaturatingAdd32(a.self_consistency_index_milli, -b.self_consistency_index_milli);
    out.d_continuity_index_milli = GovSaturatingAdd32(a.continuity_index_milli, -b.continuity_index_milli);
    return true;
}

#endif // __AURUM_GOV_CON_CMP_V1_MQH__
