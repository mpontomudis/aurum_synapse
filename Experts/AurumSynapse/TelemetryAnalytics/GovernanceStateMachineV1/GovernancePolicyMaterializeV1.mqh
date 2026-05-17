//+------------------------------------------------------------------+
//| GovernancePolicyMaterializeV1.mqh                             |
//| Materialize typed governance parameters after checksum OK.       |
//| Requires explicit gov_defaults_phase8_embedded=1 (fail-closed).  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POLICY_MATERIALIZE_V1_MQH__
#define __AURUM_GOV_POLICY_MATERIALIZE_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"
#include "GovernancePolicyPhase8DefaultsV1.mqh"

#define GOV_V1_K_GOV_DEFAULTS_EMBED "gov_defaults_phase8_embedded"

//+------------------------------------------------------------------+
bool GovPolicyMatV1_KvGet(SCGovPolicySnapshotV1 &s, const string key, string &out_val) {
    for(int i = 0; i < s.kv_count; i++) {
        if(s.kv_key[i] == key) {
            out_val = s.kv_val[i];
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
bool GovPolicySnapshotV1_MaterializeGovernance(SCGovPolicySnapshotV1 &snap,
                                               ENUM_GOV_POLICY_LOAD_ERR_V1 &out_err) {
    out_err = GOV_LOAD_ERR_V1_OK;
    string v = "";
    if(!GovPolicyMatV1_KvGet(snap, GOV_V1_K_GOV_DEFAULTS_EMBED, v)) {
        out_err = GOV_LOAD_ERR_V1_GOV_PARAMS_INCOMPLETE;
        return false;
    }
    if(StringToInteger(v) != 1) {
        out_err = GOV_LOAD_ERR_V1_GOV_PARAMS_INCOMPLETE;
        return false;
    }
    snap.gov_defaults_phase8_embedded = 1;
    GovPolicyPhase8DefaultsV1_Apply(snap);
    return true;
}

#endif // __AURUM_GOV_POLICY_MATERIALIZE_V1_MQH__
