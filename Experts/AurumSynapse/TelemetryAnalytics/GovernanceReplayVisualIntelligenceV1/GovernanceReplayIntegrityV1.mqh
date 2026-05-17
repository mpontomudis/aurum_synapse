//+------------------------------------------------------------------+
//| GovernanceReplayIntegrityV1.mqh                              |
//| Deterministic replay integrity checks (fail-closed).            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REPLAY_INTEGRITY_V1_MQH__
#define __AURUM_GOV_REPLAY_INTEGRITY_V1_MQH__

#include "GovernanceReplayDatasetV1.mqh"

bool GovernanceReplayIntegrityV1_VerifySourceHash(const SGovReplayTimelineV1 &t, const string normalized_utf8_lf, string &detail) {
    detail = "";
    string h = "";
    if(!GovCryptoV1_Sha256Utf8StringToHexLower(normalized_utf8_lf, h))
        return false;
    if(h != t.source_concat_sha256_hex) {
        detail = "GOV_REPLAY_INTEGRITY_SOURCE_HASH_MISMATCH";
        return false;
    }
    return true;
}

bool GovernanceReplayIntegrityV1_VerifyEpochMonotonicNonDecreasing(const SGovReplayTimelineV1 &t, string &detail) {
    detail = "";
    const int n = ArraySize(t.epochs);
    for(int i = 1; i < n; i++) {
        if(t.epochs[i].epoch_id < t.epochs[i - 1].epoch_id) {
            detail = "GOV_REPLAY_INTEGRITY_EPOCH_ORDER";
            return false;
        }
    }
    return true;
}

bool GovernanceReplayIntegrityV1_VerifyEpochTelemetryHashes(const SGovReplayTimelineV1 &t, string &detail) {
    detail = "";
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        const int hlen = StringLen(t.epochs[i].telemetry_line_hash_sha256_hex);
        if(hlen != 0 && hlen != 64) {
            detail = "GOV_REPLAY_INTEGRITY_LINE_HASH_LEN";
            return false;
        }
    }
    return true;
}

bool GovernanceReplayIntegrityV1_ValidateAll(const SGovReplayTimelineV1 &t, const string normalized_utf8_lf, string &detail) {
    if(t.integrity_ok == 0) {
        detail = t.integrity_detail;
        return false;
    }
    if(!GovernanceReplayIntegrityV1_VerifyEpochMonotonicNonDecreasing(t, detail))
        return false;
    if(!GovernanceReplayIntegrityV1_VerifyEpochTelemetryHashes(t, detail))
        return false;
    if(StringLen(normalized_utf8_lf) > 0 &&
       !GovernanceReplayIntegrityV1_VerifySourceHash(t, normalized_utf8_lf, detail))
        return false;
    return true;
}

#endif // __AURUM_GOV_REPLAY_INTEGRITY_V1_MQH__
