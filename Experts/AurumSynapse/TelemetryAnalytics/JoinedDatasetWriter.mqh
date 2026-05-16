//+------------------------------------------------------------------+
//|                                   JoinedDatasetWriter.mqh        |
//|     AS_JOINED_V1 — deterministic joined CSV writer (FILE_COMMON) |
//|     UTF-8, LF-only, no BOM (GOLDEN_CSV_NORMALIZATION_V1 class)   |
//+------------------------------------------------------------------+
#ifndef __AURUM_JOINED_DATASET_WRITER_MQH__
#define __AURUM_JOINED_DATASET_WRITER_MQH__

#ifndef CP_UTF8
   #define CP_UTF8  65001
#endif

static int  s_jdw_fh            = INVALID_HANDLE;
static int  s_jdw_rows_ok       = 0;
static int  s_jdw_rows_failed   = 0;
static bool s_jdw_open          = false;

//+------------------------------------------------------------------+
void JoinedDatasetWriter_NormalizeUserLine(string &s) {
    StringReplace(s, "\r", "");
    while(StringLen(s) > 0) {
        const ushort last = (ushort)StringGetCharacter(s, StringLen(s) - 1);
        if(last != '\n')
            break;
        s = StringSubstr(s, 0, StringLen(s) - 1);
    }
}

//+------------------------------------------------------------------+
bool JoinedDatasetWriter_WriteUtf8BytesLf(const int fh, const string lineNoCr) {
    uchar body[];
    const int nch = StringToCharArray(lineNoCr, body, 0, WHOLE_ARRAY, CP_UTF8);
    if(nch < 1)
        return false;
    int nwrite = nch;
    if(nwrite > 0 && body[nwrite - 1] == 0)
        nwrite--;
    if(nwrite > 0) {
        if(FileWriteArray(fh, body, 0, nwrite) != (uint)nwrite)
            return false;
    }
    uchar lf[1];
    lf[0] = (uchar)'\n';
    return (FileWriteArray(fh, lf, 0, 1) == 1);
}

//+------------------------------------------------------------------+
void JoinedDatasetWriter_ResetStats(void) {
    s_jdw_rows_ok = 0;
    s_jdw_rows_failed = 0;
}

//+------------------------------------------------------------------+
//| Open writer: truncates/creates file under Common\Files\.         |
//| Idempotent: closes any previous session first.                   |
//+------------------------------------------------------------------+
bool OpenJoinedDatasetWriter(const string relPathFromCommonFiles) {
    CloseJoinedDatasetWriter();
    JoinedDatasetWriter_ResetStats();
    FileDelete(relPathFromCommonFiles, FILE_COMMON);
    s_jdw_fh = FileOpen(relPathFromCommonFiles, FILE_WRITE | FILE_BIN | FILE_COMMON);
    if(s_jdw_fh == INVALID_HANDLE)
        return false;
    s_jdw_open = true;
    return true;
}

//+------------------------------------------------------------------+
//| One logical CSV row: stripped of CR; trailing LFs removed;      |
//| exactly one '\n' (0x0A) appended on disk (LF-only policy).       |
//| Empty payload after normalize → false (no write).                |
//+------------------------------------------------------------------+
bool WriteJoinedRow(const string joinedLine) {
    if(!s_jdw_open || s_jdw_fh == INVALID_HANDLE) {
        s_jdw_rows_failed++;
        return false;
    }
    string s = joinedLine;
    JoinedDatasetWriter_NormalizeUserLine(s);
    if(StringLen(s) < 1) {
        s_jdw_rows_failed++;
        return false;
    }
    if(!JoinedDatasetWriter_WriteUtf8BytesLf(s_jdw_fh, s)) {
        s_jdw_rows_failed++;
        return false;
    }
    s_jdw_rows_ok++;
    return true;
}

//+------------------------------------------------------------------+
//| Close session. Safe to call when already closed (returns true).  |
//+------------------------------------------------------------------+
bool CloseJoinedDatasetWriter(void) {
    if(!s_jdw_open || s_jdw_fh == INVALID_HANDLE) {
        s_jdw_fh = INVALID_HANDLE;
        s_jdw_open = false;
        return true;
    }
    FileFlush(s_jdw_fh);
    FileClose(s_jdw_fh);
    s_jdw_fh = INVALID_HANDLE;
    s_jdw_open = false;
    return true;
}

//+------------------------------------------------------------------+
int JoinedDatasetWriter_RowsWrittenSuccess(void) { return s_jdw_rows_ok; }

int JoinedDatasetWriter_RowsFailed(void) { return s_jdw_rows_failed; }

bool JoinedDatasetWriter_IsOpen(void) { return s_jdw_open && (s_jdw_fh != INVALID_HANDLE); }

//+------------------------------------------------------------------+
//| Legacy one-shot write (header + rows). Uses same UTF-8/LF path. |
//+------------------------------------------------------------------+
bool JoinedDatasetWriter_WriteUtf8LfNoBomCommon(const string relPathFromCommonFiles,
                                                const string headerLine,
                                                const string &dataLines[]) {
    if(!OpenJoinedDatasetWriter(relPathFromCommonFiles))
        return false;
    string hdr = headerLine;
    JoinedDatasetWriter_NormalizeUserLine(hdr);
    if(StringLen(hdr) < 1 || !WriteJoinedRow(hdr)) {
        CloseJoinedDatasetWriter();
        return false;
    }
    const int n = ArraySize(dataLines);
    for(int i = 0; i < n; i++) {
        if(!WriteJoinedRow(dataLines[i])) {
            CloseJoinedDatasetWriter();
            return false;
        }
    }
    return CloseJoinedDatasetWriter();
}

#endif // __AURUM_JOINED_DATASET_WRITER_MQH__
