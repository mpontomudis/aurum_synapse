//+------------------------------------------------------------------+
//| GovernanceReplaySimulationLabV1.mqh                          |
//| Multi-archetype lanes on same replay (sandbox copies).          |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RPL_SIM_LAB_V1_MQH__
#define __AURUM_GOV_RPL_SIM_LAB_V1_MQH__

#include "GovernanceSimulationDatasetV1.mqh"
#include "GovernanceStressTestEngineV1.mqh"
#include "GovernancePolicyArchetypeLabV1.mqh"
#include "GovernanceStabilityEngineV1.mqh"
#include "../GovernanceIncidentIntelligenceV1/GovernanceIncidentDetectorV1.mqh"
#include "../GovernanceReplayVisualIntelligenceV1/GovernanceReplayDatasetV1.mqh"

bool GovRplSimLabV1_RunMulti(const SGovReplayTimelineV1 &src, int &arch_ids[], const int arch_n, SGovSimPolicyRunV1 &runs[], string &out_err) {
    out_err = "";
    ArrayResize(runs, 0);
    if(arch_n < 1 || arch_n > 16) {
        out_err = "SIM_ARCH_N";
        return false;
    }
    ArrayResize(runs, arch_n);
    for(int a = 0; a < arch_n; a++) {
        const int aid = arch_ids[a];
        GovSimDsV1_InitRun(runs[a]);
        runs[a].archetype_id = aid;
        runs[a].stress_lane_code = GovArchLabV1_ToStress(aid);
        SGovReplayTimelineV1 lane;
        if(!GovStressV1_Apply(src, runs[a].stress_lane_code, lane, out_err))
            return false;
        runs[a].epoch_count = ArraySize(lane.epochs);
        if(!GovStabEngV1_Measure(lane, runs[a].stability, out_err))
            return false;
        runs[a].governance_health_proxy_0_1000 = GovStabEngV1_HealthProxy(runs[a].stability);
        SGovIncidentSummaryV1 isum;
        string e2 = "";
        if(!GovernanceIncidentDetectorV1_DetectAll(lane, isum, e2)) {
            out_err = e2;
            return false;
        }
        runs[a].incident_count = ArraySize(isum.events);
        runs[a].lane_note = "ARCH=" + IntegerToString(aid) + "|STR=" + IntegerToString(runs[a].stress_lane_code);
    }
    return true;
}

#endif // __AURUM_GOV_RPL_SIM_LAB_V1_MQH__
