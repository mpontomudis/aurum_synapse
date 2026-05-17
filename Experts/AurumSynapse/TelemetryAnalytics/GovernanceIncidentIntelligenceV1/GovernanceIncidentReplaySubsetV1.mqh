//+------------------------------------------------------------------+
//| GovernanceIncidentReplaySubsetV1.mqh                          |
//| Deterministic epoch window extraction (immutable parent hash ref).|
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INCIDENT_REPLAY_SUBSET_V1_MQH__
#define __AURUM_GOV_INCIDENT_REPLAY_SUBSET_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

bool GovernanceIncidentReplaySubsetV1_BuildAroundIndex(const SGovReplayTimelineV1 &full, const int center_ix, const int before_n, const int after_n,
                                                       SGovReplayTimelineV1 &out, string &out_err) {
    out_err = "";
    const int n = ArraySize(full.epochs);
    if(center_ix < 0 || center_ix >= n) {
        out_err = "GOV_INCIDENT_SUBSET_BAD_CENTER";
        return false;
    }
    const int lo = GovClampInt32(center_ix - before_n, 0, n - 1);
    const int hi = GovClampInt32(center_ix + after_n, 0, n - 1);
    GovernanceReplayDatasetV1_InitTimeline(out);
    out.source_concat_sha256_hex = full.source_concat_sha256_hex;
    out.integrity_ok = full.integrity_ok;
    out.integrity_detail = full.integrity_detail;
    ArrayResize(out.epochs, hi - lo + 1);
    for(int j = lo; j <= hi; j++)
        out.epochs[j - lo] = full.epochs[j];
    if(!GovernanceReplayDatasetV1_BuildCampaignRollups(out, out_err))
        return false;
    return true;
}

bool GovernanceIncidentReplaySubsetV1_BuildAroundEpochId(const SGovReplayTimelineV1 &full, const ulong epoch_id, const int before_n, const int after_n,
                                                         SGovReplayTimelineV1 &out, string &out_err) {
    const int ix = GovernanceReplayDatasetV1_FindEpochIndex(full, epoch_id);
    if(ix < 0) {
        out_err = "GOV_INCIDENT_SUBSET_EPOCH_NOT_FOUND";
        return false;
    }
    return GovernanceIncidentReplaySubsetV1_BuildAroundIndex(full, ix, before_n, after_n, out, out_err);
}

#endif // __AURUM_GOV_INCIDENT_REPLAY_SUBSET_V1_MQH__
