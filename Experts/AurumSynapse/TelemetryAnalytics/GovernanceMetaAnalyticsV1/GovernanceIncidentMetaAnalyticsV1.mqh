//+------------------------------------------------------------------+
//| GovernanceIncidentMetaAnalyticsV1.mqh                           |
//| Longitudinal aggregation over incident summaries (deterministic).  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_INCIDENT_META_ANALYTICS_V1_MQH__
#define __AURUM_GOV_INCIDENT_META_ANALYTICS_V1_MQH__

#include "../GovernanceIncidentIntelligenceV1/GovernanceIncidentDatasetV1.mqh"
#include "GovernanceMetaAnalyticsDatasetV1.mqh"

void GovIncMetaV1_Init(SGovMetaIncidentStatsV1 &acc) {
    GovernanceMetaAnalyticsDatasetV1_InitIncidentStats(acc);
}

bool GovIncMetaV1_Acc(const SGovIncidentSummaryV1 &s, const int replay_epoch_count, SGovMetaIncidentStatsV1 &acc) {
    acc.raw_epoch_denominator = GovSaturatingAdd32(acc.raw_epoch_denominator, GovClampInt32(replay_epoch_count, 0, 1000000000));
    const int n = ArraySize(s.events);
    acc.raw_incident_total = GovSaturatingAdd32(acc.raw_incident_total, n);
    long lat_sum = 0;
    int lat_n = 0;
    for(int i = 0; i < n; i++) {
        const SGovIncidentEventV1 e = s.events[i];
        if(e.incident_type == (int)GOV_INCIDENT_V1_TOX_SPIRAL)
            acc.raw_toxic_spiral = GovSaturatingAdd32(acc.raw_toxic_spiral, 1);
        else if(e.incident_type == (int)GOV_INCIDENT_V1_SURV_COLLAPSE)
            acc.raw_survivability_collapse = GovSaturatingAdd32(acc.raw_survivability_collapse, 1);
        else if(e.incident_type == (int)GOV_INCIDENT_V1_FALSE_RECOVERY)
            acc.raw_false_recovery = GovSaturatingAdd32(acc.raw_false_recovery, 1);
        else if(e.incident_type == (int)GOV_INCIDENT_V1_QUAR_ESCALATION)
            acc.raw_quarantine_escalation = GovSaturatingAdd32(acc.raw_quarantine_escalation, 1);
        else if(e.incident_type == (int)GOV_INCIDENT_V1_EXEC_SUPPRESSION)
            acc.raw_exec_suppression = GovSaturatingAdd32(acc.raw_exec_suppression, 1);
        else if(e.incident_type == (int)GOV_INCIDENT_V1_REGIME_BREAKDOWN)
            acc.raw_regime_breakdown = GovSaturatingAdd32(acc.raw_regime_breakdown, 1);
        acc.raw_forced_flatten_sum = GovSaturatingAdd32(acc.raw_forced_flatten_sum, GovClampInt32(e.forced_flatten_count, 0, 1000));
        const int ce = GovClampInt32(e.containment_effectiveness_score_0_1000, 0, 1000);
        acc.internal_containment_eff_sum = GovSaturatingAdd32(acc.internal_containment_eff_sum, ce);
        acc.internal_containment_eff_n = GovSaturatingAdd32(acc.internal_containment_eff_n, 1);
        int sf = e.survivability_floor_ms;
        if(sf == GOV_REPLAY_V1_UNSET_INT)
            sf = 0;
        acc.internal_surv_pres_sum = GovSaturatingAdd32(acc.internal_surv_pres_sum, GovClampInt32(sf * 1000 / 5000, 0, 1000));
        acc.internal_surv_pres_n = GovSaturatingAdd32(acc.internal_surv_pres_n, 1);
        const int rs = (e.recovery_epoch > e.peak_epoch) ? 400 : 200;
        acc.internal_rec_stab_sum = GovSaturatingAdd32(acc.internal_rec_stab_sum, rs);
        acc.internal_rec_stab_n = GovSaturatingAdd32(acc.internal_rec_stab_n, 1);
        const long span64 = (long)e.recovery_epoch - (long)e.start_epoch;
        if(span64 > 0) {
            lat_sum += span64;
            lat_n = GovSaturatingAdd32(lat_n, 1);
        }
    }
    if(lat_n > 0) {
        const long avg = lat_sum / (long)lat_n;
        const int chunk_avg = GovSaturateLongToInt32(avg);
        acc.governance_response_latency_avg_epochs = (acc.governance_response_latency_avg_epochs == 0)
                                                         ? chunk_avg
                                                         : (acc.governance_response_latency_avg_epochs + chunk_avg) / 2;
    }
    return true;
}

void GovIncMetaV1_Finalize(SGovMetaIncidentStatsV1 &io) {
    const int d = GovClampInt32(io.raw_epoch_denominator, 0, 1000000000);
    const int den = (d > 0) ? d : 1;
    io.incident_frequency_per_1000_epochs = GovernanceMetaAnalyticsDatasetV1_RatePer1000(io.raw_incident_total, den);
    io.toxic_spiral_frequency_per_1000_epochs = GovernanceMetaAnalyticsDatasetV1_RatePer1000(io.raw_toxic_spiral, den);
    io.survivability_collapse_frequency_per_1000_epochs = GovernanceMetaAnalyticsDatasetV1_RatePer1000(io.raw_survivability_collapse, den);
    const int quar_inc = GovSaturatingAdd32(io.raw_quarantine_escalation, io.raw_false_recovery);
    const int r_quar_inc = GovernanceMetaAnalyticsDatasetV1_RatePer1000(quar_inc, den);
    const int r_q_epochs = GovernanceMetaAnalyticsDatasetV1_RatePer1000(io.raw_quarantine_epoch_hits, den);
    io.quarantine_frequency_per_1000_epochs = GovClampInt32(GovSaturatingAdd32(r_quar_inc, r_q_epochs), 0, 2000);
    io.forced_flatten_frequency_per_1000_epochs = GovernanceMetaAnalyticsDatasetV1_RatePer1000(io.raw_forced_flatten_sum, den);
    io.regime_breakdown_density_per_1000_epochs = GovernanceMetaAnalyticsDatasetV1_RatePer1000(io.raw_regime_breakdown, den);
    if(io.internal_containment_eff_n > 0)
        io.containment_success_rate_0_1000 = GovClampInt32(io.internal_containment_eff_sum / io.internal_containment_eff_n, 0, 1000);
    if(io.internal_surv_pres_n > 0)
        io.survivability_preservation_score_0_1000 = GovClampInt32(io.internal_surv_pres_sum / io.internal_surv_pres_n, 0, 1000);
    if(io.internal_rec_stab_n > 0)
        io.recovery_stabilization_score_0_1000 = GovClampInt32(io.internal_rec_stab_sum / io.internal_rec_stab_n, 0, 1000);
}

bool GovIncMetaV1_AccQEp(const SGovReplayTimelineV1 &t, SGovMetaIncidentStatsV1 &acc) {
    const int n = ArraySize(t.epochs);
    for(int i = 0; i < n; i++) {
        const int qs = t.epochs[i].quarantine_state;
        if(qs >= 1)
            acc.raw_quarantine_epoch_hits = GovSaturatingAdd32(acc.raw_quarantine_epoch_hits, 1);
    }
    return true;
}

#endif // __AURUM_GOV_INCIDENT_META_ANALYTICS_V1_MQH__
