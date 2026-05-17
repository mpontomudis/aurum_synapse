//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualCssV1.mqh                                |
//| Embedded dashboard stylesheet (no CDN)                           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_CSS_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_CSS_V1_MQH__

inline string GovRuntimeVisualCssV1_Embedded(void)
{
   string c = "";
   c += "body{font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;margin:0;background:#0f1419;color:#e6edf3;line-height:1.45;}\n";
   c += "header{padding:16px 24px;background:#161b22;border-bottom:1px solid #30363d;}\n";
   c += "h1{font-size:1.15rem;margin:0;font-weight:600;}\n";
   c += "main{padding:20px 24px 48px;max-width:1280px;margin:0 auto;}\n";
   c += "section{margin-bottom:28px;border:1px solid #30363d;border-radius:8px;background:#11161d;padding:16px 18px;}\n";
   c += "h2{font-size:1rem;margin:0 0 12px;color:#58a6ff;font-weight:600;}\n";
   c += ".grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;}\n";
   c += ".card{border:1px solid #30363d;border-radius:8px;padding:12px;background:#0d1117;}\n";
   c += ".card b{display:block;font-size:0.75rem;color:#8b949e;margin-bottom:4px;}\n";
   c += ".card span{font-size:1.05rem;font-weight:600;}\n";
   c += ".badge{display:inline-block;padding:2px 8px;border-radius:999px;font-size:0.75rem;font-weight:600;}\n";
   c += ".tox-low{background:#23863633;color:#3fb950;border:1px solid #238636;}\n";
   c += ".tox-med{background:#d2992233;color:#d29922;border:1px solid #d29922;}\n";
   c += ".tox-high{background:#da363333;color:#f85149;border:1px solid #da3633;}\n";
   c += "table{width:100%;border-collapse:collapse;font-size:0.85rem;}\n";
   c += "th,td{border:1px solid #30363d;padding:8px;text-align:left;}\n";
   c += "th{cursor:pointer;background:#161b22;color:#8b949e;user-select:none;}\n";
   c += "tr:nth-child(even){background:#0d1117;}\n";
   c += ".barwrap{height:8px;background:#21262d;border-radius:4px;overflow:hidden;margin-top:4px;}\n";
   c += ".bar{height:100%;background:linear-gradient(90deg,#388bfd,#58a6ff);border-radius:4px;}\n";
   c += ".heat{font-weight:700;text-align:center;}\n";
   c += "details{margin:6px 0;border:1px solid #30363d;border-radius:6px;padding:8px;background:#0d1117;}\n";
   c += "summary{cursor:pointer;color:#58a6ff;font-weight:600;}\n";
   c += "ul.tree{list-style:none;padding-left:14px;margin:4px 0;border-left:1px solid #30363d;}\n";
   c += "footer{padding:16px 24px;color:#8b949e;font-size:0.8rem;border-top:1px solid #30363d;}\n";
   return c;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_CSS_V1_MQH__
