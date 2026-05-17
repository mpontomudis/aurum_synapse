//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualHtmlWriterV1.mqh                           |
//| LF-only HTML fragments + escape                                  |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_HTMLW_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_HTMLW_V1_MQH__

inline string GovRuntimeVisualHtmlW1_Escape(const string s)
{
   string o = s;
   StringReplace(o, "&", "&amp;");
   StringReplace(o, "<", "&lt;");
   StringReplace(o, ">", "&gt;");
   StringReplace(o, "\"", "&quot;");
   return o;
}

inline void GovRuntimeVisualHtmlW1_AppendLf(string &dst, const string chunk)
{
   string c = chunk;
   StringReplace(c, "\r\n", "\n");
   StringReplace(c, "\r", "\n");
   dst += c;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_HTMLW_V1_MQH__
