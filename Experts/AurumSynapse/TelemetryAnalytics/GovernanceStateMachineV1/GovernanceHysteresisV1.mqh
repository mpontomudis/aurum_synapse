//+------------------------------------------------------------------+
//| GovernanceHysteresisV1.mqh                                     |
//| Deterministic latch kernels (policy §3.2–§3.3 style).            |
//| Normative: PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md §3            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_HYSTERESIS_V1_MQH__
#define __AURUM_GOV_HYSTERESIS_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyPrimitivesV1.mqh"

//+------------------------------------------------------------------+
//| Binary latch on scalar score (toxicity / survivability style).  |
//| ON: score meets `on_ge`; OFF: score meets `off_le` (inclusive).   |
//| `cooldown_lock_epochs`: after ON→OFF, block ON for N epochs.    |
//+------------------------------------------------------------------+
void GovHysteresisV1_BinaryScoreLatchStep(const ulong gov_epoch,
                                         SGovLatchStateV1 &st,
                                         const int score,
                                         const int on_ge,
                                         const int off_le,
                                         const int dwell_esc,
                                         const int dwell_deesc,
                                         const int cooldown_lock_epochs) {
    st.last_update_epoch = gov_epoch;

    if(st.cooldown_remaining_epochs > 0) {
        st.cooldown_remaining_epochs--;
        return;
    }

    if(st.latched != 0) {
        if(score <= off_le) {
            st.dwell_deesc_count = GovSaturatingAdd32(st.dwell_deesc_count, 1);
            st.dwell_esc_count = 0;
            if(st.dwell_deesc_count >= dwell_deesc) {
                st.latched = 0;
                st.dwell_deesc_count = 0;
                if(cooldown_lock_epochs > 0)
                    st.cooldown_remaining_epochs = cooldown_lock_epochs;
            }
        } else {
            st.dwell_deesc_count = 0;
        }
    } else {
        if(score >= on_ge) {
            st.dwell_esc_count = GovSaturatingAdd32(st.dwell_esc_count, 1);
            st.dwell_deesc_count = 0;
            if(st.dwell_esc_count >= dwell_esc)
                st.latched = 1;
        } else {
            st.dwell_esc_count = 0;
        }
    }
}

#endif // __AURUM_GOV_HYSTERESIS_V1_MQH__
