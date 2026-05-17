//+------------------------------------------------------------------+
//| GovernanceResearchLiveIntegrationV1.mqh                        |
//| replay → meta → research (observational; no mutation).           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESEARCH_LIVE_V1_MQH__
#define __AURUM_GOV_RESEARCH_LIVE_V1_MQH__

#include "../GovernanceMetaAnalyticsV1/GovernanceMetaLiveIntegrationV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayParserV1.mqh"
#include "../GovernanceIncidentIntelligenceV1/GovernanceIncidentDetectorV1.mqh"
#include "GovernanceResearchObservationV1.mqh"
#include "GovernanceResearchSummaryV1.mqh"
#include "GovernanceResearchExportV1.mqh"

bool GovResLiveV1_Run(const string utf8_lf, SGovResearchSummaryV1 &out_sum, string &out_bundle, string &out_err) {
    out_err = "";
    out_bundle = "";
    SGovMetaGovernanceHealthV1 h;
    SGovMetaPolicyFingerprintV1 fp;
    SGovMetaIncidentStatsV1 inc;
    SGovMetaContainmentStatsV1 eff;
    SGovMetaRegimeStatsV1 reg;
    string meta_blk = "";
    if(!GovMetaLiveV1_BuildReplay(utf8_lf, h, fp, inc, eff, reg, meta_blk, out_err))
        return false;
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(utf8_lf, norm);
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, out_err))
        return false;
    SGovIncidentSummaryV1 isum;
    string e2 = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, isum, e2)) {
        out_err = e2;
        return false;
    }
    GovResDsV1_InitSum(out_sum);
    if(!GovResSumV1_Build(tl, h, inc, eff, fp, out_sum, out_err))
        return false;
    if(!GovResObsV1_Scan(tl, inc, isum, out_sum, out_err))
        return false;
    if(!GovResExpV1_Bundle(out_sum, "", meta_blk, out_bundle, out_err))
        return false;
    return true;
}

#endif // __AURUM_GOV_RESEARCH_LIVE_V1_MQH__
