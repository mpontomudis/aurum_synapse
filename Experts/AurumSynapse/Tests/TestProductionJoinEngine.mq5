//+------------------------------------------------------------------+
//|                                 TestProductionJoinEngine.mq5     |
//|     ProductionJoin_Run — Golden Suite Case_001 … Case_010       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "Phase 3B — ProductionJoin_Run full golden compatibility"

#include "../TelemetryAnalytics/ProductionJoinEngine.mqh"

bool CaseRoot(const int id, string &outRoot) {
    if(id == 1) {
        outRoot = JoinValidation_FixtureCase001Root();
        return true;
    }
    if(id == 2) {
        outRoot = JoinValidation_FixtureCase002Root();
        return true;
    }
    if(id == 3) {
        outRoot = JoinValidation_FixtureCase003Root();
        return true;
    }
    if(id == 4) {
        outRoot = JoinValidation_FixtureCase004Root();
        return true;
    }
    if(id == 5) {
        outRoot = JoinValidation_FixtureCase005Root();
        return true;
    }
    if(id == 6) {
        outRoot = JoinValidation_FixtureCase006Root();
        return true;
    }
    if(id == 7) {
        outRoot = JoinValidation_FixtureCase007Root();
        return true;
    }
    if(id == 8) {
        outRoot = JoinValidation_FixtureCase008Root();
        return true;
    }
    if(id == 9) {
        outRoot = JoinValidation_FixtureCase009Root();
        return true;
    }
    if(id == 10) {
        outRoot = JoinValidation_FixtureCase010Root();
        return true;
    }
    return false;
}

string CaseName(const int id) {
    if(id == 1)
        return "Case_001_BasicJoin";
    if(id == 2)
        return "Case_002_OrphanDeal";
    if(id == 3)
        return "Case_003_DuplicateCandidateJoin";
    if(id == 4)
        return "Case_004_FutureLeakProtection";
    if(id == 5)
        return "Case_005_MissingTelemetryRow";
    if(id == 6)
        return "Case_006_DuplicateDealTicket";
    if(id == 7)
        return "Case_007_PartialCloseLifecycle";
    if(id == 8)
        return "Case_008_PositionRollup";
    if(id == 9)
        return "Case_009_MultiDealPositionAttribution";
    if(id == 10)
        return "Case_010_TimezoneEdge_StaticOffset";
    return "unknown";
}

int ExpectedDataRows(const int id) {
    if(id == 7)
        return 3;
    if(id == 8 || id == 9)
        return 5;
    return 1;
}

long ExpectedOrphans(const int id) {
    if(id == 2)
        return 1;
    return 0;
}

bool VerifyScenarioStats(const int id) {
    if(id == 3 && JoinStats_DuplicateCandidateResolved() != 1)
        return false;
    if(id == 4 && JoinStats_FutureLeakPrevented() != 1)
        return false;
    if(id == 5 && (JoinStats_FutureLeakPrevented() != 1 || JoinStats_MissingTelemetryGap() != 1))
        return false;
    if(id == 6 && JoinStats_DuplicateDealTicket() != 1)
        return false;
    if(id == 7 && JoinStats_PartialCloseLifecycle() != 1)
        return false;
    if(id == 8 && JoinStats_PositionRollup() != 1)
        return false;
    if(id == 9 && JoinStats_MultiDealAttribution() != 1)
        return false;
    if(id == 10 && (JoinStats_FutureLeakPrevented() != 1 || JoinStats_TimezoneEdge() != 1))
        return false;
    return true;
}

int OnInit() {
    for(int id = 1; id <= 10; id++) {
        string root = "";
        if(!CaseRoot(id, root)) {
            Print("[PROD_JOIN] CASE=", CaseName(id), " STATUS=FAIL reason=bad_case_id");
            return INIT_FAILED;
        }

        const string tel = root + "telemetry.csv";
        const string deals = root + "deals.csv";
        const string expPath = root + "expected_joined.csv";
        const string outPath = root + "_prod_join_out.csv";

        Print("[PROD_JOIN] CASE=", CaseName(id));

        if(!FileIsExist(tel, FILE_COMMON) || !FileIsExist(deals, FILE_COMMON) || !FileIsExist(expPath, FILE_COMMON)) {
            Print("[PROD_JOIN] STATUS=FAIL reason=fixtures_not_in_FILE_common case=", CaseName(id));
            return INIT_FAILED;
        }

        if(!ProductionJoin_Run(tel, deals, outPath)) {
            Print("[PROD_JOIN] STATUS=FAIL reason=ProductionJoin_Run case=", CaseName(id));
            FileDelete(outPath, FILE_COMMON);
            return INIT_FAILED;
        }

        string expTxt = "";
        string actTxt = "";
        if(!JoinValidation_ReadUtf8FileLf(expPath, expTxt) || !JoinValidation_ReadUtf8FileLf(outPath, actTxt)) {
            Print("[PROD_JOIN] STATUS=FAIL reason=read_compare case=", CaseName(id));
            FileDelete(outPath, FILE_COMMON);
            return INIT_FAILED;
        }

        if(expTxt != actTxt) {
            Print("[PROD_JOIN] STATUS=FAIL reason=byte_mismatch case=", CaseName(id));
            FileDelete(outPath, FILE_COMMON);
            return INIT_FAILED;
        }

        const int expRows = ExpectedDataRows(id);
        const long expOrphans = ExpectedOrphans(id);
        if(JoinStats_DealsProcessed() != (long)expRows) {
            Print("[PROD_JOIN] STATUS=FAIL reason=stats_deals case=", CaseName(id));
            FileDelete(outPath, FILE_COMMON);
            return INIT_FAILED;
        }
        if(JoinStats_OrphanDeal() != expOrphans) {
            Print("[PROD_JOIN] STATUS=FAIL reason=stats_orphans case=", CaseName(id));
            FileDelete(outPath, FILE_COMMON);
            return INIT_FAILED;
        }
        const long expOk = (long)expRows - expOrphans;
        if(JoinStats_JoinOk() != expOk) {
            Print("[PROD_JOIN] STATUS=FAIL reason=stats_join_ok case=", CaseName(id));
            FileDelete(outPath, FILE_COMMON);
            return INIT_FAILED;
        }
        if(!VerifyScenarioStats(id)) {
            Print("[PROD_JOIN] STATUS=FAIL reason=scenario_counters case=", CaseName(id));
            FileDelete(outPath, FILE_COMMON);
            return INIT_FAILED;
        }

        Print("[PROD_JOIN] STATUS=PASS rows=", IntegerToString(expRows),
              " orphans=", IntegerToString((int)expOrphans));

        FileDelete(outPath, FILE_COMMON);
    }

    Print("[PROD_JOIN] SUITE STATUS=PASS cases=Case_001..Case_010");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    for(int id = 1; id <= 10; id++) {
        string root = "";
        if(CaseRoot(id, root))
            FileDelete(root + "_prod_join_out.csv", FILE_COMMON);
    }
}
