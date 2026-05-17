//+------------------------------------------------------------------+
//| GovernanceCollapseResistanceV1.mqh                             |
//| Collapse resistance from incidents + containment (integer).      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CLPS_RES_V1_MQH__
#define __AURUM_GOV_CLPS_RES_V1_MQH__

#include "GovernanceResilienceDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceContainmentAnalyticsV1.mqh"
#include "../GovernanceIncidentIntelligenceV1/GovernanceIncidentDatasetV1.mqh"

bool GovClpsResV1_Score(const SGovReplayTimelineV1 &tl, const SGovContainmentMetricsV1 &cm, const SGovIncidentSummaryV1 &isum, SGovCollapseResistanceV1 &out, string &out_err) {
    out_err = "";
    GovResilDsV1_InitCollapse(out);
    const int n = ArraySize(tl.epochs);
    int min_sv = GOV_REPLAY_V1_UNSET_INT;
    for(int i = 0; i < n; i++) {
        const int sv = tl.epochs[i].survivability_ms;
        if(sv != GOV_REPLAY_V1_UNSET_INT) {
            if(min_sv == GOV_REPLAY_V1_UNSET_INT || sv < min_sv)
                min_sv = sv;
        }
    }
    int tox_sp = 0;
    int surv_cl = 0;
    int quar_es = 0;
    int flat_cs = 0;
    int exec_cs = 0;
    const int ne = ArraySize(isum.events);
    for(int k = 0; k < ne; k++) {
        const int ty = isum.events[k].incident_type;
        if(ty == (int)GOV_INCIDENT_V1_TOX_SPIRAL)
            tox_sp = GovSaturatingAdd32(tox_sp, 1);
        else if(ty == (int)GOV_INCIDENT_V1_SURV_COLLAPSE)
            surv_cl = GovSaturatingAdd32(surv_cl, 1);
        else if(ty == (int)GOV_INCIDENT_V1_QUAR_ESCALATION)
            quar_es = GovSaturatingAdd32(quar_es, 1);
        else if(ty == (int)GOV_INCIDENT_V1_EXEC_SUPPRESSION)
            exec_cs = GovSaturatingAdd32(exec_cs, 1);
        flat_cs = GovSaturatingAdd32(flat_cs, isum.events[k].forced_flatten_count);
    }
    int score = 1000;
    score = GovSaturatingAdd32(score, -tox_sp * 140);
    score = GovSaturatingAdd32(score, -surv_cl * 160);
    score = GovSaturatingAdd32(score, -quar_es * 90);
    score = GovSaturatingAdd32(score, -exec_cs * 80);
    score = GovSaturatingAdd32(score, -GovClampInt32(flat_cs * 40, 0, 400));
    if(min_sv != GOV_REPLAY_V1_UNSET_INT)
        score = GovSaturatingAdd32(score, GovClampInt32(min_sv / 8, 0, 200));
    score = GovSaturatingAdd32(score, GovClampInt32(cm.prevented_escalation_epochs * 25, 0, 200));
    out.collapse_resistance_score_0_1000 = GovClampInt32(score, 0, 1000);
    out.resilience_interruption_efficiency_0_1000 = GovClampInt32(1000 - tox_sp * 120 - surv_cl * 120, 0, 1000);
    int lat = n;
    for(int j = 0; j < ne; j++) {
        const ulong rec = isum.events[j].recovery_epoch;
        const ulong st = isum.events[j].start_epoch;
        if(rec > st && rec < 1000000000UL) {
            const int d = GovSaturateLongToInt32((long)(rec - st));
            if(d >= 0 && d < lat)
                lat = d;
        }
    }
    if(lat >= n)
        lat = GovClampInt32(n / 2, 0, n);
    out.stabilization_interruption_latency_epochs = GovClampInt32(lat, 0, 1000000);
    out.containment_interruption_quality_0_1000 = GovClampInt32(cm.prevented_escalation_epochs * 80 + cm.toxic_interrupt_epochs * 40, 0, 1000);
    return true;
}

#endif // __AURUM_GOV_CLPS_RES_V1_MQH__
