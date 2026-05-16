//+------------------------------------------------------------------+
//|                                      TestJoinStatistics.mq5      |
//|     JoinStats_* counters — deterministic smoke                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "Phase 3B — JoinStatistics counter harness"

#include "../TelemetryAnalytics/JoinStatistics.mqh"

bool ExpectLong(const string name, const long actual, const long expected) {
    if(actual != expected) {
        Print("[JOIN_STATS_TEST] FAIL ", name, " expected=", IntegerToString((int)expected),
              " got=", IntegerToString((int)actual));
        return false;
    }
    return true;
}

void IncAllOnce(void) {
    JoinStats_IncDealsProcessed();
    JoinStats_IncJoinOk();
    JoinStats_IncOrphanDeal();
    JoinStats_IncDuplicateCandidateResolved();
    JoinStats_IncFutureLeakPrevented();
    JoinStats_IncMissingTelemetryGap();
    JoinStats_IncDuplicateDealTicket();
    JoinStats_IncPartialCloseLifecycle();
    JoinStats_IncPositionRollup();
    JoinStats_IncMultiDealAttribution();
    JoinStats_IncTimezoneEdge();
}

bool VerifyAll(const long v) {
    if(!ExpectLong("DealsProcessed", JoinStats_DealsProcessed(), v))
        return false;
    if(!ExpectLong("JoinOk", JoinStats_JoinOk(), v))
        return false;
    if(!ExpectLong("OrphanDeal", JoinStats_OrphanDeal(), v))
        return false;
    if(!ExpectLong("DuplicateCandidateResolved", JoinStats_DuplicateCandidateResolved(), v))
        return false;
    if(!ExpectLong("FutureLeakPrevented", JoinStats_FutureLeakPrevented(), v))
        return false;
    if(!ExpectLong("MissingTelemetryGap", JoinStats_MissingTelemetryGap(), v))
        return false;
    if(!ExpectLong("DuplicateDealTicket", JoinStats_DuplicateDealTicket(), v))
        return false;
    if(!ExpectLong("PartialCloseLifecycle", JoinStats_PartialCloseLifecycle(), v))
        return false;
    if(!ExpectLong("PositionRollup", JoinStats_PositionRollup(), v))
        return false;
    if(!ExpectLong("MultiDealAttribution", JoinStats_MultiDealAttribution(), v))
        return false;
    if(!ExpectLong("TimezoneEdge", JoinStats_TimezoneEdge(), v))
        return false;
    return true;
}

int OnInit() {
    JoinStats_Reset();
    if(!VerifyAll(0)) {
        return INIT_FAILED;
    }

    IncAllOnce();
    if(!VerifyAll(1)) {
        return INIT_FAILED;
    }

    JoinStats_Reset();
    if(!VerifyAll(0)) {
        return INIT_FAILED;
    }

    JoinStats_IncJoinOk();
    JoinStats_IncJoinOk();
    JoinStats_IncJoinOk();
    if(!ExpectLong("JoinOk_repeat", JoinStats_JoinOk(), 3))
        return INIT_FAILED;
    if(!ExpectLong("JoinOk_isolated", JoinStats_DealsProcessed(), 0))
        return INIT_FAILED;

    JoinStats_Reset();
    IncAllOnce();
    IncAllOnce();
    if(!VerifyAll(2)) {
        return INIT_FAILED;
    }

    Print("[JOIN_STATS_TEST] PASS counters deterministic");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}
