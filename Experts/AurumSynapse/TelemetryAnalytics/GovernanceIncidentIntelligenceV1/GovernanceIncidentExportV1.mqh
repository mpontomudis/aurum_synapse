//+------------------------------------------------------------------+
//| GovernanceIncidentExportV1.mqh                                  |
//| UTF-8/LF forensic exports (CSV + deterministic text blocks).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INCIDENT_EXPORT_V1_MQH__
#define __AURUM_GOV_INCIDENT_EXPORT_V1_MQH__

#include "GovernanceIncidentDatasetV1.mqh"
#include "GovernanceIncidentCausalityV1.mqh"
#include "GovernanceIncidentContainmentAnalyticsV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayExportV1.mqh"
#include "../GovernanceStateMachineV1/GovernanceTelemetryV1.mqh"

bool GovernanceIncidentExportV1_ExportEventsCsv(const SGovIncidentSummaryV1 &s, string &out_csv, string &out_err) {
    out_err = "";
    out_csv = "incident_id,incident_type,start_epoch,peak_epoch,recovery_epoch,dom_gs,dom_rg,dom_causal,tox_peak_ms,surv_floor_ms,quar_peak,ff_count,exec_supp,containment_0_1000,replay_hash,campaign_uuid\n";
    const int n = ArraySize(s.events);
    for(int i = 0; i < n; i++) {
        const SGovIncidentEventV1 e = s.events[i];
        out_csv += IntegerToString(e.incident_id);
        out_csv += "," + IntegerToString(e.incident_type);
        out_csv += "," + GovernanceTelemetryV1_FormatU64Dec(e.start_epoch);
        out_csv += "," + GovernanceTelemetryV1_FormatU64Dec(e.peak_epoch);
        out_csv += "," + GovernanceTelemetryV1_FormatU64Dec(e.recovery_epoch);
        out_csv += "," + IntegerToString(e.dominant_governance_state);
        out_csv += "," + IntegerToString(e.dominant_regime);
        out_csv += "," + IntegerToString(e.dominant_causal_factor);
        out_csv += "," + IntegerToString(e.toxicity_peak_ms);
        out_csv += "," + IntegerToString(e.survivability_floor_ms);
        out_csv += "," + IntegerToString(e.quarantine_peak);
        out_csv += "," + IntegerToString(e.forced_flatten_count);
        out_csv += "," + IntegerToString(e.execution_suppression_count);
        out_csv += "," + IntegerToString(e.containment_effectiveness_score_0_1000);
        out_csv += "," + e.replay_hash;
        out_csv += "," + GovernanceTelemetryV1_FormatU64Dec(e.campaign_uuid);
        out_csv += "\n";
    }
    return true;
}

bool GovernanceIncidentExportV1_ExportCausalBlock(const SGovReplayTimelineV1 &tl, const SGovIncidentSummaryV1 &s, string &out_blk, string &out_err) {
    out_err = "";
    out_blk = "";
    const int n = ArraySize(s.events);
    for(int i = 0; i < n; i++) {
        string ln = "";
        if(!GovernanceIncidentCausalityV1_FormatReport(tl, s.events[i], ln))
            return false;
        if(StringLen(out_blk) > 0)
            out_blk += "\n";
        out_blk += ln;
    }
    return true;
}

bool GovernanceIncidentExportV1_ExportContainmentBlock(const SGovReplayTimelineV1 &tl, const SGovIncidentSummaryV1 &s, string &out_blk, string &out_err) {
    out_err = "";
    out_blk = "";
    const int n = ArraySize(s.events);
    for(int i = 0; i < n; i++) {
        SGovIncidentContainmentAnalyticsRowV1 row;
        string e2 = "";
        if(!GovernanceIncidentContainmentAnalyticsV1_Compute(tl, s.events[i], row, e2)) {
            out_err = e2;
            return false;
        }
        if(StringLen(out_blk) > 0)
            out_blk += "\n";
        out_blk += "INCIDENT_ID=" + IntegerToString(s.events[i].incident_id);
        out_blk += "|SUCCESS=" + IntegerToString(row.containment_success_0_1000);
        out_blk += "|ESC_INT=" + IntegerToString(row.escalation_interruption_efficiency_0_1000);
        out_blk += "|SURV_DELTA=" + IntegerToString(row.survivability_preservation_delta_ms);
        out_blk += "|FF_EFF=" + IntegerToString(row.forced_flatten_effectiveness_0_1000);
        out_blk += "|Q_EFF=" + IntegerToString(row.quarantine_stabilization_efficiency_0_1000);
        out_blk += "|LATENCY_EP=" + IntegerToString(row.governance_response_latency_epochs);
        out_blk += "|RECOVERY_Q=" + IntegerToString(row.recovery_stabilization_quality_0_1000);
    }
    return true;
}

bool GovernanceIncidentExportV1_ExportForensicBundle(const SGovReplayTimelineV1 &tl, const SGovIncidentSummaryV1 &inc, string &out_pack, string &out_err) {
    string replay = "";
    if(!GovernanceReplayExportV1_ExportFullPack(tl, replay, out_err))
        return false;
    string evcsv = "";
    if(!GovernanceIncidentExportV1_ExportEventsCsv(inc, evcsv, out_err))
        return false;
    string causal = "";
    if(!GovernanceIncidentExportV1_ExportCausalBlock(tl, inc, causal, out_err))
        return false;
    string cont = "";
    if(!GovernanceIncidentExportV1_ExportContainmentBlock(tl, inc, cont, out_err))
        return false;
    out_pack = "===GOV_INCIDENT_FORENSIC_V1===\n";
    out_pack += "SOURCE_REPLAY_SHA256=" + inc.source_replay_sha256_hex + "\n";
    out_pack += "===REPLAY_FULL_PACK===\n" + replay + "\n";
    out_pack += "===INCIDENT_EVENTS_CSV===\n" + evcsv + "\n";
    out_pack += "===INCIDENT_CAUSAL===\n" + causal + "\n";
    out_pack += "===INCIDENT_CONTAINMENT===\n" + cont + "\n";
    return true;
}

#endif // __AURUM_GOV_INCIDENT_EXPORT_V1_MQH__
