//+------------------------------------------------------------------+
//| GovernanceTemporalComparatorV1.mqh                             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_TMP_CMP_V1_MQH__
#define __AURUM_GOV_TMP_CMP_V1_MQH__

#include "GovernanceTemporalDatasetV1.mqh"

void GovTmpCmpV1_Diff(const SGovTemporalSummaryV1 &x, const SGovTemporalSummaryV1 &y, SGovTemporalComparisonV1 &out) {
    GovTmpDsV1_InitCmp(out);
    out.d_temporal_stability_milli = GovSaturatingAdd32(x.temporal_stability_milli, -y.temporal_stability_milli);
    out.d_long_cycle_survivability_milli = GovSaturatingAdd32(x.long_cycle_survivability_milli, -y.long_cycle_survivability_milli);
    out.d_era_transition_pressure_milli = GovSaturatingAdd32(x.era_transition_pressure_milli, -y.era_transition_pressure_milli);
    out.d_cumulative_temporal_pressure_milli = GovSaturatingAdd32(x.cumulative_temporal_pressure_milli, -y.cumulative_temporal_pressure_milli);
    out.d_decay_composite_milli = GovSaturatingAdd32(x.decay_composite_milli, -y.decay_composite_milli);
    out.d_continuity_strength_milli = GovSaturatingAdd32(x.continuity_strength_milli, -y.continuity_strength_milli);
    out.d_aging_entropy_milli = GovSaturatingAdd32(x.aging_entropy_milli, -y.aging_entropy_milli);
}

#endif // __AURUM_GOV_TMP_CMP_V1_MQH__
