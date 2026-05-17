//+------------------------------------------------------------------+
//| GovEvidenceFromRollupV1.mqh                                    |
//| Adapter: POSITION_ROLLUP_V1 → runtime evidence (read-only).     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_EVID_FROM_ROLLUP_V1_MQH__
#define __AURUM_GOV_EVID_FROM_ROLLUP_V1_MQH__

#include "../PositionRollupV1.mqh"
#include "GovernanceL0RuntimeEvidenceV1.mqh"
#include "GovernanceEvidenceNormalizerV1.mqh"

void GovEvidenceFromRollupV1_Apply(const SRollupPositionCampaignV1 &camp,
                                   SGovL0RuntimeEvidenceV1 &io) {
    if(!camp.valid)
        return;
    io.lifecycle_id = camp.lifecycle_group_id;
    io.campaign_uuid = "GW1:" + IntegerToString((long)camp.root_position_id);
    io.campaign_duration_epochs = GovClampInt32(camp.deal_count, 0, 1000000);
    const long span = (long)camp.lifecycle_close_time_utc - (long)camp.lifecycle_open_time_utc;
    int span_clamped = 0;
    if(span < 0)
        span_clamped = 0;
    else if(span > (long)GOV_EVID_MILLI_MAX)
        span_clamped = GOV_EVID_MILLI_MAX;
    else
        span_clamped = (int)span;
    io.drawdown_pressure_ms = GovEvidenceNormV1_ClampMilli(span_clamped);
    if(camp.lifecycle_state == LIFECYCLE_V1_ACTIVE_NONZERO)
        io.active_recovery_depth = GovClampInt32(camp.deal_count, 0, 1000);
    else
        io.active_recovery_depth = 0;
}

#endif // __AURUM_GOV_EVID_FROM_ROLLUP_V1_MQH__
