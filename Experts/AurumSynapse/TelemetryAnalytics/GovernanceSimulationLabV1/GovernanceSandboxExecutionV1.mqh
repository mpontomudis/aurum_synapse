//+------------------------------------------------------------------+
//| GovernanceSandboxExecutionV1.mqh                              |
//| Isolated replay copies — no production mutation.                 |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SANDBOX_EXEC_V1_MQH__
#define __AURUM_GOV_SANDBOX_EXEC_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"

void GovSbExecV1_CloneTl(const SGovReplayTimelineV1 &src, SGovReplayTimelineV1 &dst) {
    GovernanceReplayDatasetV1_InitTimeline(dst);
    dst.source_concat_sha256_hex = src.source_concat_sha256_hex;
    dst.integrity_ok = src.integrity_ok;
    dst.integrity_detail = src.integrity_detail;
    const int n = ArraySize(src.epochs);
    ArrayResize(dst.epochs, n);
    for(int i = 0; i < n; i++)
        dst.epochs[i] = src.epochs[i];
    const int nc = ArraySize(src.campaigns);
    ArrayResize(dst.campaigns, nc);
    for(int k = 0; k < nc; k++)
        dst.campaigns[k] = src.campaigns[k];
}

#endif // __AURUM_GOV_SANDBOX_EXEC_V1_MQH__
