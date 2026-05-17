//+------------------------------------------------------------------+
//| GovernanceRuntimeReportRegistryV1.mqh                           |
//| PHASE 20E — unique dossier filenames, CSV history, index, cap      |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_REPORT_REGISTRY_V1_MQH__
#define __AURUM_GOV_RUNTIME_REPORT_REGISTRY_V1_MQH__

#include "GovernanceRuntimeVisualContractsV1.mqh"
#include "../GovernanceComparativeInsightsV1/GovernanceComparisonDatasetV1.mqh"

#define GOV_REPORT_REG_MAX_ROWS 600

struct SGovReportRegRowV1
{
   int      valid;
   string   report_id;
   string   timestamp;
   string   symbol;
   string   timeframe;
   int      deposit;
   double   pf;
   double   dd;
   double   net_profit;
   string   toxicity;
   string   governance_grade;
   string   report_path;
};

struct SGovReportExportCtxV1
{
   int                  valid;
   string               report_ts_display;
   string               report_core_id;
   string               run_label;
   string               rel_filename;
   string               prev_report_id;
   string               prev_filename;
   string               next_filename;
   string               baseline_report_id;
   string               best_pf_report_id;
   string               safest_dd_report_id;
   string               richest_report_id;
   SGovCmpRunRecordV1   cmp_best_pf;
   SGovCmpRunRecordV1   cmp_safest_dd;
   SGovCmpRunRecordV1   cmp_richest;
};

SGovReportExportCtxV1 g_gov_report_export_ctx_v1;

inline void GovReportExportCtxV1_Reset(SGovReportExportCtxV1 &c)
{
   c.valid = 0;
   c.report_ts_display = "";
   c.report_core_id = "";
   c.run_label = "";
   c.rel_filename = "";
   c.prev_report_id = "";
   c.prev_filename = "";
   c.next_filename = "";
   c.baseline_report_id = "";
   c.best_pf_report_id = "";
   c.safest_dd_report_id = "";
   c.richest_report_id = "";
   {
      SGovCmpRunRecordV1 z1, z2, z3;
      GovCmpDsV1_Init(z1);
      GovCmpDsV1_Init(z2);
      GovCmpDsV1_Init(z3);
      c.cmp_best_pf = z1;
      c.cmp_safest_dd = z2;
      c.cmp_richest = z3;
   }
}

inline string GovReportRegV1_CsvHeader(void)
{
   return "report_id,timestamp,symbol,timeframe,deposit,pf,dd,net_profit,toxicity,governance_grade,report_path\n";
}

inline string GovReportRegV1_TfShort(const ENUM_TIMEFRAMES tf)
{
   string s = EnumToString(tf);
   if(StringLen(s) >= 7 && StringFind(s, "PERIOD_") == 0)
      return StringSubstr(s, 7);
   return s;
}

inline string GovReportRegV1_ToxTier(const int max_tox)
{
   if(max_tox < 350)
      return "LOW";
   if(max_tox < 550)
      return "MED";
   return "HIGH";
}

inline string GovReportRegV1_GradeStr(const double pf, const double dd)
{
   if(pf >= 1.55 && dd < 12.0)
      return "A";
   if(pf >= 1.25 && dd < 18.0)
      return "B";
   if(pf >= 1.05 && dd < 28.0)
      return "C";
   if(pf >= 0.95 && dd < 40.0)
      return "D";
   return "F";
}

inline string GovVisualV1_BuildUniqueReportId(const string wall_yyyymmdd_hhmmss,
                                             const string sym,
                                             const string tf_short,
                                             const int deposit_whole,
                                             const int run_index,
                                             const uint salt_u32)
{
   ushort wch = 48;
   ushort sch = 65;
   if(StringLen(wall_yyyymmdd_hhmmss) > 0)
      wch = StringGetCharacter(wall_yyyymmdd_hhmmss, 0);
   if(StringLen(sym) > 0)
      sch = StringGetCharacter(sym, 0);
   int mix = (int)wch + (int)sch;
   mix ^= run_index * 7919;
   mix ^= (int)(salt_u32 & 0xFFFFu);
   mix &= 0xFFFF;
   return StringFormat("%s_%s_%s_%d_%04X_RUN_%04d", wall_yyyymmdd_hhmmss, sym, tf_short, deposit_whole, mix, run_index);
}

inline void GovReportRegV1_RowInit(SGovReportRegRowV1 &r)
{
   r.valid = 0;
   r.report_id = "";
   r.timestamp = "";
   r.symbol = "";
   r.timeframe = "";
   r.deposit = 0;
   r.pf = 0;
   r.dd = 0;
   r.net_profit = 0;
   r.toxicity = "";
   r.governance_grade = "";
   r.report_path = "";
}

inline bool GovReportRegV1_ParseLine(const string line, SGovReportRegRowV1 &r)
{
   GovReportRegV1_RowInit(r);
   string p[];
   const int n = StringSplit(line, ',', p);
   if(n < 11)
      return false;
   if(StringFind(p[0], "report_id") == 0)
      return false;
   r.report_id = p[0];
   r.timestamp = p[1];
   r.symbol = p[2];
   r.timeframe = p[3];
   r.deposit = (int)StringToInteger(p[4]);
   r.pf = StringToDouble(p[5]);
   r.dd = StringToDouble(p[6]);
   r.net_profit = StringToDouble(p[7]);
   r.toxicity = p[8];
   r.governance_grade = p[9];
   r.report_path = p[10];
   r.valid = 1;
   return true;
}

inline string GovReportRegV1_CsvEscapeField(const string s)
{
   string o = s;
   StringReplace(o, "\r", " ");
   StringReplace(o, "\n", " ");
   StringReplace(o, ",", ";");
   return o;
}

inline string GovReportRegV1_CsvLineFromRow(const SGovReportRegRowV1 &r)
{
   return GovReportRegV1_CsvEscapeField(r.report_id) + "," + GovReportRegV1_CsvEscapeField(r.timestamp) + "," +
          GovReportRegV1_CsvEscapeField(r.symbol) + "," + GovReportRegV1_CsvEscapeField(r.timeframe) + "," + IntegerToString(r.deposit) + "," +
          DoubleToString(r.pf, 6) + "," + DoubleToString(r.dd, 4) + "," + DoubleToString(r.net_profit, 2) + "," +
          GovReportRegV1_CsvEscapeField(r.toxicity) + "," + GovReportRegV1_CsvEscapeField(r.governance_grade) + "," +
          GovReportRegV1_CsvEscapeField(r.report_path) + "\n";
}

inline int GovReportRegV1_LoadRows(SGovReportRegRowV1 &rows[])
{
   ArrayResize(rows, 0);
   const string path = GOV_REPORT_REGISTRY_CSV_V1;
   const int h = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return 0;
   while(!FileIsEnding(h)) {
      string ln = FileReadString(h);
      StringTrimLeft(ln);
      StringTrimRight(ln);
      if(StringLen(ln) <= 0)
         continue;
      if(StringFind(ln, "report_id,") == 0)
         continue;
      SGovReportRegRowV1 rr;
      if(!GovReportRegV1_ParseLine(ln, rr))
         continue;
      const int n = ArraySize(rows);
      if(n >= GOV_REPORT_REG_MAX_ROWS)
         break;
      ArrayResize(rows, n + 1);
      rows[n] = rr;
   }
   FileClose(h);
   return ArraySize(rows);
}

inline void GovReportRegV1_ToCmpRecord(const SGovReportRegRowV1 &row, SGovCmpRunRecordV1 &o)
{
   GovCmpDsV1_Init(o);
   if(row.valid == 0)
      return;
   o.valid = 1;
   o.run_ts = row.report_id;
   o.sym = row.symbol;
   o.tf = row.timeframe;
   o.pf = row.pf;
   o.dd_bal_pct = row.dd;
   o.dd_eq_pct = row.dd;
   if(row.toxicity == "HIGH")
      o.max_tox = 750;
   else if(row.toxicity == "MED")
      o.max_tox = 450;
   else
      o.max_tox = 200;
   o.trades = 0;
   o.deposit_cents = (long)row.deposit * 100L;
}

inline bool GovReportRegV1_RowMatchesSymTf(const SGovReportRegRowV1 &row, const string sym, const string tf_short)
{
   if(row.valid == 0)
      return false;
   if(row.symbol != sym)
      return false;
   return (row.timeframe == tf_short);
}

inline void GovReportRegV1_SelectHistoricalIntoCtx(SGovReportRegRowV1 &rows[],
                                                  const string sym,
                                                  const ENUM_TIMEFRAMES tf,
                                                  SGovReportExportCtxV1 &ctx)
{
   {
      SGovCmpRunRecordV1 z1, z2, z3;
      GovCmpDsV1_Init(z1);
      GovCmpDsV1_Init(z2);
      GovCmpDsV1_Init(z3);
      ctx.cmp_best_pf = z1;
      ctx.cmp_safest_dd = z2;
      ctx.cmp_richest = z3;
   }
   ctx.best_pf_report_id = "";
   ctx.safest_dd_report_id = "";
   ctx.richest_report_id = "";
   ctx.baseline_report_id = "";
   ctx.prev_filename = "";
   const string tf_short = GovReportRegV1_TfShort(tf);
   const int n = ArraySize(rows);
   if(n <= 0)
      return;
   ctx.prev_report_id = rows[n - 1].report_id;
   ctx.prev_filename = rows[n - 1].report_path;
   for(int k = n - 1; k >= 0; k--) {
      if(GovReportRegV1_RowMatchesSymTf(rows[k], sym, tf_short)) {
         ctx.baseline_report_id = rows[k].report_id;
         break;
      }
   }
   if(StringLen(ctx.baseline_report_id) <= 0)
      ctx.baseline_report_id = rows[n - 1].report_id;
   int bi = -1;
   int si = -1;
   int ri = -1;
   double best_pf = -1.0e100;
   double best_dd = 1.0e100;
   double best_net = -1.0e100;
   for(int i = 0; i < n; i++) {
      if(!GovReportRegV1_RowMatchesSymTf(rows[i], sym, tf_short))
         continue;
      if(rows[i].pf > best_pf) {
         best_pf = rows[i].pf;
         bi = i;
      }
      if(rows[i].dd < best_dd) {
         best_dd = rows[i].dd;
         si = i;
      }
      if(rows[i].net_profit > best_net) {
         best_net = rows[i].net_profit;
         ri = i;
      }
   }
   if(bi >= 0) {
      ctx.best_pf_report_id = rows[bi].report_id;
      GovReportRegV1_ToCmpRecord(rows[bi], ctx.cmp_best_pf);
   }
   if(si >= 0) {
      ctx.safest_dd_report_id = rows[si].report_id;
      GovReportRegV1_ToCmpRecord(rows[si], ctx.cmp_safest_dd);
   }
   if(ri >= 0) {
      ctx.richest_report_id = rows[ri].report_id;
      GovReportRegV1_ToCmpRecord(rows[ri], ctx.cmp_richest);
   }
}

inline bool GovReportRegV1_AppendRow(const SGovReportRegRowV1 &r)
{
   if(r.valid == 0)
      return false;
   const string path = GOV_REPORT_REGISTRY_CSV_V1;
   bool need_header = true;
   const int h0 = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h0 != INVALID_HANDLE) {
      if(FileSize(h0) > 32)
         need_header = false;
      FileClose(h0);
   }
   const int h = FileOpen(path, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileSeek(h, 0, SEEK_END);
   if(need_header)
      FileWriteString(h, GovReportRegV1_CsvHeader());
   FileWriteString(h, GovReportRegV1_CsvLineFromRow(r));
   FileClose(h);
   return true;
}

inline void GovReportRegV1_DeleteReportArtifacts(const string report_path_filename)
{
   const string dir = GOV_VISUAL_REPORT_DIR_V1;
   if(StringLen(report_path_filename) <= 5)
      return;
   if(StringFind(report_path_filename, ".html") < 0)
      return;
   const string stem = StringSubstr(report_path_filename, 0, StringLen(report_path_filename) - 5);
   FileDelete(dir + stem + GOV_VISUAL_HTML_EXT_V1);
   FileDelete(dir + stem + GOV_VISUAL_CSS_EXT_V1);
   FileDelete(dir + stem + GOV_VISUAL_JS_EXT_V1);
   FileDelete(dir + stem + GOV_VISUAL_JSON_EXT_V1);
   FileDelete(dir + stem + GOV_DOSSIER_COMPARE_EXT_V1);
}

inline bool GovReportRegV1_RewriteCsv(const SGovReportRegRowV1 &rows[], const int n)
{
   const string path = GOV_REPORT_REGISTRY_CSV_V1;
   const int h = FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWriteString(h, GovReportRegV1_CsvHeader());
   for(int i = 0; i < n; i++) {
      if(rows[i].valid != 0)
         FileWriteString(h, GovReportRegV1_CsvLineFromRow(rows[i]));
   }
   FileClose(h);
   return true;
}

inline void GovReportRegV1_EnforceRetentionCap(void)
{
   SGovReportRegRowV1 rows[];
   const int n = GovReportRegV1_LoadRows(rows);
   if(n <= (int)GOV_REPORT_HISTORY_CAP_V1)
      return;
   const int excess = n - (int)GOV_REPORT_HISTORY_CAP_V1;
   if(excess <= 0)
      return;
   for(int k = 0; k < excess; k++) {
      if(rows[k].valid != 0)
         GovReportRegV1_DeleteReportArtifacts(rows[k].report_path);
   }
   SGovReportRegRowV1 kept[];
   ArrayResize(kept, n - excess);
   for(int j = 0; j < n - excess; j++)
      kept[j] = rows[j + excess];
   GovReportRegV1_RewriteCsv(kept, n - excess);
}

inline void GovReportRegV1_WriteIndexHtml(void)
{
   SGovReportRegRowV1 rows[];
   const int n = GovReportRegV1_LoadRows(rows);
   string html = "";
   html += "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"/><title>Governance research library</title>\n";
   html += "<style>body{font-family:system-ui,Segoe UI,Roboto,Arial;background:#0d1117;color:#e6edf3;margin:0;padding:16px;}";
   html += "h1{font-size:1.25rem;} table{border-collapse:collapse;width:100%;font-size:0.85rem;} th,td{border:1px solid #30363d;padding:6px;text-align:left;}";
   html += "th{background:#161b22;position:sticky;top:0;} tr:nth-child(even){background:#11161d;} a{color:#58a6ff;} .filters{display:flex;flex-wrap:wrap;gap:8px;margin:12px 0;}";
   html += ".filters input,.filters select{background:#161b22;border:1px solid #30363d;color:#e6edf3;padding:4px 8px;}";
   html += ".stats{display:flex;flex-wrap:wrap;gap:12px;margin:12px 0;font-size:0.85rem;color:#8b949e;}</style></head><body>\n";
   html += "<h1>Governance research library</h1><p class=\"stats\">Cold-path index under MQL5 Files. Open dossier HTML from the links column.</p>\n";
   html += "<div class=\"filters\"><label>Symbol <input id=\"fSym\" type=\"text\" placeholder=\"e.g. XAUUSD\"/></label>";
   html += "<label>Year <input id=\"fYear\" type=\"number\" placeholder=\"2022\"/></label>";
   html += "<label>Min PF <input id=\"fPfMin\" type=\"number\" step=\"0.01\"/></label>";
   html += "<label>Max DD% <input id=\"fDdMax\" type=\"number\" step=\"0.1\"/></label>";
   html += "<label>Toxicity <select id=\"fTox\"><option value=\"\">(any)</option><option>LOW</option><option>MED</option><option>HIGH</option></select></label>";
   html += "<label>Grade <input id=\"fGrade\" type=\"text\" placeholder=\"A\"/></label>";
   html += "<button type=\"button\" onclick=\"applyFilters()\">Apply filters</button></div>\n";
   html += "<div class=\"stats\" id=\"agg\"></div>\n";
   html += "<table id=\"tbl\"><thead><tr><th>#</th><th>Timestamp</th><th>Symbol</th><th>TF</th><th>Deposit</th><th>PF</th><th>DD%</th><th>Net</th><th>Tox</th><th>Grade</th><th>Report</th></tr></thead><tbody>\n";
   double max_pf = -1e100;
   int hi = -1;
   for(int i = 0; i < n; i++) {
      if(rows[i].valid == 0)
         continue;
      if(rows[i].pf > max_pf) {
         max_pf = rows[i].pf;
         hi = i;
      }
   }
   for(int r = 0; r < n; r++) {
      if(rows[r].valid == 0)
         continue;
      int y = 0;
      if(StringLen(rows[r].timestamp) >= 4)
         y = (int)StringToInteger(StringSubstr(rows[r].timestamp, 0, 4));
      string cls = "";
      if(r == hi && hi >= 0)
         cls = "best-pf ";
      html += "<tr class=\"" + cls + "govrow\" data-sym=\"" + rows[r].symbol + "\" data-year=\"" + IntegerToString(y) + "\" data-pf=\"" + DoubleToString(rows[r].pf, 6) + "\" data-dd=\"" + DoubleToString(rows[r].dd, 4) + "\" data-tox=\"" + rows[r].toxicity + "\" data-grade=\"" + rows[r].governance_grade + "\">";
      html += "<td>" + IntegerToString(r + 1) + "</td><td>" + rows[r].timestamp + "</td><td>" + rows[r].symbol + "</td><td>" + rows[r].timeframe + "</td><td>" + IntegerToString(rows[r].deposit) + "</td>";
      html += "<td>" + DoubleToString(rows[r].pf, 3) + "</td><td>" + DoubleToString(rows[r].dd, 2) + "</td><td>" + DoubleToString(rows[r].net_profit, 2) + "</td><td>" + rows[r].toxicity + "</td><td>" + rows[r].governance_grade + "</td>";
      html += "<td><a href=\"./" + rows[r].report_path + "\">open</a></td></tr>\n";
   }
   html += "</tbody></table>\n<script>\n";
   html += "function num(v){var x=parseFloat(v);return isFinite(x)?x:NaN;}\n";
   html += "function applyFilters(){\n";
   html += "  var fs=(document.getElementById('fSym').value||'').toUpperCase();\n";
   html += "  var fy=document.getElementById('fYear').value;\n";
   html += "  var fpmn=num(document.getElementById('fPfMin').value);\n";
   html += "  var fdm=num(document.getElementById('fDdMax').value);\n";
   html += "  var ft=document.getElementById('fTox').value;\n";
   html += "  var fg=(document.getElementById('fGrade').value||'').toUpperCase();\n";
   html += "  var rows=document.querySelectorAll('#tbl tbody tr');\n";
   html += "  for(var i=0;i<rows.length;i++){\n";
   html += "    var tr=rows[i]; var ok=true;\n";
   html += "    if(fs && (tr.getAttribute('data-sym')||'').toUpperCase().indexOf(fs)<0) ok=false;\n";
   html += "    if(fy && tr.getAttribute('data-year')!=fy) ok=false;\n";
   html += "    if(isFinite(fpmn) && num(tr.getAttribute('data-pf'))<fpmn) ok=false;\n";
   html += "    if(isFinite(fdm) && num(tr.getAttribute('data-dd'))>fdm) ok=false;\n";
   html += "    if(ft && tr.getAttribute('data-tox')!=ft) ok=false;\n";
   html += "    if(fg && (tr.getAttribute('data-grade')||'').toUpperCase().indexOf(fg)<0) ok=false;\n";
   html += "    tr.style.display=ok?'':'none';\n";
   html += "  }\n";
   html += "}\n";
   html += "(function(){var rows=document.querySelectorAll('#tbl tbody tr');var last=rows.length?rows[rows.length-1]:null;";
   html += "document.getElementById('agg').textContent='Rows: '+rows.length+' · Latest: '+(last?last.children[1].textContent:'n/a');})();\n";
   html += "</script></body></html>\n";
   const int h = FileOpen(GOV_REPORT_INDEX_HTML_V1, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return;
   FileWriteString(h, html);
   FileClose(h);
}

#endif // __AURUM_GOV_RUNTIME_REPORT_REGISTRY_V1_MQH__
