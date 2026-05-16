//+------------------------------------------------------------------+
//|                                        JoinStatistics.mqh        |
//|     Phase 3B — read-only deterministic join observability       |
//|     Integer counters only; no file I/O; no EA / trade hooks.    |
//+------------------------------------------------------------------+
#ifndef __AURUM_JOIN_STATISTICS_MQH__
#define __AURUM_JOIN_STATISTICS_MQH__

// All counters are process-wide (single compilation unit). No threading contract.

static long g_js_deals_processed              = 0;
static long g_js_join_ok                     = 0;
static long g_js_orphan_deal                 = 0;
static long g_js_duplicate_candidate_resolved = 0;
static long g_js_future_leak_prevented       = 0;
static long g_js_missing_telemetry_gap       = 0;
static long g_js_duplicate_deal_ticket       = 0;
static long g_js_partial_close_lifecycle     = 0;
static long g_js_position_rollup             = 0;
static long g_js_multi_deal_attribution      = 0;
static long g_js_timezone_edge               = 0;

//+------------------------------------------------------------------+
//| Safe reset: all counters to zero (idempotent).                 |
//+------------------------------------------------------------------+
void JoinStats_Reset(void) {
    g_js_deals_processed = 0;
    g_js_join_ok = 0;
    g_js_orphan_deal = 0;
    g_js_duplicate_candidate_resolved = 0;
    g_js_future_leak_prevented = 0;
    g_js_missing_telemetry_gap = 0;
    g_js_duplicate_deal_ticket = 0;
    g_js_partial_close_lifecycle = 0;
    g_js_position_rollup = 0;
    g_js_multi_deal_attribution = 0;
    g_js_timezone_edge = 0;
}

void JoinStats_IncDealsProcessed(void)              { g_js_deals_processed++; }
void JoinStats_IncJoinOk(void)                       { g_js_join_ok++; }
void JoinStats_IncOrphanDeal(void)                   { g_js_orphan_deal++; }
void JoinStats_IncDuplicateCandidateResolved(void) { g_js_duplicate_candidate_resolved++; }
void JoinStats_IncFutureLeakPrevented(void)          { g_js_future_leak_prevented++; }
void JoinStats_IncMissingTelemetryGap(void)         { g_js_missing_telemetry_gap++; }
void JoinStats_IncDuplicateDealTicket(void)         { g_js_duplicate_deal_ticket++; }
void JoinStats_IncPartialCloseLifecycle(void)       { g_js_partial_close_lifecycle++; }
void JoinStats_IncPositionRollup(void)              { g_js_position_rollup++; }
void JoinStats_IncMultiDealAttribution(void)        { g_js_multi_deal_attribution++; }
void JoinStats_IncTimezoneEdge(void)                { g_js_timezone_edge++; }

long JoinStats_DealsProcessed(void)              { return g_js_deals_processed; }
long JoinStats_JoinOk(void)                     { return g_js_join_ok; }
long JoinStats_OrphanDeal(void)                 { return g_js_orphan_deal; }
long JoinStats_DuplicateCandidateResolved(void) { return g_js_duplicate_candidate_resolved; }
long JoinStats_FutureLeakPrevented(void)       { return g_js_future_leak_prevented; }
long JoinStats_MissingTelemetryGap(void)       { return g_js_missing_telemetry_gap; }
long JoinStats_DuplicateDealTicket(void)       { return g_js_duplicate_deal_ticket; }
long JoinStats_PartialCloseLifecycle(void)     { return g_js_partial_close_lifecycle; }
long JoinStats_PositionRollup(void)            { return g_js_position_rollup; }
long JoinStats_MultiDealAttribution(void)      { return g_js_multi_deal_attribution; }
long JoinStats_TimezoneEdge(void)              { return g_js_timezone_edge; }

#endif // __AURUM_JOIN_STATISTICS_MQH__
