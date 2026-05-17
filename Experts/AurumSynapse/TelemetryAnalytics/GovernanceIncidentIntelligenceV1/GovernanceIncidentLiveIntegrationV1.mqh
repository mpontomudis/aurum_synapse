//+------------------------------------------------------------------+
//| GovernanceIncidentLiveIntegrationV1.mqh                       |
//| Parse → timeline → incident detect → export (read-only on TL).   |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INCIDENT_LIVE_INTEGRATION_V1_MQH__
#define __AURUM_GOV_INCIDENT_LIVE_INTEGRATION_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayParserV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceTimelineEngineV1.mqh"
#include "GovernanceIncidentDetectorV1.mqh"
#include "GovernanceIncidentExportV1.mqh"

bool GovernanceIncidentLiveIntegrationV1_ProcessUtf8Replay(const string utf8_lf, SGovReplayTimelineV1 &out_tl, SGovIncidentSummaryV1 &out_inc,
                                                             string &out_timeline_csv, string &out_incident_bundle, string &out_err) {
    out_err = "";
    out_timeline_csv = "";
    out_incident_bundle = "";
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(utf8_lf, norm);
    GovernanceReplayDatasetV1_InitTimeline(out_tl);
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, out_tl, out_err))
        return false;
    if(!GovernanceTimelineEngineV1_BuildAll(out_tl, out_timeline_csv, out_err))
        return false;
    string e2 = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(out_tl, out_inc, e2)) {
        out_err = e2;
        return false;
    }
    if(!GovernanceIncidentExportV1_ExportForensicBundle(out_tl, out_inc, out_incident_bundle, out_err))
        return false;
    return true;
}

#endif // __AURUM_GOV_INCIDENT_LIVE_INTEGRATION_V1_MQH__
