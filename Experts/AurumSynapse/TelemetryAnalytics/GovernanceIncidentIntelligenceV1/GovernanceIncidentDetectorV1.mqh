//+------------------------------------------------------------------+
//| GovernanceIncidentDetectorV1.mqh                             |
//| Deterministic pattern detection over replay epochs.             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INCIDENT_DETECTOR_V1_MQH__
#define __AURUM_GOV_INCIDENT_DETECTOR_V1_MQH__

#include "GovernanceIncidentDatasetV1.mqh"
#include "../GovernanceStateMachineV1/GovernancePolicyPrimitivesV1.mqh"

bool GovIncidentDetectorV1_AppendEvent(SGovIncidentSummaryV1 &sum, const SGovIncidentEventV1 &ev) {
    const int n = ArraySize(sum.events);
    ArrayResize(sum.events, n + 1);
    sum.events[n] = ev;
    return true;
}

int GovIncidentDetectorV1_MinSurv3(const int a, const int b, const int c) {
    int m = a;
    if(b != GOV_REPLAY_V1_UNSET_INT && (m == GOV_REPLAY_V1_UNSET_INT || b < m))
        m = b;
    if(c != GOV_REPLAY_V1_UNSET_INT && (m == GOV_REPLAY_V1_UNSET_INT || c < m))
        m = c;
    return m;
}

bool GovernanceIncidentDetectorV1_DetectAll(const SGovReplayTimelineV1 &tl, SGovIncidentSummaryV1 &out, string &out_err) {
    out_err = "";
    GovernanceIncidentDatasetV1_InitSummary(out);
    out.source_replay_sha256_hex = tl.source_concat_sha256_hex;
    int next_id = 1;
    const int n = ArraySize(tl.epochs);
    int run_supp = 0;
    int run_esc = 0;
    int prev_q = GOV_REPLAY_V1_UNSET_INT;
    for(int i = 0; i < n; i++) {
        SGovReplayEpochV1 e = tl.epochs[i];
        if(e.regime_state == 4) {
            SGovIncidentEventV1 ev;
            GovernanceIncidentDatasetV1_InitEvent(ev);
            ev.incident_id = next_id++;
            ev.incident_type = (int)GOV_INCIDENT_V1_REGIME_BREAKDOWN;
            ev.start_epoch = e.epoch_id;
            ev.peak_epoch = e.epoch_id;
            ev.recovery_epoch = e.epoch_id;
            ev.dominant_governance_state = e.governance_state;
            ev.dominant_regime = e.regime_state;
            ev.dominant_causal_factor = e.dominant_evidence_id;
            ev.toxicity_peak_ms = e.toxicity_ms;
            ev.survivability_floor_ms = e.survivability_ms;
            ev.quarantine_peak = (e.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : e.quarantine_state;
            ev.forced_flatten_count = (e.forced_flatten_required == 1) ? 1 : 0;
            ev.execution_suppression_count = (e.execution_allowed == 0) ? 1 : 0;
            ev.containment_effectiveness_score_0_1000 = GovClampInt32(1000 - GovClampInt32(e.throttle_interval_ms, 0, 1000000) / 20, 0, 1000);
            ev.replay_hash = e.telemetry_line_hash_sha256_hex;
            ev.campaign_uuid = e.campaign_uuid;
            if(!GovIncidentDetectorV1_AppendEvent(out, ev))
                return false;
        }
        if(i >= 2) {
            SGovReplayEpochV1 a = tl.epochs[i - 2];
            SGovReplayEpochV1 b = tl.epochs[i - 1];
            SGovReplayEpochV1 c = tl.epochs[i];
            if(a.toxicity_ms != GOV_REPLAY_V1_UNSET_INT && b.toxicity_ms != GOV_REPLAY_V1_UNSET_INT && c.toxicity_ms != GOV_REPLAY_V1_UNSET_INT) {
                if(b.toxicity_ms >= a.toxicity_ms + 1500 && c.toxicity_ms >= b.toxicity_ms + 1500) {
                    SGovIncidentEventV1 ev;
                    GovernanceIncidentDatasetV1_InitEvent(ev);
                    ev.incident_id = next_id++;
                    ev.incident_type = (int)GOV_INCIDENT_V1_TOX_SPIRAL;
                    ev.start_epoch = a.epoch_id;
                    ev.peak_epoch = c.epoch_id;
                    ev.recovery_epoch = c.epoch_id;
                    ev.dominant_governance_state = c.governance_state;
                    ev.dominant_regime = c.regime_state;
                    ev.dominant_causal_factor = c.dominant_evidence_id;
                    ev.toxicity_peak_ms = GovMaxInt32_x3(a.toxicity_ms, b.toxicity_ms, c.toxicity_ms);
                    ev.survivability_floor_ms = GovIncidentDetectorV1_MinSurv3(a.survivability_ms, b.survivability_ms, c.survivability_ms);
                    const int qa = (a.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : a.quarantine_state;
                    const int qb = (b.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : b.quarantine_state;
                    const int qc = (c.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : c.quarantine_state;
                    ev.quarantine_peak = GovMaxInt32_x3(qa, qb, qc);
                    ev.forced_flatten_count = (a.forced_flatten_required == 1 ? 1 : 0) + (b.forced_flatten_required == 1 ? 1 : 0) +
                                              (c.forced_flatten_required == 1 ? 1 : 0);
                    ev.execution_suppression_count = (a.execution_allowed == 0 ? 1 : 0) + (b.execution_allowed == 0 ? 1 : 0) +
                                                     (c.execution_allowed == 0 ? 1 : 0);
                    ev.containment_effectiveness_score_0_1000 = GovClampInt32(1000 - GovClampInt32(ev.toxicity_peak_ms, 0, 1000000) / 10000, 0, 1000);
                    ev.replay_hash = c.telemetry_line_hash_sha256_hex;
                    ev.campaign_uuid = c.campaign_uuid;
                    if(!GovIncidentDetectorV1_AppendEvent(out, ev))
                        return false;
                }
            }
            if(a.survivability_ms != GOV_REPLAY_V1_UNSET_INT && c.survivability_ms != GOV_REPLAY_V1_UNSET_INT) {
                if(a.survivability_ms >= 4000 && c.survivability_ms < 2000) {
                    SGovIncidentEventV1 ev;
                    GovernanceIncidentDatasetV1_InitEvent(ev);
                    ev.incident_id = next_id++;
                    ev.incident_type = (int)GOV_INCIDENT_V1_SURV_COLLAPSE;
                    ev.start_epoch = a.epoch_id;
                    ev.peak_epoch = b.epoch_id;
                    ev.recovery_epoch = c.epoch_id;
                    ev.dominant_governance_state = c.governance_state;
                    ev.dominant_regime = c.regime_state;
                    ev.survivability_floor_ms = GovIncidentDetectorV1_MinSurv3(a.survivability_ms, b.survivability_ms, c.survivability_ms);
                    ev.toxicity_peak_ms = GovMaxInt32_x3(a.toxicity_ms, b.toxicity_ms, c.toxicity_ms);
                    ev.dominant_causal_factor = c.dominant_evidence_id;
                    const int qa2 = (a.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : a.quarantine_state;
                    const int qb2 = (b.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : b.quarantine_state;
                    const int qc2 = (c.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : c.quarantine_state;
                    ev.quarantine_peak = GovMaxInt32_x3(qa2, qb2, qc2);
                    ev.forced_flatten_count = (a.forced_flatten_required == 1 ? 1 : 0) + (b.forced_flatten_required == 1 ? 1 : 0) +
                                                (c.forced_flatten_required == 1 ? 1 : 0);
                    ev.execution_suppression_count = (a.execution_allowed == 0 ? 1 : 0) + (b.execution_allowed == 0 ? 1 : 0) +
                                                     (c.execution_allowed == 0 ? 1 : 0);
                    int sf = ev.survivability_floor_ms;
                    if(sf == GOV_REPLAY_V1_UNSET_INT)
                        sf = 0;
                    ev.containment_effectiveness_score_0_1000 = GovClampInt32(sf * 1000 / 4000, 0, 1000);
                    ev.replay_hash = c.telemetry_line_hash_sha256_hex;
                    ev.campaign_uuid = c.campaign_uuid;
                    if(!GovIncidentDetectorV1_AppendEvent(out, ev))
                        return false;
                }
            }
            if(a.execution_allowed == 0 && b.execution_allowed == 1 && c.execution_allowed == 0 &&
               (b.quarantine_state >= 1 || c.quarantine_state >= 1)) {
                SGovIncidentEventV1 ev;
                GovernanceIncidentDatasetV1_InitEvent(ev);
                ev.incident_id = next_id++;
                ev.incident_type = (int)GOV_INCIDENT_V1_FALSE_RECOVERY;
                ev.start_epoch = a.epoch_id;
                ev.peak_epoch = b.epoch_id;
                ev.recovery_epoch = c.epoch_id;
                ev.dominant_governance_state = b.governance_state;
                ev.dominant_regime = b.regime_state;
                ev.dominant_causal_factor = b.dominant_evidence_id;
                ev.toxicity_peak_ms = GovMaxInt32_x3(a.toxicity_ms, b.toxicity_ms, c.toxicity_ms);
                ev.survivability_floor_ms = GovIncidentDetectorV1_MinSurv3(a.survivability_ms, b.survivability_ms, c.survivability_ms);
                const int qa3 = (a.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : a.quarantine_state;
                const int qb3 = (b.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : b.quarantine_state;
                const int qc3 = (c.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : c.quarantine_state;
                ev.quarantine_peak = GovMaxInt32_x3(qa3, qb3, qc3);
                ev.forced_flatten_count = (a.forced_flatten_required == 1 ? 1 : 0) + (b.forced_flatten_required == 1 ? 1 : 0) +
                                          (c.forced_flatten_required == 1 ? 1 : 0);
                ev.execution_suppression_count = 2;
                ev.containment_effectiveness_score_0_1000 = GovClampInt32(1000 - ev.quarantine_peak * 150, 0, 1000);
                ev.replay_hash = b.telemetry_line_hash_sha256_hex;
                ev.campaign_uuid = b.campaign_uuid;
                if(!GovIncidentDetectorV1_AppendEvent(out, ev))
                    return false;
            }
        }
        if(e.execution_allowed == 0)
            run_supp = GovSaturatingAdd32(run_supp, 1);
        else
            run_supp = 0;
        if(run_supp >= 3) {
            SGovIncidentEventV1 ev;
            GovernanceIncidentDatasetV1_InitEvent(ev);
            ev.incident_id = next_id++;
            ev.incident_type = (int)GOV_INCIDENT_V1_EXEC_SUPPRESSION;
            ev.start_epoch = tl.epochs[i - 2].epoch_id;
            ev.peak_epoch = e.epoch_id;
            ev.recovery_epoch = e.epoch_id;
            ev.execution_suppression_count = 3;
            ev.dominant_governance_state = e.governance_state;
            ev.dominant_regime = e.regime_state;
            ev.dominant_causal_factor = e.dominant_evidence_id;
            ev.toxicity_peak_ms = e.toxicity_ms;
            ev.survivability_floor_ms = e.survivability_ms;
            ev.quarantine_peak = (e.quarantine_state == GOV_REPLAY_V1_UNSET_INT) ? 0 : e.quarantine_state;
            ev.forced_flatten_count = (e.forced_flatten_required == 1) ? 1 : 0;
            ev.containment_effectiveness_score_0_1000 = GovClampInt32(700 - ev.execution_suppression_count * 120, 0, 1000);
            ev.replay_hash = e.telemetry_line_hash_sha256_hex;
            ev.campaign_uuid = e.campaign_uuid;
            if(!GovIncidentDetectorV1_AppendEvent(out, ev))
                return false;
            run_supp = 0;
        }
        const int q = e.quarantine_state;
        if(q != GOV_REPLAY_V1_UNSET_INT && prev_q != GOV_REPLAY_V1_UNSET_INT && q > prev_q)
            run_esc = GovSaturatingAdd32(run_esc, 1);
        else
            run_esc = (q != GOV_REPLAY_V1_UNSET_INT && q > 0) ? 1 : 0;
        prev_q = q;
        if(run_esc >= 2 && q >= 2) {
            SGovIncidentEventV1 ev;
            GovernanceIncidentDatasetV1_InitEvent(ev);
            ev.incident_id = next_id++;
            ev.incident_type = (int)GOV_INCIDENT_V1_QUAR_ESCALATION;
            ev.start_epoch = tl.epochs[i - 1].epoch_id;
            ev.peak_epoch = e.epoch_id;
            ev.recovery_epoch = e.epoch_id;
            ev.quarantine_peak = q;
            ev.dominant_governance_state = e.governance_state;
            ev.dominant_regime = e.regime_state;
            ev.dominant_causal_factor = e.dominant_evidence_id;
            ev.toxicity_peak_ms = e.toxicity_ms;
            ev.survivability_floor_ms = e.survivability_ms;
            ev.forced_flatten_count = (e.forced_flatten_required == 1) ? 1 : 0;
            ev.execution_suppression_count = (e.execution_allowed == 0) ? 1 : 0;
            ev.containment_effectiveness_score_0_1000 = GovClampInt32(900 - q * 80, 0, 1000);
            ev.replay_hash = e.telemetry_line_hash_sha256_hex;
            ev.campaign_uuid = e.campaign_uuid;
            if(!GovIncidentDetectorV1_AppendEvent(out, ev))
                return false;
            run_esc = 0;
        }
    }
    return true;
}

#endif // __AURUM_GOV_INCIDENT_DETECTOR_V1_MQH__
