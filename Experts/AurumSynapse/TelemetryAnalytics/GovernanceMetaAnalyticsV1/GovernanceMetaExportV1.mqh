//+------------------------------------------------------------------+
//| GovernanceMetaExportV1.mqh                                     |
//| UTF-8/LF deterministic CSV + JSON-like meta reports.            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_META_EXPORT_V1_MQH__
#define __AURUM_GOV_META_EXPORT_V1_MQH__

#include "GovernanceMetaAnalyticsDatasetV1.mqh"

bool GovernanceMetaExportV1_ExportHealthCsv(const SGovMetaGovernanceHealthV1 &h, string &out_csv, string &out_err) {
    out_err = "";
    out_csv = "governance_health_index,replay_stability,containment_quality,survivability_preservation,escalation_interruption,quarantine_effectiveness,recovery_stabilization,execution_containment_efficiency\n";
    out_csv += IntegerToString(h.governance_health_index_0_1000);
    out_csv += "," + IntegerToString(h.replay_stability_0_1000);
    out_csv += "," + IntegerToString(h.containment_quality_0_1000);
    out_csv += "," + IntegerToString(h.survivability_preservation_0_1000);
    out_csv += "," + IntegerToString(h.escalation_interruption_0_1000);
    out_csv += "," + IntegerToString(h.quarantine_effectiveness_0_1000);
    out_csv += "," + IntegerToString(h.recovery_stabilization_0_1000);
    out_csv += "," + IntegerToString(h.execution_containment_efficiency_0_1000);
    out_csv += "\n";
    return true;
}

bool GovernanceMetaExportV1_ExportIncidentStatsCsv(const SGovMetaIncidentStatsV1 &m, string &out_csv, string &out_err) {
    out_err = "";
    out_csv = "raw_epochs,raw_incidents,tox_spiral,surv_collapse,quar_esc,exec_supp,reg_breakdown,ff_sum,q_epochs,";
    out_csv += "incident_freq_1e3,tox_freq_1e3,surv_freq_1e3,quar_freq_1e3,ff_freq_1e3,reg_break_1e3,";
    out_csv += "containment_success,surv_preservation,avg_lockdown_ep,rec_stab_score,gov_latency_avg_ep\n";
    out_csv += IntegerToString(m.raw_epoch_denominator);
    out_csv += "," + IntegerToString(m.raw_incident_total);
    out_csv += "," + IntegerToString(m.raw_toxic_spiral);
    out_csv += "," + IntegerToString(m.raw_survivability_collapse);
    out_csv += "," + IntegerToString(m.raw_quarantine_escalation);
    out_csv += "," + IntegerToString(m.raw_exec_suppression);
    out_csv += "," + IntegerToString(m.raw_regime_breakdown);
    out_csv += "," + IntegerToString(m.raw_forced_flatten_sum);
    out_csv += "," + IntegerToString(m.raw_quarantine_epoch_hits);
    out_csv += "," + IntegerToString(m.incident_frequency_per_1000_epochs);
    out_csv += "," + IntegerToString(m.toxic_spiral_frequency_per_1000_epochs);
    out_csv += "," + IntegerToString(m.survivability_collapse_frequency_per_1000_epochs);
    out_csv += "," + IntegerToString(m.quarantine_frequency_per_1000_epochs);
    out_csv += "," + IntegerToString(m.forced_flatten_frequency_per_1000_epochs);
    out_csv += "," + IntegerToString(m.regime_breakdown_density_per_1000_epochs);
    out_csv += "," + IntegerToString(m.containment_success_rate_0_1000);
    out_csv += "," + IntegerToString(m.survivability_preservation_score_0_1000);
    out_csv += "," + IntegerToString(m.average_lockdown_duration_epochs);
    out_csv += "," + IntegerToString(m.recovery_stabilization_score_0_1000);
    out_csv += "," + IntegerToString(m.governance_response_latency_avg_epochs);
    out_csv += "\n";
    return true;
}

bool GovernanceMetaExportV1_ExportJsonLikeBundle(const SGovMetaGovernanceHealthV1 &h, const SGovMetaPolicyFingerprintV1 &fp, const SGovMetaIncidentStatsV1 &inc,
                                                 const SGovMetaContainmentStatsV1 &con, const SGovMetaRegimeStatsV1 &reg, string &out, string &out_err) {
    out_err = "";
    out = "{\n";
    out += "  \"schema\":\"GOV_META_ANALYTICS_V1\",\n";
    out += "  \"health_index\":" + IntegerToString(h.governance_health_index_0_1000) + ",\n";
    out += "  \"replay_stability\":" + IntegerToString(h.replay_stability_0_1000) + ",\n";
    out += "  \"fingerprint\":\"" + fp.policy_behavior_fingerprint + "\",\n";
    out += "  \"incident_freq_1e3\":" + IntegerToString(inc.incident_frequency_per_1000_epochs) + ",\n";
    out += "  \"regime_churn\":" + IntegerToString(reg.regime_churn_count) + "\n";
    out += "}\n";
    return true;
}

bool GovMetaExpV1_AppendRpt(const SGovMetaGovernanceHealthV1 &h, const SGovMetaPolicyFingerprintV1 &fp, const SGovMetaIncidentStatsV1 &inc,
                                                           const SGovMetaContainmentStatsV1 &con, const SGovMetaRegimeStatsV1 &reg, string &out_pack, string &out_err) {
    string hcsv = "", icsv = "";
    if(!GovernanceMetaExportV1_ExportHealthCsv(h, hcsv, out_err))
        return false;
    if(!GovernanceMetaExportV1_ExportIncidentStatsCsv(inc, icsv, out_err))
        return false;
    string j = "";
    if(!GovernanceMetaExportV1_ExportJsonLikeBundle(h, fp, inc, con, reg, j, out_err))
        return false;
    out_pack = "===GOV_META_ANALYTICS_V1===\n";
    out_pack += "===META_HEALTH_CSV===\n" + hcsv;
    out_pack += "===META_INCIDENT_CSV===\n" + icsv;
    out_pack += "===META_JSON_SUMMARY===\n" + j;
    return true;
}

#endif // __AURUM_GOV_META_EXPORT_V1_MQH__
