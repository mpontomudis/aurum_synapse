//+------------------------------------------------------------------+
//| GovernanceResearchExportV1.mqh                                |
//| UTF-8/LF research bundles (append-friendly).                     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RESEARCH_EXPORT_V1_MQH__
#define __AURUM_GOV_RESEARCH_EXPORT_V1_MQH__

#include "GovernanceResearchDatasetV1.mqh"

bool GovResExpV1_Csv(const SGovResearchSummaryV1 &s, string &out_csv, string &out_err) {
    out_err = "";
    out_csv = "window_ep,inc_density_1e3,ctn_q,surv_p,quar_p,frag_r,rec_s,thr_p,health,dom_fp,policy_fp,replay_sha\n";
    out_csv += IntegerToString(s.observation_window_epochs);
    out_csv += "," + IntegerToString(s.incident_density_per_1000);
    out_csv += "," + IntegerToString(s.containment_quality_0_1000);
    out_csv += "," + IntegerToString(s.survivability_preservation_0_1000);
    out_csv += "," + IntegerToString(s.quarantine_pressure_0_1000);
    out_csv += "," + IntegerToString(s.regime_fragility_0_1000);
    out_csv += "," + IntegerToString(s.recovery_stability_0_1000);
    out_csv += "," + IntegerToString(s.throttle_pressure_0_1000);
    out_csv += "," + IntegerToString(s.governance_health_index);
    out_csv += "," + s.dominant_behavior_fingerprint;
    out_csv += "," + s.policy_fingerprint;
    out_csv += "," + s.replay_hash;
    out_csv += "\n";
    return true;
}

bool GovResExpV1_Bundle(const SGovResearchSummaryV1 &s, const string &drift_line, const string &meta_embed, string &out, string &out_err) {
    string csv = "";
    if(!GovResExpV1_Csv(s, csv, out_err))
        return false;
    out = "===GOV_RESEARCH_V1===\n";
    out += "===RESEARCH_CSV===\n" + csv;
    out += "===OBS_COUNT===\n" + IntegerToString(ArraySize(s.obs)) + "\n";
    if(StringLen(drift_line) > 0) {
        out += "===DRIFT===\n";
        out += drift_line;
    }
    if(StringLen(meta_embed) > 0) {
        out += "===META_EMBED===\n";
        out += meta_embed;
    }
    return true;
}

#endif // __AURUM_GOV_RESEARCH_EXPORT_V1_MQH__
