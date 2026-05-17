//+------------------------------------------------------------------+
//| GovernanceEcologyResearchV1.mqh                                 |
//| GOVERNANCE_ECOLOGY_INTELLIGENCE_V1 — deterministic ranking       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_ECO_RSCH_V1_MQH__
#define __AURUM_GOV_ECO_RSCH_V1_MQH__

#include "GovernanceEcologyDatasetV1.mqh"

int GovEcoRschV1_EntityScore(const SGovEcologyEntityV1 &e) {
    return GovClampInt32(GovSaturatingAdd32(e.survivability_milli, GovSaturatingAdd32(-e.collapse_exposure_milli / 3, e.recovery_coexistence_milli / 4)), -1000000000, 1000000000);
}

bool GovEcoRschV1_PrefRank(const SGovEcologyEntityV1 &prefer, const SGovEcologyEntityV1 &than) {
    const int sp = GovEcoRschV1_EntityScore(prefer);
    const int st = GovEcoRschV1_EntityScore(than);
    if(sp != st)
        return sp > st;
    if(prefer.ecosystem_id != than.ecosystem_id)
        return prefer.ecosystem_id < than.ecosystem_id;
    return prefer.replay_hash < than.replay_hash;
}

bool GovEcoResV1_Rank(const SGovEcologyEntityV1 &ents[], const int n, int &ix_rank[], string &out_err) {
    out_err = "";
    const int nn = GovClampInt32(n, 0, 64);
    ArrayResize(ix_rank, nn);
    for(int i = 0; i < nn; i++)
        ix_rank[i] = i;
    for(int i = 0; i < nn; i++) {
        int best = i;
        for(int j = i + 1; j < nn; j++) {
            const int idx_j = ix_rank[j];
            const int idx_b = ix_rank[best];
            if(GovEcoRschV1_PrefRank(ents[idx_j], ents[idx_b]))
                best = j;
        }
        const int swap = ix_rank[i];
        ix_rank[i] = ix_rank[best];
        ix_rank[best] = swap;
    }
    return true;
}

#endif // __AURUM_GOV_ECO_RSCH_V1_MQH__
