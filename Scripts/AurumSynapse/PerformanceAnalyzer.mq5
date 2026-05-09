//+------------------------------------------------------------------+
//|                                            PerformanceAnalyzer.mq5 |
//|                                      Aurum Synapse v2.0 Pro       |
//|             Post-Backtest Metrics Collector & Analyzer             |
//|                                   Copyright 2026, Aurum Synapse   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "1.00"
#property description "Collects and exports detailed performance metrics"
#property description "Run AFTER a backtest to analyze deal history"
#property script_show_inputs

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input string InpReportName = "AurumSynapse_Analysis";  // Report File Name
input int    InpMagicNumber = 20260505;                // Magic Number (0=all)
input string InpSymbolFilter = "";                     // Symbol Filter (empty=current)

//+------------------------------------------------------------------+
//| Structures                                                        |
//+------------------------------------------------------------------+
struct DealRecord {
    ulong    ticket;
    datetime time;
    int      type;        // DEAL_TYPE_BUY or DEAL_TYPE_SELL
    double   volume;
    double   price;
    double   profit;
    double   commission;
    double   swap;
    double   netProfit;   // profit + commission + swap
    string   comment;
    long     positionId;
    int      hourWIT;
    int      dayOfWeek;
    int      month;
    int      year;
    long     durationSec;
};

struct HourlyStats {
    int    trades;
    int    wins;
    double pnl;
};

struct DailyStats {
    int    trades;
    int    wins;
    double pnl;
};

struct MonthlyStats {
    int    trades;
    int    wins;
    double pnl;
    double maxDD;
};

//+------------------------------------------------------------------+
//| Global Arrays                                                     |
//+------------------------------------------------------------------+
DealRecord g_deals[];
int g_totalDeals = 0;

HourlyStats g_hourly[24];
DailyStats  g_daily[7];     // 0=Sun, 1=Mon, ..., 6=Sat
MonthlyStats g_monthly[12]; // 0=Jan, ..., 11=Dec

//+------------------------------------------------------------------+
//| Script Entry Point                                                |
//+------------------------------------------------------------------+
void OnStart() {
    Print("╔══════════════════════════════════════════════════════╗");
    Print("║   AURUM SYNAPSE - PERFORMANCE ANALYZER v1.0         ║");
    Print("╚══════════════════════════════════════════════════════╝");
    Print("");
    
    string symbol = (InpSymbolFilter == "") ? _Symbol : InpSymbolFilter;
    
    //--- 1. Collect deal history
    if(!CollectDeals(symbol)) {
        Print("ERROR: Failed to collect deal history.");
        Print("Make sure to run this AFTER a backtest or on a live account with history.");
        return;
    }
    
    Print("Collected ", g_totalDeals, " closed deals for ", symbol);
    Print("");
    
    if(g_totalDeals < 10) {
        Print("WARNING: Too few trades (", g_totalDeals, ") for meaningful analysis.");
        Print("Minimum recommended: 200+ trades.");
    }
    
    //--- 2. Calculate all metrics
    CalculateTimeBreakdowns();
    
    //--- 3. Generate report
    string reportPath = "AurumSynapse/" + InpReportName + "_" +
                        TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
    
    //--- 4. Print comprehensive analysis to Journal
    PrintCoreMetrics();
    PrintRiskMetrics();
    PrintTimeAnalysis();
    PrintDurationAnalysis();
    PrintStreakAnalysis();
    PrintMonthlyBreakdown();
    
    //--- 5. Export to CSV
    ExportToCSV(reportPath);
    
    Print("");
    Print("╔══════════════════════════════════════════════════════╗");
    Print("║   ANALYSIS COMPLETE                                 ║");
    Print("║   Report: MQL5/Files/", reportPath);
    Print("╚══════════════════════════════════════════════════════╝");
}

//+------------------------------------------------------------------+
//| Collect deal history from terminal                                |
//+------------------------------------------------------------------+
bool CollectDeals(string symbol) {
    if(!HistorySelect(0, TimeCurrent())) {
        Print("ERROR: HistorySelect failed");
        return false;
    }
    
    int totalHistory = HistoryDealsTotal();
    if(totalHistory == 0) return false;
    
    ArrayResize(g_deals, totalHistory);
    g_totalDeals = 0;
    
    for(int i = 0; i < totalHistory; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket == 0) continue;
        
        //--- Filter by symbol
        string dealSymbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
        if(dealSymbol != symbol && symbol != "") continue;
        
        //--- Filter by magic number
        if(InpMagicNumber > 0) {
            long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            if(magic != InpMagicNumber) continue;
        }
        
        //--- Only count closing deals (profit/loss realized)
        long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
        if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;
        
        //--- Populate record
        DealRecord deal;
        deal.ticket = ticket;
        deal.time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
        deal.type = (int)HistoryDealGetInteger(ticket, DEAL_TYPE);
        deal.volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
        deal.price = HistoryDealGetDouble(ticket, DEAL_PRICE);
        deal.profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
        deal.commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        deal.swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
        deal.netProfit = deal.profit + deal.commission + deal.swap;
        deal.comment = HistoryDealGetString(ticket, DEAL_COMMENT);
        deal.positionId = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
        
        MqlDateTime dt;
        TimeToStruct(deal.time, dt);
        deal.hourWIT = dt.hour;   // Broker time, adjust if needed
        deal.dayOfWeek = dt.day_of_week;
        deal.month = dt.mon;
        deal.year = dt.year;
        
        //--- Calculate trade duration by finding the opening deal
        deal.durationSec = CalculateDuration(deal.positionId, deal.time);
        
        g_deals[g_totalDeals] = deal;
        g_totalDeals++;
    }
    
    ArrayResize(g_deals, g_totalDeals);
    return (g_totalDeals > 0);
}

//+------------------------------------------------------------------+
//| Calculate trade duration from position open to close              |
//+------------------------------------------------------------------+
long CalculateDuration(long positionId, datetime closeTime) {
    int total = HistoryDealsTotal();
    for(int i = 0; i < total; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket == 0) continue;
        
        long pid = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
        long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
        
        if(pid == positionId && (entry == DEAL_ENTRY_IN)) {
            datetime openTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            return (long)(closeTime - openTime);
        }
    }
    return 0;
}

//+------------------------------------------------------------------+
//| Calculate time-based breakdowns                                   |
//+------------------------------------------------------------------+
void CalculateTimeBreakdowns() {
    //--- Initialize struct arrays (ArrayInitialize doesn't work with structs)
    for(int h = 0; h < 24; h++) {
        g_hourly[h].trades = 0;
        g_hourly[h].wins = 0;
        g_hourly[h].pnl = 0;
    }
    for(int d = 0; d < 7; d++) {
        g_daily[d].trades = 0;
        g_daily[d].wins = 0;
        g_daily[d].pnl = 0;
    }
    for(int m = 0; m < 12; m++) {
        g_monthly[m].trades = 0;
        g_monthly[m].wins = 0;
        g_monthly[m].pnl = 0;
        g_monthly[m].maxDD = 0;
    }
    
    for(int i = 0; i < g_totalDeals; i++) {
        int h = g_deals[i].hourWIT;
        int d = g_deals[i].dayOfWeek;
        int m = g_deals[i].month - 1; // 0-based
        
        if(h >= 0 && h < 24) {
            g_hourly[h].trades++;
            if(g_deals[i].netProfit > 0) g_hourly[h].wins++;
            g_hourly[h].pnl += g_deals[i].netProfit;
        }
        
        if(d >= 0 && d < 7) {
            g_daily[d].trades++;
            if(g_deals[i].netProfit > 0) g_daily[d].wins++;
            g_daily[d].pnl += g_deals[i].netProfit;
        }
        
        if(m >= 0 && m < 12) {
            g_monthly[m].trades++;
            if(g_deals[i].netProfit > 0) g_monthly[m].wins++;
            g_monthly[m].pnl += g_deals[i].netProfit;
        }
    }
}

//+------------------------------------------------------------------+
//| Print core profitability metrics                                  |
//+------------------------------------------------------------------+
void PrintCoreMetrics() {
    double grossProfit = 0, grossLoss = 0;
    int wins = 0, losses = 0;
    double totalProfit = 0;
    double totalCommission = 0, totalSwap = 0;
    double maxWin = 0, maxLoss = 0;
    double sumWin = 0, sumLoss = 0;
    
    for(int i = 0; i < g_totalDeals; i++) {
        double np = g_deals[i].netProfit;
        totalProfit += np;
        totalCommission += g_deals[i].commission;
        totalSwap += g_deals[i].swap;
        
        if(np > 0) {
            grossProfit += np;
            wins++;
            sumWin += np;
            if(np > maxWin) maxWin = np;
        } else if(np < 0) {
            grossLoss += MathAbs(np);
            losses++;
            sumLoss += MathAbs(np);
            if(MathAbs(np) > maxLoss) maxLoss = MathAbs(np);
        }
    }
    
    double winRate = (g_totalDeals > 0) ? (double)wins / g_totalDeals * 100.0 : 0;
    double profitFactor = (grossLoss > 0) ? grossProfit / grossLoss : 0;
    double expectedPayoff = (g_totalDeals > 0) ? totalProfit / g_totalDeals : 0;
    double avgWin = (wins > 0) ? sumWin / wins : 0;
    double avgLoss = (losses > 0) ? sumLoss / losses : 0;
    double rrRatio = (avgLoss > 0) ? avgWin / avgLoss : 0;
    double commissionRatio = (grossProfit > 0) ? MathAbs(totalCommission) / grossProfit * 100.0 : 0;
    
    Print("┌─ CORE PROFITABILITY METRICS ──────────────────────────┐");
    Print("│ Total Trades:       ", g_totalDeals);
    Print("│ Wins / Losses:      ", wins, " / ", losses);
    Print("│ Win Rate:           ", DoubleToString(winRate, 2), "%");
    Print("│ Net Profit:         $", DoubleToString(totalProfit, 2));
    Print("│ Gross Profit:       $", DoubleToString(grossProfit, 2));
    Print("│ Gross Loss:         $", DoubleToString(grossLoss, 2));
    Print("│ Profit Factor:      ", DoubleToString(profitFactor, 3));
    Print("│ Expected Payoff:    $", DoubleToString(expectedPayoff, 4));
    Print("│ Avg Win:            $", DoubleToString(avgWin, 2));
    Print("│ Avg Loss:           $", DoubleToString(avgLoss, 2));
    Print("│ Risk:Reward Ratio:  ", DoubleToString(rrRatio, 2));
    Print("│ Max Single Win:     $", DoubleToString(maxWin, 2));
    Print("│ Max Single Loss:    $", DoubleToString(maxLoss, 2));
    Print("│ Total Commission:   $", DoubleToString(totalCommission, 2));
    Print("│ Total Swap:         $", DoubleToString(totalSwap, 2));
    Print("│ Commission Ratio:   ", DoubleToString(commissionRatio, 1), "% of gross profit");
    Print("└───────────────────────────────────────────────────────┘");
    Print("");
}

//+------------------------------------------------------------------+
//| Print risk metrics                                                |
//+------------------------------------------------------------------+
void PrintRiskMetrics() {
    double equity = 10000.0; // Assumed initial deposit
    double peakEquity = equity;
    double maxDD = 0, maxDDpct = 0;
    double currentDD = 0;
    int maxDDduration = 0;
    int currentDDduration = 0;
    datetime ddStartDate = 0;
    datetime maxDDstartDate = 0, maxDDendDate = 0;
    
    //--- Calculate drawdown curve
    double returns[];
    ArrayResize(returns, g_totalDeals);
    
    for(int i = 0; i < g_totalDeals; i++) {
        equity += g_deals[i].netProfit;
        returns[i] = g_deals[i].netProfit;
        
        if(equity > peakEquity) {
            peakEquity = equity;
            currentDDduration = 0;
        } else {
            currentDDduration++;
            double dd = peakEquity - equity;
            double ddPct = dd / peakEquity * 100.0;
            
            if(dd > maxDD) {
                maxDD = dd;
                maxDDpct = ddPct;
                maxDDduration = currentDDduration;
            }
        }
    }
    
    double finalEquity = equity;
    double netProfit = finalEquity - 10000.0;
    double recoveryFactor = (maxDD > 0) ? netProfit / maxDD : 0;
    
    //--- Sharpe Ratio (annualized, assuming 250 trading days)
    double meanReturn = 0;
    for(int i = 0; i < g_totalDeals; i++) meanReturn += returns[i];
    meanReturn /= g_totalDeals;
    
    double variance = 0;
    for(int i = 0; i < g_totalDeals; i++) {
        double diff = returns[i] - meanReturn;
        variance += diff * diff;
    }
    variance /= g_totalDeals;
    double stdDev = MathSqrt(variance);
    
    double sharpe = (stdDev > 0) ? (meanReturn / stdDev) * MathSqrt(250.0) : 0;
    
    //--- Sortino Ratio (downside deviation only)
    double downsideVariance = 0;
    int downsideCount = 0;
    for(int i = 0; i < g_totalDeals; i++) {
        if(returns[i] < 0) {
            downsideVariance += returns[i] * returns[i];
            downsideCount++;
        }
    }
    double downsideDev = (downsideCount > 0) ? MathSqrt(downsideVariance / downsideCount) : 0;
    double sortino = (downsideDev > 0) ? (meanReturn / downsideDev) * MathSqrt(250.0) : 0;
    
    Print("┌─ RISK METRICS ────────────────────────────────────────┐");
    Print("│ Initial Deposit:    $10,000.00");
    Print("│ Final Equity:       $", DoubleToString(finalEquity, 2));
    Print("│ Max Drawdown:       $", DoubleToString(maxDD, 2), " (", DoubleToString(maxDDpct, 2), "%)");
    Print("│ Max DD Duration:    ", maxDDduration, " trades");
    Print("│ Recovery Factor:    ", DoubleToString(recoveryFactor, 2));
    Print("│ Sharpe Ratio:       ", DoubleToString(sharpe, 3));
    Print("│ Sortino Ratio:      ", DoubleToString(sortino, 3));
    Print("│ Mean Trade Return:  $", DoubleToString(meanReturn, 4));
    Print("│ StdDev Returns:     $", DoubleToString(stdDev, 4));
    Print("└───────────────────────────────────────────────────────┘");
    Print("");
    
    //--- t-test for statistical significance
    double tStat = (stdDev > 0) ? (meanReturn / (stdDev / MathSqrt((double)g_totalDeals))) : 0;
    string significance = (MathAbs(tStat) > 1.96) ? "YES (95% confidence)" : "NO (insufficient evidence)";
    
    Print("┌─ STATISTICAL SIGNIFICANCE ────────────────────────────┐");
    Print("│ t-statistic:        ", DoubleToString(tStat, 3));
    Print("│ Significant Edge:   ", significance);
    Print("│ Minimum trades for 95% CI: ~", 
          IntegerToString((int)MathCeil(3.84 * 0.7 * 0.3 / (0.03*0.03))));
    Print("└───────────────────────────────────────────────────────┘");
    Print("");
}

//+------------------------------------------------------------------+
//| Print time-based analysis                                         |
//+------------------------------------------------------------------+
void PrintTimeAnalysis() {
    Print("┌─ HOURLY PERFORMANCE ──────────────────────────────────┐");
    Print("│ Hour   Trades   Wins    WR%      PnL                  │");
    Print("│ ────   ──────   ────   ─────   ──────                 │");
    
    for(int h = 0; h < 24; h++) {
        if(g_hourly[h].trades == 0) continue;
        double wr = (double)g_hourly[h].wins / g_hourly[h].trades * 100.0;
        string marker = "";
        if(h == 8 || h == 9 || h == 22 || h == 23) marker = " ⭐ GOLDEN";
        
        Print("│ ", StringFormat("%02d:00", h), "   ",
              StringFormat("%5d", g_hourly[h].trades), "   ",
              StringFormat("%4d", g_hourly[h].wins), "   ",
              StringFormat("%5.1f", wr), "%  $",
              StringFormat("%8.2f", g_hourly[h].pnl), marker);
    }
    Print("└───────────────────────────────────────────────────────┘");
    Print("");
    
    string dayNames[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
    Print("┌─ DAILY PERFORMANCE ───────────────────────────────────┐");
    Print("│ Day    Trades   Wins    WR%      PnL                  │");
    Print("│ ────   ──────   ────   ─────   ──────                 │");
    
    for(int d = 0; d < 7; d++) {
        if(g_daily[d].trades == 0) continue;
        double wr = (double)g_daily[d].wins / g_daily[d].trades * 100.0;
        
        Print("│ ", dayNames[d], "    ",
              StringFormat("%5d", g_daily[d].trades), "   ",
              StringFormat("%4d", g_daily[d].wins), "   ",
              StringFormat("%5.1f", wr), "%  $",
              StringFormat("%8.2f", g_daily[d].pnl));
    }
    Print("└───────────────────────────────────────────────────────┘");
    Print("");
}

//+------------------------------------------------------------------+
//| Print trade duration analysis                                     |
//+------------------------------------------------------------------+
void PrintDurationAnalysis() {
    //--- Duration buckets (seconds)
    int bucket_under1m = 0, win_under1m = 0;
    int bucket_1to5m = 0, win_1to5m = 0;
    int bucket_5to15m = 0, win_5to15m = 0;
    int bucket_15to30m = 0, win_15to30m = 0;
    int bucket_30to60m = 0, win_30to60m = 0;
    int bucket_1to2h = 0, win_1to2h = 0;
    int bucket_over2h = 0, win_over2h = 0;
    
    double pnl_under1m = 0, pnl_1to5m = 0, pnl_5to15m = 0;
    double pnl_15to30m = 0, pnl_30to60m = 0, pnl_1to2h = 0, pnl_over2h = 0;
    
    for(int i = 0; i < g_totalDeals; i++) {
        long dur = g_deals[i].durationSec;
        double np = g_deals[i].netProfit;
        bool isWin = (np > 0);
        
        if(dur < 60)           { bucket_under1m++; if(isWin) win_under1m++; pnl_under1m += np; }
        else if(dur < 300)     { bucket_1to5m++;   if(isWin) win_1to5m++;   pnl_1to5m += np; }
        else if(dur < 900)     { bucket_5to15m++;  if(isWin) win_5to15m++;  pnl_5to15m += np; }
        else if(dur < 1800)    { bucket_15to30m++; if(isWin) win_15to30m++; pnl_15to30m += np; }
        else if(dur < 3600)    { bucket_30to60m++; if(isWin) win_30to60m++; pnl_30to60m += np; }
        else if(dur < 7200)    { bucket_1to2h++;   if(isWin) win_1to2h++;   pnl_1to2h += np; }
        else                   { bucket_over2h++;  if(isWin) win_over2h++;  pnl_over2h += np; }
    }
    
    Print("┌─ TRADE DURATION ANALYSIS ─────────────────────────────┐");
    Print("│ Duration      Trades   Wins    WR%       PnL          │");
    Print("│ ──────────   ──────   ────   ──────   ────────        │");
    
    if(bucket_under1m > 0) {
        double wr = (double)win_under1m/bucket_under1m*100;
        Print("│ < 1 min      ", StringFormat("%5d", bucket_under1m), "   ",
              StringFormat("%4d", win_under1m), "   ", StringFormat("%5.1f", wr),
              "%  $", StringFormat("%8.2f", pnl_under1m));
    }
    if(bucket_1to5m > 0) {
        double wr = (double)win_1to5m/bucket_1to5m*100;
        Print("│ 1-5 min      ", StringFormat("%5d", bucket_1to5m), "   ",
              StringFormat("%4d", win_1to5m), "   ", StringFormat("%5.1f", wr),
              "%  $", StringFormat("%8.2f", pnl_1to5m), " ⭐ TARGET");
    }
    if(bucket_5to15m > 0) {
        double wr = (double)win_5to15m/bucket_5to15m*100;
        Print("│ 5-15 min     ", StringFormat("%5d", bucket_5to15m), "   ",
              StringFormat("%4d", win_5to15m), "   ", StringFormat("%5.1f", wr),
              "%  $", StringFormat("%8.2f", pnl_5to15m));
    }
    if(bucket_15to30m > 0) {
        double wr = (double)win_15to30m/bucket_15to30m*100;
        Print("│ 15-30 min    ", StringFormat("%5d", bucket_15to30m), "   ",
              StringFormat("%4d", win_15to30m), "   ", StringFormat("%5.1f", wr),
              "%  $", StringFormat("%8.2f", pnl_15to30m));
    }
    if(bucket_30to60m > 0) {
        double wr = (double)win_30to60m/bucket_30to60m*100;
        Print("│ 30-60 min    ", StringFormat("%5d", bucket_30to60m), "   ",
              StringFormat("%4d", win_30to60m), "   ", StringFormat("%5.1f", wr),
              "%  $", StringFormat("%8.2f", pnl_30to60m));
    }
    if(bucket_1to2h > 0) {
        double wr = (double)win_1to2h/bucket_1to2h*100;
        Print("│ 1-2 hours    ", StringFormat("%5d", bucket_1to2h), "   ",
              StringFormat("%4d", win_1to2h), "   ", StringFormat("%5.1f", wr),
              "%  $", StringFormat("%8.2f", pnl_1to2h), " ⚠ WARNING");
    }
    if(bucket_over2h > 0) {
        double wr = (double)win_over2h/bucket_over2h*100;
        Print("│ > 2 hours    ", StringFormat("%5d", bucket_over2h), "   ",
              StringFormat("%4d", win_over2h), "   ", StringFormat("%5.1f", wr),
              "%  $", StringFormat("%8.2f", pnl_over2h), " ❌ DANGER");
    }
    
    Print("└───────────────────────────────────────────────────────┘");
    Print("");
    
    //--- Duration vs QQ benchmark
    int totalShort = bucket_under1m + bucket_1to5m;
    double pctShort = (g_totalDeals > 0) ? (double)totalShort / g_totalDeals * 100.0 : 0;
    Print("│ Scalping ratio (< 5 min): ", DoubleToString(pctShort, 1), "% of trades");
    Print("│ QQ benchmark: 77% of trades were < 5 min");
    Print("");
}

//+------------------------------------------------------------------+
//| Print winning/losing streak analysis                              |
//+------------------------------------------------------------------+
void PrintStreakAnalysis() {
    int maxWinStreak = 0, maxLossStreak = 0;
    int currentWinStreak = 0, currentLossStreak = 0;
    
    int streakWinCounts[20];
    int streakLossCounts[20];
    ArrayInitialize(streakWinCounts, 0);
    ArrayInitialize(streakLossCounts, 0);
    
    for(int i = 0; i < g_totalDeals; i++) {
        if(g_deals[i].netProfit > 0) {
            currentWinStreak++;
            if(currentLossStreak > 0) {
                int idx = MathMin(currentLossStreak, 19);
                streakLossCounts[idx]++;
            }
            currentLossStreak = 0;
            if(currentWinStreak > maxWinStreak) maxWinStreak = currentWinStreak;
        } else {
            currentLossStreak++;
            if(currentWinStreak > 0) {
                int idx = MathMin(currentWinStreak, 19);
                streakWinCounts[idx]++;
            }
            currentWinStreak = 0;
            if(currentLossStreak > maxLossStreak) maxLossStreak = currentLossStreak;
        }
    }
    
    Print("┌─ STREAK ANALYSIS ─────────────────────────────────────┐");
    Print("│ Max Winning Streak:  ", maxWinStreak, " trades");
    Print("│ Max Losing Streak:   ", maxLossStreak, " trades");
    Print("│");
    Print("│ Losing streak distribution:");
    for(int s = 1; s <= MathMin(maxLossStreak, 10); s++) {
        string bar = "";
        for(int b = 0; b < MathMin(streakLossCounts[s], 50); b++) bar += "█";
        Print("│   ", s, " losses: ", StringFormat("%4d", streakLossCounts[s]), " times  ", bar);
    }
    Print("└───────────────────────────────────────────────────────┘");
    Print("");
}

//+------------------------------------------------------------------+
//| Print monthly breakdown                                           |
//+------------------------------------------------------------------+
void PrintMonthlyBreakdown() {
    string monthNames[] = {"Jan","Feb","Mar","Apr","May","Jun",
                           "Jul","Aug","Sep","Oct","Nov","Dec"};
    
    int profitableMonths = 0;
    int totalActiveMonths = 0;
    
    Print("┌─ MONTHLY PERFORMANCE ─────────────────────────────────┐");
    Print("│ Month    Trades   Wins    WR%       PnL               │");
    Print("│ ──────   ──────   ────   ──────   ────────            │");
    
    for(int m = 0; m < 12; m++) {
        if(g_monthly[m].trades == 0) continue;
        totalActiveMonths++;
        
        double wr = (double)g_monthly[m].wins / g_monthly[m].trades * 100.0;
        string status = (g_monthly[m].pnl > 0) ? " ✓" : " ✗";
        if(g_monthly[m].pnl > 0) profitableMonths++;
        
        Print("│ ", monthNames[m], "      ",
              StringFormat("%5d", g_monthly[m].trades), "   ",
              StringFormat("%4d", g_monthly[m].wins), "   ",
              StringFormat("%5.1f", wr), "%  $",
              StringFormat("%8.2f", g_monthly[m].pnl), status);
    }
    
    double pctProfitable = (totalActiveMonths > 0) ? 
                           (double)profitableMonths / totalActiveMonths * 100.0 : 0;
    
    Print("│");
    Print("│ Profitable months: ", profitableMonths, "/", totalActiveMonths,
          " (", DoubleToString(pctProfitable, 1), "%)");
    Print("│ Target: > 70% months profitable");
    Print("└───────────────────────────────────────────────────────┘");
    Print("");
}

//+------------------------------------------------------------------+
//| Export detailed data to CSV for external analysis                  |
//+------------------------------------------------------------------+
void ExportToCSV(string filePath) {
    int handle = FileOpen(filePath, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
    if(handle == INVALID_HANDLE) {
        Print("WARNING: Cannot create CSV file: ", filePath);
        return;
    }
    
    //--- Header
    FileWrite(handle, "Ticket", "DateTime", "Type", "Volume", "Price",
              "Profit", "Commission", "Swap", "NetProfit",
              "DurationSec", "DurationMin", "HourWIT", "DayOfWeek",
              "Month", "Year", "Comment");
    
    //--- Data rows
    for(int i = 0; i < g_totalDeals; i++) {
        string typeStr = (g_deals[i].type == DEAL_TYPE_BUY) ? "BUY" : "SELL";
        double durMin = g_deals[i].durationSec / 60.0;
        
        string dayNames[] = {"Sun","Mon","Tue","Wed","Thu","Fri","Sat"};
        string dayStr = (g_deals[i].dayOfWeek >= 0 && g_deals[i].dayOfWeek < 7) ?
                        dayNames[g_deals[i].dayOfWeek] : "?";
        
        FileWrite(handle,
            IntegerToString(g_deals[i].ticket),
            TimeToString(g_deals[i].time, TIME_DATE|TIME_SECONDS),
            typeStr,
            DoubleToString(g_deals[i].volume, 2),
            DoubleToString(g_deals[i].price, 2),
            DoubleToString(g_deals[i].profit, 2),
            DoubleToString(g_deals[i].commission, 2),
            DoubleToString(g_deals[i].swap, 2),
            DoubleToString(g_deals[i].netProfit, 2),
            IntegerToString(g_deals[i].durationSec),
            DoubleToString(durMin, 1),
            IntegerToString(g_deals[i].hourWIT),
            dayStr,
            IntegerToString(g_deals[i].month),
            IntegerToString(g_deals[i].year),
            g_deals[i].comment
        );
    }
    
    FileClose(handle);
    Print("CSV exported: MQL5/Files/", filePath);
}

//+------------------------------------------------------------------+
//| END OF PERFORMANCE ANALYZER                                       |
//+------------------------------------------------------------------+
