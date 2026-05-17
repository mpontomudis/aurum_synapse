//+------------------------------------------------------------------+
//| GovernanceReplayDatasetV1.mqh                                  |
//| GOVERNANCE_REPLAY_VISUAL_INTELLIGENCE_V1 — canonical replay      |
//| substrate (immutable records; integer-first; replay-stable).    |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REPLAY_DATASET_V1_MQH__
#define __AURUM_GOV_REPLAY_DATASET_V1_MQH__

#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTypesV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceCryptoV1.mqh"

#define GOV_REPLAY_V1_UNSET_INT (-1)
#define GOV_REPLAY_V1_MAX_EPOCHS 16384

struct SGovReplayEpochV1 {
    ulong epoch_id;
    int   governance_state;
    int   regime_state;
    int   toxicity_ms;
    int   survivability_ms;
    int   causal_pressure_ms;
    int   structural_instability_ms;
    int   risk_multiplier_milli;
    int   exposure_cap_milli;
    int   quarantine_state;
    int   survivability_emergency;
    int   execution_allowed;
    int   entry_allowed;
    int   recovery_allowed;
    int   forced_flatten_required;
    int   throttle_interval_ms;
    int   cooldown_epochs;
    int   causal_reason_code;
    int   dominant_evidence_id;
    string evidence_fingerprint;
    string policy_fingerprint;
    ulong campaign_uuid;
    string telemetry_line_hash_sha256_hex;
};

struct SGovReplayCampaignV1 {
    ulong campaign_uuid;
    int   epoch_count;
    int   min_survivability_ms;
    int   max_toxicity_ms;
    int   max_structural_instability_ms;
    int   lockdown_epoch_hits;
    int   forced_flatten_hits;
    int   execution_denied_epochs;
    int   hard_quarantine_epochs;
};

struct SGovReplayTimelineV1 {
    SGovReplayEpochV1   epochs[];
    SGovReplayCampaignV1 campaigns[];
    string              source_concat_sha256_hex;
    uchar               integrity_ok;
    string              integrity_detail;
};

void GovernanceReplayDatasetV1_InitEpoch(SGovReplayEpochV1 &e) {
    e.epoch_id = 0;
    e.governance_state = GOV_REPLAY_V1_UNSET_INT;
    e.regime_state = GOV_REPLAY_V1_UNSET_INT;
    e.toxicity_ms = GOV_REPLAY_V1_UNSET_INT;
    e.survivability_ms = GOV_REPLAY_V1_UNSET_INT;
    e.causal_pressure_ms = GOV_REPLAY_V1_UNSET_INT;
    e.structural_instability_ms = GOV_REPLAY_V1_UNSET_INT;
    e.risk_multiplier_milli = GOV_REPLAY_V1_UNSET_INT;
    e.exposure_cap_milli = GOV_REPLAY_V1_UNSET_INT;
    e.quarantine_state = GOV_REPLAY_V1_UNSET_INT;
    e.survivability_emergency = GOV_REPLAY_V1_UNSET_INT;
    e.execution_allowed = GOV_REPLAY_V1_UNSET_INT;
    e.entry_allowed = GOV_REPLAY_V1_UNSET_INT;
    e.recovery_allowed = GOV_REPLAY_V1_UNSET_INT;
    e.forced_flatten_required = GOV_REPLAY_V1_UNSET_INT;
    e.throttle_interval_ms = GOV_REPLAY_V1_UNSET_INT;
    e.cooldown_epochs = GOV_REPLAY_V1_UNSET_INT;
    e.causal_reason_code = GOV_REPLAY_V1_UNSET_INT;
    e.dominant_evidence_id = GOV_REPLAY_V1_UNSET_INT;
    e.evidence_fingerprint = "";
    e.policy_fingerprint = "";
    e.campaign_uuid = 0;
    e.telemetry_line_hash_sha256_hex = "";
}

void GovernanceReplayDatasetV1_InitCampaign(SGovReplayCampaignV1 &c) {
    c.campaign_uuid = 0;
    c.epoch_count = 0;
    c.min_survivability_ms = GOV_REPLAY_V1_UNSET_INT;
    c.max_toxicity_ms = GOV_REPLAY_V1_UNSET_INT;
    c.max_structural_instability_ms = GOV_REPLAY_V1_UNSET_INT;
    c.lockdown_epoch_hits = 0;
    c.forced_flatten_hits = 0;
    c.execution_denied_epochs = 0;
    c.hard_quarantine_epochs = 0;
}

void GovernanceReplayDatasetV1_InitTimeline(SGovReplayTimelineV1 &t) {
    ArrayResize(t.epochs, 0);
    ArrayResize(t.campaigns, 0);
    t.source_concat_sha256_hex = "";
    t.integrity_ok = 1;
    t.integrity_detail = "";
}

int GovernanceReplayDatasetV1_FindEpochIndex(const SGovReplayTimelineV1 &t, const ulong epoch_id) {
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        if(t.epochs[i].epoch_id == epoch_id)
            return i;
    }
    return -1;
}

void GovernanceReplayDatasetV1_MergeEpochScalar(int &slot, const int v) {
    if(v == GOV_REPLAY_V1_UNSET_INT)
        return;
    slot = v;
}

void GovernanceReplayDatasetV1_MergeEpochStrings(string &slot, const string v) {
    if(StringLen(v) < 1)
        return;
    slot = v;
}

bool GovernanceReplayDatasetV1_AppendOrMergeEpoch(SGovReplayTimelineV1 &t, const SGovReplayEpochV1 &patch, const string raw_line,
                                                 string &out_err) {
    out_err = "";
    const int n = ArraySize(t.epochs);
    if(n >= GOV_REPLAY_V1_MAX_EPOCHS) {
        out_err = "GOV_REPLAY_V1_EPOCH_CAP";
        return false;
    }
    int ix = GovernanceReplayDatasetV1_FindEpochIndex(t, patch.epoch_id);
    if(ix < 0) {
        ix = n;
        ArrayResize(t.epochs, n + 1);
        GovernanceReplayDatasetV1_InitEpoch(t.epochs[ix]);
        t.epochs[ix].epoch_id = patch.epoch_id;
    }
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].governance_state, patch.governance_state);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].regime_state, patch.regime_state);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].toxicity_ms, patch.toxicity_ms);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].survivability_ms, patch.survivability_ms);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].causal_pressure_ms, patch.causal_pressure_ms);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].structural_instability_ms, patch.structural_instability_ms);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].risk_multiplier_milli, patch.risk_multiplier_milli);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].exposure_cap_milli, patch.exposure_cap_milli);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].quarantine_state, patch.quarantine_state);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].survivability_emergency, patch.survivability_emergency);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].execution_allowed, patch.execution_allowed);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].entry_allowed, patch.entry_allowed);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].recovery_allowed, patch.recovery_allowed);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].forced_flatten_required, patch.forced_flatten_required);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].throttle_interval_ms, patch.throttle_interval_ms);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].cooldown_epochs, patch.cooldown_epochs);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].causal_reason_code, patch.causal_reason_code);
    GovernanceReplayDatasetV1_MergeEpochScalar(t.epochs[ix].dominant_evidence_id, patch.dominant_evidence_id);
    GovernanceReplayDatasetV1_MergeEpochStrings(t.epochs[ix].evidence_fingerprint, patch.evidence_fingerprint);
    GovernanceReplayDatasetV1_MergeEpochStrings(t.epochs[ix].policy_fingerprint, patch.policy_fingerprint);
    if(patch.campaign_uuid != 0)
        t.epochs[ix].campaign_uuid = patch.campaign_uuid;
    if(StringLen(raw_line) > 0) {
        string h = "";
        if(StringLen(t.epochs[ix].telemetry_line_hash_sha256_hex) < 64) {
            if(!GovCryptoV1_Sha256Utf8StringToHexLower(raw_line, h))
                return false;
        } else {
            if(!GovCryptoV1_Sha256Utf8StringToHexLower(t.epochs[ix].telemetry_line_hash_sha256_hex + "\n" + raw_line, h))
                return false;
        }
        t.epochs[ix].telemetry_line_hash_sha256_hex = h;
    }
    return true;
}

void GovernanceReplayDatasetV1_SortEpochsByIdDeterministic(SGovReplayTimelineV1 &t) {
    const int n = ArraySize(t.epochs);
    for(int a = 0; a < n; a++) {
        for(int b = a + 1; b < n; b++) {
            if(t.epochs[b].epoch_id < t.epochs[a].epoch_id) {
                const SGovReplayEpochV1 tmp = t.epochs[a];
                t.epochs[a] = t.epochs[b];
                t.epochs[b] = tmp;
            }
        }
    }
}

bool GovernanceReplayDatasetV1_BuildCampaignRollups(SGovReplayTimelineV1 &t, string &out_err) {
    out_err = "";
    ArrayResize(t.campaigns, 0);
    const int ne = ArraySize(t.epochs);
    for(int i = 0; i < ne; i++) {
        const ulong cid = t.epochs[i].campaign_uuid;
        if(cid == 0)
            continue;
        int cix = -1;
        const int nc = ArraySize(t.campaigns);
        for(int k = 0; k < nc; k++) {
            if(t.campaigns[k].campaign_uuid == cid) {
                cix = k;
                break;
            }
        }
        if(cix < 0) {
            cix = nc;
            ArrayResize(t.campaigns, nc + 1);
            GovernanceReplayDatasetV1_InitCampaign(t.campaigns[cix]);
            t.campaigns[cix].campaign_uuid = cid;
        }
        t.campaigns[cix].epoch_count = GovSaturatingAdd32(t.campaigns[cix].epoch_count, 1);
        const int sv = t.epochs[i].survivability_ms;
        const int tx = t.epochs[i].toxicity_ms;
        const int st = t.epochs[i].structural_instability_ms;
        if(sv != GOV_REPLAY_V1_UNSET_INT) {
            if(t.campaigns[cix].min_survivability_ms == GOV_REPLAY_V1_UNSET_INT || sv < t.campaigns[cix].min_survivability_ms)
                t.campaigns[cix].min_survivability_ms = sv;
        }
        if(tx != GOV_REPLAY_V1_UNSET_INT) {
            if(t.campaigns[cix].max_toxicity_ms == GOV_REPLAY_V1_UNSET_INT || tx > t.campaigns[cix].max_toxicity_ms)
                t.campaigns[cix].max_toxicity_ms = tx;
        }
        if(st != GOV_REPLAY_V1_UNSET_INT) {
            if(t.campaigns[cix].max_structural_instability_ms == GOV_REPLAY_V1_UNSET_INT || st > t.campaigns[cix].max_structural_instability_ms)
                t.campaigns[cix].max_structural_instability_ms = st;
        }
        const int gs = t.epochs[i].governance_state;
        if(gs == (int)GOV_STATE_LOCKDOWN)
            t.campaigns[cix].lockdown_epoch_hits = GovSaturatingAdd32(t.campaigns[cix].lockdown_epoch_hits, 1);
        const int ff = t.epochs[i].forced_flatten_required;
        if(ff == 1)
            t.campaigns[cix].forced_flatten_hits = GovSaturatingAdd32(t.campaigns[cix].forced_flatten_hits, 1);
        const int ex = t.epochs[i].execution_allowed;
        if(ex == 0)
            t.campaigns[cix].execution_denied_epochs = GovSaturatingAdd32(t.campaigns[cix].execution_denied_epochs, 1);
        const int qs = t.epochs[i].quarantine_state;
        if(qs >= 2)
            t.campaigns[cix].hard_quarantine_epochs = GovSaturatingAdd32(t.campaigns[cix].hard_quarantine_epochs, 1);
    }
    return true;
}

#endif // __AURUM_GOV_REPLAY_DATASET_V1_MQH__
