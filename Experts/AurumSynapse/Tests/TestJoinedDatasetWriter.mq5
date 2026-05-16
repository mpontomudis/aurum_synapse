//+------------------------------------------------------------------+
//|                                  TestJoinedDatasetWriter.mq5     |
//|     Smoke: Open / WriteJoinedRow / Close — FILE_COMMON bytes     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "JoinedDatasetWriter UTF-8 LF no-BOM smoke (writes under Common\\Files only when run)"

#include "../TelemetryAnalytics/JoinedDatasetWriter.mqh"

static const string K_REL = "AurumSynapse\\Tests\\_joined_dataset_writer_smoke.csv";

bool SmokeReadAllBytesCommon(const string rel, uchar &out[]) {
    ArrayResize(out, 0);
    const int fh = FileOpen(rel, FILE_READ | FILE_BIN | FILE_COMMON);
    if(fh == INVALID_HANDLE)
        return false;
    const long szl = FileGetInteger(fh, FILE_SIZE);
    if(szl < 0 || szl > 1000000) {
        FileClose(fh);
        return false;
    }
    const int sz = (int)szl;
    ArrayResize(out, sz);
    if(sz > 0 && FileReadArray(fh, out, 0, sz) != (uint)sz) {
        FileClose(fh);
        return false;
    }
    FileClose(fh);
    return true;
}

bool BytesHaveCrLfOrBom(const uchar &raw[], const int sz) {
    if(sz >= 3 && raw[0] == 0xEF && raw[1] == 0xBB && raw[2] == 0xBF)
        return true;
    if(sz >= 2 && raw[0] == 0xFE && raw[1] == 0xFF)
        return true;
    for(int i = 0; i < sz; i++) {
        if(raw[i] == 0x0D)
            return true;
    }
    return false;
}

int OnInit() {
    const string line0 = "joined_schema,joined_major,joined_minor";
    const string line1 = "AS_JOINED_V1,1,0,J1-DEALTIME-BACKWARD-BAR,900001";
    const string line2 = "AS_JOINED_V1,1,0,J1-DEALTIME-BACKWARD-BAR,900002";
    const string expected = line0 + "\n" + line1 + "\n" + line2 + "\n";

    if(!OpenJoinedDatasetWriter(K_REL)) {
        Print("[JOINED_WRITER_TEST] FAIL Open");
        return INIT_FAILED;
    }
    if(JoinedDatasetWriter_RowsWrittenSuccess() != 0 || JoinedDatasetWriter_RowsFailed() != 0) {
        Print("[JOINED_WRITER_TEST] FAIL stats not zero after open");
        CloseJoinedDatasetWriter();
        return INIT_FAILED;
    }
    if(!WriteJoinedRow(line0) || !WriteJoinedRow(line1) || !WriteJoinedRow(line2)) {
        Print("[JOINED_WRITER_TEST] FAIL Write rows ok=", IntegerToString(JoinedDatasetWriter_RowsWrittenSuccess()),
              " fail=", IntegerToString(JoinedDatasetWriter_RowsFailed()));
        CloseJoinedDatasetWriter();
        return INIT_FAILED;
    }
    if(!CloseJoinedDatasetWriter()) {
        Print("[JOINED_WRITER_TEST] FAIL Close");
        return INIT_FAILED;
    }
    if(JoinedDatasetWriter_RowsWrittenSuccess() != 3) {
        Print("[JOINED_WRITER_TEST] FAIL row count expected=3 got=", IntegerToString(JoinedDatasetWriter_RowsWrittenSuccess()));
        return INIT_FAILED;
    }
    if(JoinedDatasetWriter_RowsFailed() != 0) {
        Print("[JOINED_WRITER_TEST] FAIL unexpected write failures");
        return INIT_FAILED;
    }

    uchar raw[];
    if(!SmokeReadAllBytesCommon(K_REL, raw)) {
        Print("[JOINED_WRITER_TEST] FAIL read back");
        return INIT_FAILED;
    }
    const int sz = ArraySize(raw);
    if(sz != StringLen(expected)) {
        Print("[JOINED_WRITER_TEST] FAIL byte length exp=", IntegerToString(StringLen(expected)), " got=", IntegerToString(sz));
        return INIT_FAILED;
    }
    if(BytesHaveCrLfOrBom(raw, sz)) {
        Print("[JOINED_WRITER_TEST] FAIL BOM or CR present");
        return INIT_FAILED;
    }

    string round = CharArrayToString(raw, 0, sz, CP_UTF8);
    if(round != expected) {
        Print("[JOINED_WRITER_TEST] FAIL byte mismatch");
        return INIT_FAILED;
    }

    if(!OpenJoinedDatasetWriter(K_REL)) {
        Print("[JOINED_WRITER_TEST] FAIL reopen truncate");
        return INIT_FAILED;
    }
    if(!WriteJoinedRow(line0) || !CloseJoinedDatasetWriter()) {
        Print("[JOINED_WRITER_TEST] FAIL second session");
        return INIT_FAILED;
    }
    uchar raw2[];
    if(!SmokeReadAllBytesCommon(K_REL, raw2)) {
        Print("[JOINED_WRITER_TEST] FAIL read after truncate");
        return INIT_FAILED;
    }
    const string exp2 = line0 + "\n";
    if(ArraySize(raw2) != StringLen(exp2) || CharArrayToString(raw2, 0, ArraySize(raw2), CP_UTF8) != exp2) {
        Print("[JOINED_WRITER_TEST] FAIL truncate rewrite");
        return INIT_FAILED;
    }

    if(!OpenJoinedDatasetWriter(K_REL)) {
        Print("[JOINED_WRITER_TEST] FAIL open for empty-row test");
        return INIT_FAILED;
    }
    if(WriteJoinedRow("")) {
        Print("[JOINED_WRITER_TEST] FAIL empty string must reject");
        CloseJoinedDatasetWriter();
        return INIT_FAILED;
    }
    if(WriteJoinedRow("\r\n")) {
        Print("[JOINED_WRITER_TEST] FAIL whitespace-only newline payload must reject");
        CloseJoinedDatasetWriter();
        return INIT_FAILED;
    }
    CloseJoinedDatasetWriter();

    FileDelete(K_REL, FILE_COMMON);
    Print("[JOINED_WRITER_TEST] PASS UTF-8 LF deterministic bytes verified");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    FileDelete(K_REL, FILE_COMMON);
}
