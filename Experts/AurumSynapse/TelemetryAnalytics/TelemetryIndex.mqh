//+------------------------------------------------------------------+
//|                                         TelemetryIndex.mqh       |
//|     Phase 3B — Step 1A: telemetry store + backward-only lookup  |
//|     BACKWARD_ONLY_JOIN_POLICY_V1 via JoinValidationPrototype.   |
//+------------------------------------------------------------------+
#ifndef __AURUM_TELEMETRY_INDEX_MQH__
#define __AURUM_TELEMETRY_INDEX_MQH__

#include "JoinValidationPrototype.mqh"

//+------------------------------------------------------------------+
//| AS_TELEMETRY_V1 CSV index (UTF-8 LF, CR stripped on load).        |
//|                                                                   |
//| LoadTelemetryCsv: parses every data row with                      |
//| CsvTelemetry_PrepareFieldsFromLine (same as golden harness).    |
//| Rows are stored in file order; m_sortPerm[] is a permutation     |
//| giving ascending (bar_utc, original_index) — deterministic.     |
//|                                                                   |
//| FindNearestBackwardBar(symbol, period, d_time_utc, ...):          |
//| builds a temporary UTF-8 slice (header + rows matching           |
//| t_symbol / t_period only), then calls                             |
//| JoinValidation_SelectBestBackwardBarFromTelemetryText on it —     |
//| no duplicated MAX(bar) logic, no forward / interpolation.         |
//| If no row matches symbol+period, or no bar_utc <= d_time_utc:     |
//| returns false; eligibleCount from helper (0 when none).         |
//+------------------------------------------------------------------+
class CTelemetryIndex {
    string m_hdr;
    string m_rowLine[];
    long   m_barUtc[];
    string m_sym[];
    int    m_periodInt[];
    int    m_sortPerm[];
    int    m_rowCount;

    void ClearRows(void) {
        m_hdr = "";
        ArrayResize(m_rowLine, 0);
        ArrayResize(m_barUtc, 0);
        ArrayResize(m_sym, 0);
        ArrayResize(m_periodInt, 0);
        ArrayResize(m_sortPerm, 0);
        m_rowCount = 0;
    }

    void RebuildAscendingPermutation(void) {
        ArrayResize(m_sortPerm, m_rowCount);
        for(int i = 0; i < m_rowCount; i++)
            m_sortPerm[i] = i;
        if(m_rowCount < 2)
            return;
        for(int a = 0; a < m_rowCount - 1; a++) {
            for(int b = 0; b < m_rowCount - 1 - a; b++) {
                const int ia = m_sortPerm[b];
                const int ib = m_sortPerm[b + 1];
                const bool swap = (m_barUtc[ia] > m_barUtc[ib]) ||
                                  (m_barUtc[ia] == m_barUtc[ib] && ia > ib);
                if(swap) {
                    const int t = m_sortPerm[b];
                    m_sortPerm[b] = m_sortPerm[b + 1];
                    m_sortPerm[b + 1] = t;
                }
            }
        }
    }

    bool BuildFilteredTelemetryUtf8Lf(const string symbol, const int period, string &outUtf8Lf) const {
        outUtf8Lf = m_hdr;
        StringTrimRight(outUtf8Lf);
        outUtf8Lf += "\n";
        int nMatch = 0;
        for(int i = 0; i < m_rowCount; i++) {
            if(m_sym[i] != symbol)
                continue;
            if(m_periodInt[i] != period)
                continue;
            outUtf8Lf += m_rowLine[i];
            outUtf8Lf += "\n";
            nMatch++;
        }
        return (nMatch > 0);
    }

public:
    CTelemetryIndex(void) { ClearRows(); }

    void Clear(void) { ClearRows(); }

    int RowCount(void) const { return m_rowCount; }

    //+------------------------------------------------------------------+
    //| Original file-order index for sorted position (0 .. RowCount()-1).|
    //+------------------------------------------------------------------+
    bool SortedOriginalIndex(const int sortedPosition, int &outOriginalRowIndex) const {
        if(sortedPosition < 0 || sortedPosition >= m_rowCount)
            return false;
        outOriginalRowIndex = m_sortPerm[sortedPosition];
        return true;
    }

    long SortedBarUtc(const int sortedPosition) const {
        if(sortedPosition < 0 || sortedPosition >= m_rowCount)
            return 0;
        return m_barUtc[m_sortPerm[sortedPosition]];
    }

    //+------------------------------------------------------------------+
    //| Path relative to Terminal\Common\Files\ (FILE_COMMON).         |
    //+------------------------------------------------------------------+
    bool LoadTelemetryCsv(const string relPathFromCommonFiles) {
        ClearRows();
        string full = "";
        if(!JoinValidation_ReadUtf8FileLf(relPathFromCommonFiles, full))
            return false;
        string lines[];
        const int n = StringSplit(full, '\n', lines);
        if(n < 2)
            return false;
        m_hdr = lines[0];
        StringTrimRight(m_hdr);
        const int need = TelemetryCsvV1_ExpectedColumns();
        for(int i = 1; i < n; i++) {
            string s = lines[i];
            StringTrimLeft(s);
            StringTrimRight(s);
            if(s == "")
                continue;
            string parts[];
            if(!CsvTelemetry_PrepareFieldsFromLine(s, parts))
                return false;
            if(ArraySize(parts) != need)
                return false;
            const int k = m_rowCount;
            m_rowCount++;
            ArrayResize(m_rowLine, m_rowCount);
            ArrayResize(m_barUtc, m_rowCount);
            ArrayResize(m_sym, m_rowCount);
            ArrayResize(m_periodInt, m_rowCount);
            m_rowLine[k] = s;
            m_barUtc[k] = (long)StringToInteger(parts[TCOL_BAR_UTC]);
            m_sym[k] = parts[TCOL_SYMBOL];
            m_periodInt[k] = (int)StringToInteger(parts[TCOL_PERIOD]);
        }
        if(m_rowCount < 1) {
            ClearRows();
            return false;
        }
        RebuildAscendingPermutation();
        return true;
    }

    //+------------------------------------------------------------------+
    //| BACKWARD_ONLY_JOIN_POLICY_V1: only bar_utc <= d_time_utc compete;|
    //| winner = MAX(bar_utc); ties → earliest physical CSV row.       |
    //+------------------------------------------------------------------+
    bool FindNearestBackwardBar(const string symbol, const int period, const long d_time_utc,
                                string &outParts[], int &eligibleCount) {
        ArrayResize(outParts, 0);
        eligibleCount = 0;
        if(m_rowCount < 1)
            return false;
        string slice = "";
        if(!BuildFilteredTelemetryUtf8Lf(symbol, period, slice))
            return false;
        if(!JoinValidation_SelectBestBackwardBarFromTelemetryText(slice, d_time_utc, outParts, eligibleCount))
            return false;
        return (ArraySize(outParts) == TelemetryCsvV1_ExpectedColumns());
    }
};

#endif // __AURUM_TELEMETRY_INDEX_MQH__
