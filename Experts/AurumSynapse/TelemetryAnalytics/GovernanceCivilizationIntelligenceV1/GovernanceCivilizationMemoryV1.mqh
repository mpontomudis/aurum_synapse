//+------------------------------------------------------------------+
//| GovernanceCivilizationMemoryV1.mqh                             |
//| Single-pass deterministic memory view + integer EWMA.          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_MEM_V1_MQH__
#define __AURUM_GOV_CIV_MEM_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

bool GovCivMemV1_Update(const SGovEvolutionGenerationV1 &gens[], const int n, const SGovDegenerationV1 &dg, SGovCivilizationMemoryV1 &out, string &out_err) {
    out_err = "";
    GovCivDsV1_InitMem(out);
    if(n < 1 || n > 32) {
        out_err = "GOV_CIV_MEM_N";
        return false;
    }
    int cyc = 0;
    int rec_acc = 0;
    int stable = 0;
    long ew_f = 0;
    long ew_r = 0;
    const int dgv = GovClampInt32(dg.degeneration_velocity_milli, 0, 100000000);
    const int csp = GovClampInt32(dg.collapse_susceptibility_0_1000, 0, 1000);
    for(int i = 0; i < n; i++) {
        cyc = GovSaturatingAdd32(cyc, GovClampInt32(gens[i].replay_epoch_count, 0, 1000000));
        rec_acc = GovSaturatingAdd32(rec_acc, GovClampInt32(gens[i].recovery_elasticity_0_1000, 0, 1000));
        if(GovClampInt32(gens[i].degeneration_velocity_milli, 0, 100000000) < 5000)
            stable = GovSaturatingAdd32(stable, 1);
        const long f_in = (long)GovClampInt32(gens[i].fatigue_index_0_1000, 0, 1000) * 1000L;
        const long r_in = (long)GovClampInt32(gens[i].resilience_profile_0_1000, 0, 1000) * 1000L;
        ew_f = (ew_f * 7L + f_in) / 8L;
        ew_r = (ew_r * 7L + r_in) / 8L;
    }
    out.civilization_cycles = cyc;
    out.collapse_cycles = GovClampInt32((dgv / 1000) * n + (csp * n) / 1000, 0, 100000000);
    out.recovery_cycles = GovClampInt32((rec_acc * 1000) / GovClampInt32(n, 1, 32), 0, 100000000);
    out.stable_cycles = stable;
    out.cumulative_fatigue_milli = GovClampInt32((int)ew_f, 0, 1000000000);
    out.cumulative_resilience_milli = GovClampInt32((int)ew_r, 0, 1000000000);
    return true;
}

#endif // __AURUM_GOV_CIV_MEM_V1_MQH__
