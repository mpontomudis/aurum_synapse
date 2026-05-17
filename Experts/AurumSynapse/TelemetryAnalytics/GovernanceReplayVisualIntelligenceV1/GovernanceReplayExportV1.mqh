//+------------------------------------------------------------------+
//| GovernanceReplayExportV1.mqh                                 |
//| Deterministic UTF-8/LF exports (data-only; no GUI).            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REPLAY_EXPORT_V1_MQH__
#define __AURUM_GOV_REPLAY_EXPORT_V1_MQH__

#include "GovernanceReplayDatasetV1.mqh"
#include "GovernanceTimelineEngineV1.mqh"
#include "GovernanceCausalReplayInspectorV1.mqh"
#include "GovernanceContainmentAnalyticsV1.mqh"

bool GovernanceReplayExportV1_ExportJsonLikeSummary(const SGovReplayTimelineV1 &t,
                                                   const SGovContainmentMetricsV1 &met,
                                                   string &out,
                                                   string &out_err) {
    out_err = "";
    out = "{\n";
    out += "  \"schema\":\"GOV_REPLAY_EXPORT_V1\",\n";
    out += "  \"epochs\":" + IntegerToString(ArraySize(t.epochs)) + ",\n";
    out += "  \"campaigns\":" + IntegerToString(ArraySize(t.campaigns)) + ",\n";
    out += "  \"source_sha256\":\"" + t.source_concat_sha256_hex + "\",\n";
    out += "  \"integrity_ok\":" + IntegerToString((int)t.integrity_ok) + ",\n";
    out += "  \"containment\":{\n";
    out += "    \"prevented_escalation_epochs\":" + IntegerToString(met.prevented_escalation_epochs) + ",\n";
    out += "    \"exposure_compression_sum_milli\":" + IntegerToString(met.exposure_compression_sum_milli) + ",\n";
    out += "    \"survivability_preservation_score_0_1000\":" + IntegerToString(met.survivability_preservation_score_0_1000) + ",\n";
    out += "    \"toxic_interrupt_epochs\":" + IntegerToString(met.toxic_interrupt_epochs) + ",\n";
    out += "    \"quarantine_hard_epoch_hits\":" + IntegerToString(met.quarantine_hard_epoch_hits) + ",\n";
    out += "    \"forced_flatten_count\":" + IntegerToString(met.forced_flatten_count) + ",\n";
    out += "    \"throttle_containment_score_0_1000\":" + IntegerToString(met.throttle_containment_score_0_1000) + "\n";
    out += "  }\n";
    out += "}\n";
    return true;
}

bool GovernanceReplayExportV1_ExportEpochCsv(const SGovReplayTimelineV1 &t, string &out_csv, string &out_err) {
    out_err = "";
    out_csv = "epoch_id,governance_state,regime_state,toxicity_ms,survivability_ms,causal_pressure_ms,structural_ms,risk_milli,exposure_cap_milli,quarantine,surv_emergency,exec_allowed,entry_allowed,recovery_allowed,flatten,throttle_ms,cooldown_epochs,causal_code,dom_evidence,evidence_fp,policy_fp,campaign_uuid,line_hash\n";
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        SGovReplayEpochV1 e = t.epochs[i];
        out_csv += GovernanceTelemetryV1_FormatU64Dec(e.epoch_id);
        out_csv += "," + IntegerToString(e.governance_state);
        out_csv += "," + IntegerToString(e.regime_state);
        out_csv += "," + IntegerToString(e.toxicity_ms);
        out_csv += "," + IntegerToString(e.survivability_ms);
        out_csv += "," + IntegerToString(e.causal_pressure_ms);
        out_csv += "," + IntegerToString(e.structural_instability_ms);
        out_csv += "," + IntegerToString(e.risk_multiplier_milli);
        out_csv += "," + IntegerToString(e.exposure_cap_milli);
        out_csv += "," + IntegerToString(e.quarantine_state);
        out_csv += "," + IntegerToString(e.survivability_emergency);
        out_csv += "," + IntegerToString(e.execution_allowed);
        out_csv += "," + IntegerToString(e.entry_allowed);
        out_csv += "," + IntegerToString(e.recovery_allowed);
        out_csv += "," + IntegerToString(e.forced_flatten_required);
        out_csv += "," + IntegerToString(e.throttle_interval_ms);
        out_csv += "," + IntegerToString(e.cooldown_epochs);
        out_csv += "," + IntegerToString(e.causal_reason_code);
        out_csv += "," + IntegerToString(e.dominant_evidence_id);
        out_csv += "," + e.evidence_fingerprint;
        out_csv += "," + e.policy_fingerprint;
        out_csv += "," + GovernanceTelemetryV1_FormatU64Dec(e.campaign_uuid);
        out_csv += "," + e.telemetry_line_hash_sha256_hex;
        out_csv += "\n";
    }
    return true;
}

bool GovernanceReplayExportV1_ExportFullPack(const SGovReplayTimelineV1 &t,
                                            string &out_pack,
                                            string &out_err) {
    string tl = "";
    if(!GovernanceTimelineEngineV1_BuildAll(t, tl, out_err))
        return false;
    string caus = "";
    if(!GovernanceCausalReplayInspectorV1_BuildTransitions(t, caus, out_err))
        return false;
    SGovContainmentMetricsV1 met;
    if(!GovernanceContainmentAnalyticsV1_Compute(t, met, out_err))
        return false;
    string summ = "";
    if(!GovernanceReplayExportV1_ExportJsonLikeSummary(t, met, summ, out_err))
        return false;
    string csv = "";
    if(!GovernanceReplayExportV1_ExportEpochCsv(t, csv, out_err))
        return false;
    out_pack = "===TIMELINE_CSV===\n" + tl + "\n===CAUSAL===\n" + caus + "\n===EPOCH_CSV===\n" + csv + "\n===SUMMARY_JSON_LIKE===\n" + summ;
    return true;
}

#endif // __AURUM_GOV_REPLAY_EXPORT_V1_MQH__
