//+------------------------------------------------------------------+
//| GovernanceBacktestReplayTimelineV1.mqh                           |
//| PHASE 20B — chronological bridge slice (deterministic)           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_BACKTEST_REPLAY_TL_V1_MQH__
#define __AURUM_GOV_BACKTEST_REPLAY_TL_V1_MQH__

#include "../GovernanceRuntimeStrategyTaggingV1/GovernanceRuntimeStrategyTaggingModuleV1.mqh"
#include "GovernanceRuntimeVisualHtmlWriterV1.mqh"
#include "GovernanceRuntimeVisualDashboardBuilderV1.mqh"

inline void GovBacktestReplayTlV1_AppendSection(const SGovRuntimeTaggingModuleV1 &mod, string &html, const int max_rows)
{
   GovRuntimeVisualHtmlW1_AppendLf(html, "<section id=\"s-rtl\"><h2>14. Replay timeline</h2>\n");
   GovRuntimeVisualHtmlW1_AppendLf(html, "<p style=\"color:#8b949e;font-size:0.85rem;\">Cold-path bridge slice (open → PnL attribution). Scale-in / recovery / SL/TP require deal hooks (reserved).</p>\n");
   GovRuntimeVisualDashV1_AppendBridgeTimeline(mod, html, max_rows);
   GovRuntimeVisualHtmlW1_AppendLf(html, "</section>\n");
}

#endif // __AURUM_GOV_BACKTEST_REPLAY_TL_V1_MQH__
