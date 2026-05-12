//+------------------------------------------------------------------+
//|                                           SessionAnalytics.mqh   |
//|     Group by session_code + hour_wit (CSV-native).             |
//+------------------------------------------------------------------+
#ifndef __AURUM_SESSION_ANALYTICS_MQH__
#define __AURUM_SESSION_ANALYTICS_MQH__

#include "AnalyticsTypes.mqh"

#define SESSION_ANALYTICS_BUCKETS  8

struct SessionAnalyticsState {
    ulong         bars[SESSION_ANALYTICS_BUCKETS];
    RunningStatD  quality[SESSION_ANALYTICS_BUCKETS];
    RunningStatD  agreement[SESSION_ANALYTICS_BUCKETS];
    RunningStatI  consensusCode[SESSION_ANALYTICS_BUCKETS];
};

void SessionAnalytics_Reset(SessionAnalyticsState &s) {
    for(int i = 0; i < SESSION_ANALYTICS_BUCKETS; i++) {
        s.bars[i] = 0;
        s.quality[i].Reset();
        s.agreement[i].Reset();
        s.consensusCode[i].Reset();
    }
}

int SessionAnalytics_Bucket(const TelemetryCsvRow &row) {
    if(row.null_session)
        return 7;
    int b = row.session_code;
    if(b < 0 || b >= SESSION_ANALYTICS_BUCKETS - 1)
        return SESSION_ANALYTICS_BUCKETS - 1;
    return b;
}

void SessionAnalytics_Feed(SessionAnalyticsState &s, const TelemetryCsvRow &row) {
    const int k = SessionAnalytics_Bucket(row);
    s.bars[k]++;
    s.quality[k].Add(row.quality, row.null_quality);
    s.agreement[k].Add(row.agreement_pct, row.null_agreement);
    bool nc = row.null_consensus;
    s.consensusCode[k].Add(row.consensus_code, nc);
}

string SessionAnalytics_BucketLabel(const int k) {
    switch(k) {
        case 0: return "SESSION_ASIAN";
        case 1: return "SESSION_LONDON";
        case 2: return "SESSION_NEWYORK";
        case 3: return "SESSION_OVERLAP";
        default:
            if(k == 7)
                return "SESSION_UNKNOWN";
            return "SESSION_OTHER";
    }
}

#endif // __AURUM_SESSION_ANALYTICS_MQH__
