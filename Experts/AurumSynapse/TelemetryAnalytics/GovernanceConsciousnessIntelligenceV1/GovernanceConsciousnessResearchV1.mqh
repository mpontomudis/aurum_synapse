//+------------------------------------------------------------------+
//| GovernanceConsciousnessResearchV1.mqh                           |
//| GOVERNANCE_CONSCIOUSNESS_INTELLIGENCE_V1 — deterministic rank      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CON_RSCH_V1_MQH__
#define __AURUM_GOV_CON_RSCH_V1_MQH__

#include "GovernanceConsciousnessDatasetV1.mqh"

bool GovConRschV1_PrefRank(const int score_a, const int score_b, const string rh_a, const string rh_b, const int id_a, const int id_b) {
    if(score_a != score_b)
        return score_a > score_b;
    if(rh_a != rh_b)
        return rh_a < rh_b;
    return id_a < id_b;
}

bool GovConResV1_Rank(const string replay_hash, const int &dim_score[], const int &dim_identity_id[], const int dim_n, int &ix_rank[], string &out_err) {
    out_err = "";
    const int nn = GovClampInt32(dim_n, 0, 16);
    ArrayResize(ix_rank, nn);
    for(int i = 0; i < nn; i++)
        ix_rank[i] = i;
    for(int i = 0; i < nn; i++) {
        int best = i;
        for(int j = i + 1; j < nn; j++) {
            const int idx_b = ix_rank[best];
            const int idx_j = ix_rank[j];
            if(GovConRschV1_PrefRank(dim_score[idx_j], dim_score[idx_b], replay_hash, replay_hash, dim_identity_id[idx_j], dim_identity_id[idx_b]))
                best = j;
        }
        const int sw = ix_rank[i];
        ix_rank[i] = ix_rank[best];
        ix_rank[best] = sw;
    }
    return true;
}

#endif // __AURUM_GOV_CON_RSCH_V1_MQH__
