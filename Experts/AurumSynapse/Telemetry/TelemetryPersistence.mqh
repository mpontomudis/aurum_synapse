//+------------------------------------------------------------------+
//|                                         TelemetryPersistence.mqh |
//|                    T2 shadow CSV — cold path + failure isolation |
//| Hot path: EnqueueCopy only. File I/O in OnTimer drain only.     |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_PERSISTENCE_MQH__
#define __AURUM_TELEMETRY_PERSISTENCE_MQH__

#include "TelemetryConfig.mqh"
#include "TelemetryQueue.mqh"
#include "TelemetryWriter.mqh"
#include "TelemetryRotation.mqh"

static int     g_t2FileHandle      = INVALID_HANDLE;
static ulong   g_t2BytesInSeg      = 0;
static int     g_t2SegYmd          = 0;
static int     g_t2SegSeq        = 0;
static bool    g_t2Disabled        = true;
static bool    g_t2FailLogged      = false;
static bool    g_t2Inited          = false;
static string  g_t2SymSan        = "";
static string  g_t2LineBuf        = "";
static string  g_t2RelPath        = "";

void TelemetryT2_SoftDisableOnce(const string reason) {
    g_t2Disabled = true;
    if(g_t2FileHandle != INVALID_HANDLE) {
        FileFlush(g_t2FileHandle);
        FileClose(g_t2FileHandle);
        g_t2FileHandle = INVALID_HANDLE;
    }
    if(!g_t2FailLogged) {
        g_t2FailLogged = true;
        Print("[TelemetryT2] persistence disabled: ", reason);
    }
}

bool TelemetryT2_CloseSegment(void) {
    if(g_t2FileHandle == INVALID_HANDLE)
        return true;
    FileFlush(g_t2FileHandle);
    FileClose(g_t2FileHandle);
    g_t2FileHandle = INVALID_HANDLE;
    g_t2BytesInSeg = 0;
    return true;
}

//+------------------------------------------------------------------+
//| Open (or replace) segment file; append header if new/empty.      |
//+------------------------------------------------------------------+
bool TelemetryT2_OpenSegment(const int ymd, const int seq) {
    TelemetryT2_CloseSegment();
    string rel;
    TelemetryRotation_BuildRelativePath(g_t2SymSan, ymd, seq, rel);
    g_t2RelPath = rel;
    g_t2FileHandle = FileOpen(rel,
                              FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
    if(g_t2FileHandle == INVALID_HANDLE) {
        TelemetryT2_SoftDisableOnce("FileOpen failed for " + rel);
        return false;
    }
    FileSeek(g_t2FileHandle, 0, SEEK_END);
    const ulong fsz = (ulong)FileSize(g_t2FileHandle);
    if(fsz == 0) {
        const string hdr = TelemetryWriter_CsvHeaderLine();
        if(FileWriteString(g_t2FileHandle, hdr + "\n") < 1) {
            TelemetryT2_SoftDisableOnce("header write failed");
            return false;
        }
        g_t2BytesInSeg = (ulong)StringLen(hdr) + 1;
    } else {
        g_t2BytesInSeg = fsz;
    }
    g_t2SegYmd = ymd;
    g_t2SegSeq = seq;
    return true;
}

void TelemetryT2_CheckRotateByDayOrSize(void) {
    if(g_t2Disabled || g_t2FileHandle == INVALID_HANDLE)
        return;
    const int today = TelemetryRotation_YmdFromTime(TimeGMT());
    if(today != g_t2SegYmd) {
        if(!TelemetryT2_OpenSegment(today, 0))
            return;
    } else if(g_t2BytesInSeg >= (ulong)TELEMETRY_T2_MAX_SEGMENT_BYTES) {
        if(!TelemetryT2_OpenSegment(today, g_t2SegSeq + 1))
            return;
    }
}

//+------------------------------------------------------------------+
void TelemetryT2_Init(void) {
    g_t2Inited = false;
    g_t2Disabled = true;
    g_t2FailLogged = false;
    TelemetryQueue_Reset();
    g_t2SymSan = TelemetryRotation_SanitizeSymbol(_Symbol);
    StringInit(g_t2LineBuf, TELEMETRY_T2_LINE_BUFFER_CHARS, 0);
    if(!FolderCreate("AurumSynapse", FILE_COMMON)) {
        // may already exist
    }
    if(!FolderCreate("AurumSynapse\\telemetry", FILE_COMMON)) {
        // may already exist
    }
    const int ymd = TelemetryRotation_YmdFromTime(TimeGMT());
    if(!TelemetryT2_OpenSegment(ymd, 0))
        return;
    g_t2Disabled = false;
    g_t2Inited = true;
}

bool TelemetryT2_IsReady(void) {
    return (g_t2Inited && !g_t2Disabled);
}

string TelemetryT2_CurrentRelativePath(void) {
    return g_t2RelPath;
}

void TelemetryT2_Deinit(void) {
    if(!g_t2Inited) {
        TelemetryQueue_Reset();
        TelemetryT2_CloseSegment();
        return;
    }
    TelemetryBarRow row;
    int safety = 0;
    while(TelemetryQueue_TryDequeue(row) && safety < 100000) {
        TelemetryWriter_FormatDataLine(row, g_t2LineBuf);
        if(g_t2FileHandle != INVALID_HANDLE && !g_t2Disabled) {
            if(FileWriteString(g_t2FileHandle, g_t2LineBuf + "\n") < 1)
                break;
        }
        safety++;
    }
    TelemetryT2_CloseSegment();
    TelemetryQueue_Reset();
    g_t2Inited = false;
    g_t2Disabled = true;
}

//+------------------------------------------------------------------+
//| Hot path: O(1) enqueue; no file I/O.                            |
//+------------------------------------------------------------------+
void TelemetryT2_EnqueueCopy(const TelemetryBarRow &row) {
    if(!g_t2Inited || g_t2Disabled)
        return;
    TelemetryQueue_EnqueueCopy(row);
}

//+------------------------------------------------------------------+
//| Cold path: OnTimer — bounded drain.                              |
//+------------------------------------------------------------------+
void TelemetryT2_OnTimerDrain(void) {
    if(!g_t2Inited || g_t2Disabled)
        return;
    TelemetryT2_CheckRotateByDayOrSize();
    if(g_t2FileHandle == INVALID_HANDLE)
        return;
    int drained = 0;
    TelemetryBarRow row;
    while(drained < TELEMETRY_T2_DRAIN_MAX_ROWS && TelemetryQueue_TryDequeue(row)) {
        if(g_t2BytesInSeg >= (ulong)TELEMETRY_T2_MAX_SEGMENT_BYTES) {
            const int ymd = TelemetryRotation_YmdFromTime(TimeGMT());
            if(!TelemetryT2_OpenSegment(ymd, g_t2SegSeq + 1))
                return;
        }
        TelemetryWriter_FormatDataLine(row, g_t2LineBuf);
        const uint w = FileWriteString(g_t2FileHandle, g_t2LineBuf + "\n");
        if(w < 1) {
            TelemetryT2_SoftDisableOnce("FileWriteString failed");
            return;
        }
        g_t2BytesInSeg += (ulong)StringLen(g_t2LineBuf) + 1;
        drained++;
    }
}

//+------------------------------------------------------------------+
//| Test helper: drain up to maxRows×maxBatches (no timer).          |
//+------------------------------------------------------------------+
void TelemetryT2_DrainForTesting(const int maxBatches) {
    for(int b = 0; b < maxBatches; b++)
        TelemetryT2_OnTimerDrain();
}

//+------------------------------------------------------------------+
//| Test-only: verify soft-disable path (no throw).                 |
//+------------------------------------------------------------------+
void TelemetryT2_TestForceSoftDisable(void) {
    TelemetryT2_SoftDisableOnce("TestTelemetryT2 manual disable");
}

#endif // __AURUM_TELEMETRY_PERSISTENCE_MQH__
