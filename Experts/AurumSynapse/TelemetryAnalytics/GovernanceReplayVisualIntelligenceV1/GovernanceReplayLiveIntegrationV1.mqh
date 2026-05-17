//+------------------------------------------------------------------+
//| GovernanceReplayLiveIntegrationV1.mqh                        |
//| Production log ingestion (FILE_COMMON UTF-8/LF).               |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REPLAY_LIVE_INTEGRATION_V1_MQH__
#define __AURUM_GOV_REPLAY_LIVE_INTEGRATION_V1_MQH__

#include "../JoinValidationPrototype.mqh"
#include "GovernanceReplayParserV1.mqh"
#include "GovernanceReplayIntegrityV1.mqh"

bool GovernanceReplayLiveIntegrationV1_LoadAndParseFromCommonUtf8Lf(const string relPathFromCommonFiles,
                                                                     SGovReplayTimelineV1 &out_timeline,
                                                                     string &out_err) {
    out_err = "";
    string raw = "";
    if(!JoinValidation_ReadUtf8FileLf(relPathFromCommonFiles, raw)) {
        out_err = "GOV_REPLAY_LIVE_READ_FAIL";
        return false;
    }
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(raw, norm);
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, out_timeline, out_err))
        return false;
    string d = "";
    if(!GovernanceReplayIntegrityV1_ValidateAll(out_timeline, norm, d)) {
        out_err = d;
        return false;
    }
    return true;
}

#endif // __AURUM_GOV_REPLAY_LIVE_INTEGRATION_V1_MQH__
