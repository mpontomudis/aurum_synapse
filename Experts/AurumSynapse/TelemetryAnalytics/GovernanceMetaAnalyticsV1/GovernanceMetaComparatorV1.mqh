//+------------------------------------------------------------------+
//| GovernanceMetaComparatorV1.mqh                                |
//| Deterministic deltas across meta snapshots (immutable inputs).   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_META_COMPARATOR_V1_MQH__
#define __AURUM_GOV_META_COMPARATOR_V1_MQH__

#include "GovernanceMetaAnalyticsDatasetV1.mqh"

struct SGovMetaComparatorDeltaV1 {
    int d_governance_health_index;
    int d_replay_stability;
    int d_containment_quality;
    int d_survivability_preservation;
    int d_incident_freq_per_1000;
    int d_toxic_spiral_freq_per_1000;
    int d_fingerprint_flags_xor;
    int d_archetype_primary;
};

void GovernanceMetaComparatorV1_InitDelta(SGovMetaComparatorDeltaV1 &d) {
    d.d_governance_health_index = 0;
    d.d_replay_stability = 0;
    d.d_containment_quality = 0;
    d.d_survivability_preservation = 0;
    d.d_incident_freq_per_1000 = 0;
    d.d_toxic_spiral_freq_per_1000 = 0;
    d.d_fingerprint_flags_xor = 0;
    d.d_archetype_primary = 0;
}

void GovernanceMetaComparatorV1_CompareHealth(const SGovMetaGovernanceHealthV1 &a, const SGovMetaGovernanceHealthV1 &b, SGovMetaComparatorDeltaV1 &out) {
    out.d_governance_health_index = GovSaturatingAdd32(a.governance_health_index_0_1000, -b.governance_health_index_0_1000);
    out.d_replay_stability = GovSaturatingAdd32(a.replay_stability_0_1000, -b.replay_stability_0_1000);
    out.d_containment_quality = GovSaturatingAdd32(a.containment_quality_0_1000, -b.containment_quality_0_1000);
    out.d_survivability_preservation = GovSaturatingAdd32(a.survivability_preservation_0_1000, -b.survivability_preservation_0_1000);
}

void GovernanceMetaComparatorV1_CompareIncidentStats(const SGovMetaIncidentStatsV1 &a, const SGovMetaIncidentStatsV1 &b, SGovMetaComparatorDeltaV1 &io) {
    io.d_incident_freq_per_1000 = GovSaturatingAdd32(a.incident_frequency_per_1000_epochs, -b.incident_frequency_per_1000_epochs);
    io.d_toxic_spiral_freq_per_1000 = GovSaturatingAdd32(a.toxic_spiral_frequency_per_1000_epochs, -b.toxic_spiral_frequency_per_1000_epochs);
}

void GovernanceMetaComparatorV1_CompareFingerprint(const SGovMetaPolicyFingerprintV1 &a, const SGovMetaPolicyFingerprintV1 &b, SGovMetaComparatorDeltaV1 &io) {
    io.d_fingerprint_flags_xor = a.archetype_flags ^ b.archetype_flags;
    io.d_archetype_primary = GovSaturatingAdd32(a.archetype_primary_code, -b.archetype_primary_code);
}

bool GovernanceMetaComparatorV1_FormatDeltaReport(const SGovMetaComparatorDeltaV1 &d, string &out, string &out_err) {
    out_err = "";
    out = "META_CMP_V1|D_HEALTH=" + IntegerToString(d.d_governance_health_index);
    out += "|D_STAB=" + IntegerToString(d.d_replay_stability);
    out += "|D_CONTAIN=" + IntegerToString(d.d_containment_quality);
    out += "|D_SURV=" + IntegerToString(d.d_survivability_preservation);
    out += "|D_INC_FREQ=" + IntegerToString(d.d_incident_freq_per_1000);
    out += "|D_TOX_FREQ=" + IntegerToString(d.d_toxic_spiral_freq_per_1000);
    out += "|FLAGS_XOR=" + IntegerToString(d.d_fingerprint_flags_xor);
    out += "|D_ARCH_PRIMARY=" + IntegerToString(d.d_archetype_primary);
    out += "\n";
    return true;
}

void GovernanceMetaComparatorV1_FullCompare(const SGovMetaGovernanceHealthV1 &ha, const SGovMetaGovernanceHealthV1 &hb, const SGovMetaIncidentStatsV1 &ia,
                                            const SGovMetaIncidentStatsV1 &ib, const SGovMetaPolicyFingerprintV1 &fa, const SGovMetaPolicyFingerprintV1 &fb,
                                            SGovMetaComparatorDeltaV1 &out) {
    GovernanceMetaComparatorV1_InitDelta(out);
    GovernanceMetaComparatorV1_CompareHealth(ha, hb, out);
    GovernanceMetaComparatorV1_CompareIncidentStats(ia, ib, out);
    GovernanceMetaComparatorV1_CompareFingerprint(fa, fb, out);
}

#endif // __AURUM_GOV_META_COMPARATOR_V1_MQH__
