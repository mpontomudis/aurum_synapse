//+------------------------------------------------------------------+
//| GovernanceMetaLiveIntegrationV1.mqh                            |
//| Observational meta pipeline over UTF-8 replay (no mutation).      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_META_LIVE_INTEGRATION_V1_MQH__
#define __AURUM_GOV_META_LIVE_INTEGRATION_V1_MQH__

#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayParserV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceContainmentAnalyticsV1.mqh"
#include "../GovernanceIncidentIntelligenceV1/GovernanceIncidentDetectorV1.mqh"
#include "GovernanceIncidentMetaAnalyticsV1.mqh"
#include "GovernanceRegimeMetaAnalyticsV1.mqh"
#include "GovernanceEffectivenessAnalyticsV1.mqh"
#include "GovernancePolicyBehaviorFingerprintV1.mqh"
#include "GovernanceHealthEngineV1.mqh"
#include "GovernanceMetaExportV1.mqh"

bool GovMetaLiveV1_BuildReplay(const string utf8_lf, SGovMetaGovernanceHealthV1 &out_health, SGovMetaPolicyFingerprintV1 &out_fp,
                                                           SGovMetaIncidentStatsV1 &out_inc, SGovMetaContainmentStatsV1 &out_eff, SGovMetaRegimeStatsV1 &out_reg,
                                                           string &out_report, string &out_err) {
    out_err = "";
    out_report = "";
    GovernanceMetaAnalyticsDatasetV1_InitHealth(out_health);
    GovernanceMetaAnalyticsDatasetV1_InitFingerprint(out_fp);
    GovernanceMetaAnalyticsDatasetV1_InitIncidentStats(out_inc);
    GovernanceMetaAnalyticsDatasetV1_InitContainmentStats(out_eff);
    GovernanceMetaAnalyticsDatasetV1_InitRegimeStats(out_reg);
    string norm = "";
    GovernanceReplayParserV1_NormalizeLf(utf8_lf, norm);
    SGovReplayTimelineV1 tl;
    GovernanceReplayDatasetV1_InitTimeline(tl);
    if(!GovernanceReplayParserV1_ParseMultilineUtf8Lf(norm, tl, out_err))
        return false;
    SGovContainmentMetricsV1 cm;
    if(!GovernanceContainmentAnalyticsV1_Compute(tl, cm, out_err))
        return false;
    SGovIncidentSummaryV1 inc_sum;
    string e2 = "";
    if(!GovernanceIncidentDetectorV1_DetectAll(tl, inc_sum, e2)) {
        out_err = e2;
        return false;
    }
    GovIncMetaV1_Init(out_inc);
    GovIncMetaV1_Acc(inc_sum, ArraySize(tl.epochs), out_inc);
    GovIncMetaV1_AccQEp(tl, out_inc);
    GovIncMetaV1_Finalize(out_inc);
    int ld_avg = 0;
    if(!GovernanceRegimeMetaAnalyticsV1_LockdownRuns(tl, ld_avg, out_err))
        return false;
    out_inc.average_lockdown_duration_epochs = ld_avg;
    if(!GovernanceRegimeMetaAnalyticsV1_Compute(tl, out_reg, out_err))
        return false;
    if(!GovernanceEffectivenessAnalyticsV1_Compute(tl, cm, out_eff, out_err))
        return false;
    if(!GovernancePolicyBehaviorFingerprintV1_Compute(tl, cm, out_fp, out_err))
        return false;
    if(!GovernanceHealthEngineV1_Compute(tl, out_inc, out_eff, out_reg, out_health, out_err))
        return false;
    if(!GovMetaExpV1_AppendRpt(out_health, out_fp, out_inc, out_eff, out_reg, out_report, out_err))
        return false;
    return true;
}

#endif // __AURUM_GOV_META_LIVE_INTEGRATION_V1_MQH__
