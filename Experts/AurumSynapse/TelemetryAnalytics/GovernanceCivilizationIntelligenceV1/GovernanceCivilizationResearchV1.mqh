//+------------------------------------------------------------------+
//| GovernanceCivilizationResearchV1.mqh                           |
//| Deterministic civilization ranking (no STL).                     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CIV_RES_V1_MQH__
#define __AURUM_GOV_CIV_RES_V1_MQH__

#include "GovernanceCivilizationDatasetV1.mqh"

bool GovCivResV1_IxBetter(const SGovCivilizationNodeV1 &nodes[], const SGovCivilizationFederationV1 &fed, const int ia, const int ib) {
    if(nodes[ia].survivability_score_milli != nodes[ib].survivability_score_milli)
        return (nodes[ia].survivability_score_milli > nodes[ib].survivability_score_milli);
    const int ca = GovClampInt32(1000000 - nodes[ia].collapse_risk_milli, 0, 1000000);
    const int cb = GovClampInt32(1000000 - nodes[ib].collapse_risk_milli, 0, 1000000);
    if(ca != cb)
        return (ca > cb);
    const int cona = GovSaturatingAdd32(nodes[ia].survivability_score_milli, -nodes[ia].fatigue_score_milli / 4);
    const int conb = GovSaturatingAdd32(nodes[ib].survivability_score_milli, -nodes[ib].fatigue_score_milli / 4);
    if(cona != conb)
        return (cona > conb);
    const int fa = GovSaturatingAdd32(ca / 8, fed.federation_stability_milli / 1000);
    const int fb = GovSaturatingAdd32(cb / 8, fed.federation_stability_milli / 1000);
    if(fa != fb)
        return (fa > fb);
    return (nodes[ia].civilization_id < nodes[ib].civilization_id);
}

bool GovCivResV1_RankCivilizations(const SGovCivilizationNodeV1 &nodes[], const int n, const SGovCivilizationFederationV1 &fed, int &ix_order[], string &out_err) {
    out_err = "";
    if(n < 1 || n > 32) {
        out_err = "GOV_CIV_RES_N";
        return false;
    }
    for(int i = 0; i < n; i++)
        ix_order[i] = i;
    for(int i = 0; i < n; i++) {
        int best = i;
        for(int j = i + 1; j < n; j++) {
            if(GovCivResV1_IxBetter(nodes, fed, ix_order[j], ix_order[best]))
                best = j;
        }
        const int t = ix_order[i];
        ix_order[i] = ix_order[best];
        ix_order[best] = t;
    }
    return true;
}

#endif // __AURUM_GOV_CIV_RES_V1_MQH__
