//+------------------------------------------------------------------+
//|                                                SCALPX PRO v4.mq5 |
//+------------------------------------------------------------------+
#property copyright "SCALPX PRO"
#property link      ""
#property version   "4.14"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   8

//--- Plot Settings
#property indicator_label1  "EMA Fast"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMagenta
#property indicator_width1  2

#property indicator_label2  "EMA Medium"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_width2  2

#property indicator_label3  "EMA Slow"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue
#property indicator_width3  2

// Zone Lines
#property indicator_label4  "Zone Top"
#property indicator_type4   DRAW_NONE
#property indicator_label5  "Zone Bottom"
#property indicator_type5   DRAW_NONE

//--- Input Parameters
input group "🎯 SCALPX Scoring"
input double   InpBuyThreshold = 2.0;        // Buy Threshold
input double   InpSellThreshold = 2.0;       // Sell Threshold
input int      InpMinADX = 20;               // Minimum ADX
input int      InpConfirmBars = 2;           // Confirmation Bars

input group "⚖️ Scoring Weights"
input double   InpTrendWeight = 1.0;         // Trend Weight
input double   InpMomWeight = 1.0;           // Momentum Weight
input double   InpRSIWeight = 1.0;           // RSI Weight

input group "📍 SD Zone Detection"
input int      InpMinImpulseCandles = 2;     // Min Impulse Candles
input int      InpMaxBaseCandles = 3;        // Max Base Candles
input double   InpMinImpulseSize = 0.3;      // Min Impulse %
input double   InpMaxBaseSize = 0.15;        // Max Base %
input int      InpZoneExpiry = 50;           // Zone Expiry (Bars)
input double   InpPriceTooFar = 5.0;         // Zone Reset Distance %

input group "🔗 Filters & Integration"
input bool     InpUseSession = true;         // Enable Session Filter
input int      InpAsiaOpen = 0;              // Asia Open (Hour)
input int      InpLondonOpen = 8;            // London Open (Hour)
input int      InpNYOpen = 13;               // NY Open (Hour)
input bool     InpUseVolume = true;          // Enable Volume Filter

input group "🎯 SL/TP Settings"
input double   InpSLBuffer = 0.5;            // SL Buffer (ATR Multiplier)
input double   InpTP1RR = 2.0;               // TP1 Risk:Reward
input double   InpTP2RR = 3.0;               // TP2 Risk:Reward
input double   InpTP3RR = 4.0;               // TP3 Risk:Reward
input double   InpAccountBalance = 10000;    // Account Balance
input double   InpRiskPercent = 1.0;         // Risk %

input group "🎨 Visuals"
input bool     InpShowDashboard = true;      // Show Main Dashboard (Right)
input bool     InpShowChecklist = true;      // Show Checklist (Left)
input bool     InpShowTradePanel = true;     // Show Trade Setup Panel (Bottom Right)
input bool     InpShowZoneLines = true;      // Show Zone Lines
input int      InpDashX = 5;                 // Main Dash X (Right)
input int      InpDashY = 50;                // Main Dash Y (Top)
input int      InpCheckX = 10;               // Checklist X (Left)
input int      InpCheckY = 50;               // Checklist Y (Bottom)

//--- Buffers
double EMAFastBuf[];
double EMAMediumBuf[];
double EMASlowBuf[];
double ZoneTopBuf[];
double ZoneBotBuf[];
double EntryBuf[];
double SLBuf[];
double TPBuf[];

//--- Global Handles & Vars
int hEMA8, hEMA21, hEMA50;
int hEMAFast, hEMAMedium, hEMASlow;
int hRSI, hMACD, hADX, hATR, hBB, hStoch;

string lastPattern = "NEUTRAL";
double lastTop = 0;
double lastBot = 0;
int    zoneCreatedBar = 0;
string currentSignal = "NEUTRAL";
int    buyConfirmCount = 0;
int    sellConfirmCount = 0;

// Dashboard Vars
double g_BuyScore = 0;
double g_SellScore = 0;
string g_Session = "OFF";
bool   g_SessionOK = false;
bool   g_VolOK = false;
double g_ADX = 0;
string g_ChecklistStatus = "NOT READY";
int    g_ChecksPassed = 0;

// Trade Vars
double g_Entry = 0;
double g_SL = 0;
double g_TP1 = 0;
double g_TP2 = 0;
double g_TP3 = 0;
double g_RiskDist = 0;
double g_PosSize = 0;
double g_RiskAmt = 0;
double g_SLPct = 0;

// Status strings
string g_TrendStatus = "NEUTRAL";
string g_MomStatus = "NEUTRAL";
string g_RSIStatus = "OK";

// --- CONSTANTS ---
// VERSION 4.14 PREFIX
#define DASH_PREFIX "SP_V14_"
#define CHK_PREFIX  "SC_V14_"
#define TRD_PREFIX  "TR_V14_"

#define DASH_WIDTH 230
#define DASH_BG_COLOR C'20,22,25'
#define DASH_BORDER_COLOR clrGold
#define DASH_TEXT_COLOR clrWhiteSmoke
#define DASH_TITLE_COLOR clrGold

#define CHK_WIDTH 240
#define CHK_BG_COLOR C'25,25,25'
#define CHK_BORDER_COLOR clrDarkTurquoise
#define CHK_TEXT_COLOR clrSilver
#define CHK_FONT "Calibri"

#define TRD_WIDTH 230
#define TRD_BG_COLOR C'20,22,25'
#define TRD_BORDER_COLOR clrDarkTurquoise

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, EMAFastBuf, INDICATOR_DATA);
   SetIndexBuffer(1, EMAMediumBuf, INDICATOR_DATA);
   SetIndexBuffer(2, EMASlowBuf, INDICATOR_DATA);
   SetIndexBuffer(3, ZoneTopBuf, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, ZoneBotBuf, INDICATOR_CALCULATIONS);
   
   ArraySetAsSeries(EMAFastBuf, true);
   ArraySetAsSeries(EMAMediumBuf, true);
   ArraySetAsSeries(EMASlowBuf, true);
   
   // --- NUCLEAR CLEANUP ON INIT ---
   ObjectsDeleteAll(0, "Scalpx"); 
   ObjectsDeleteAll(0, "SP_");    
   ObjectsDeleteAll(0, "SC_");    
   ObjectsDeleteAll(0, "SPRO_");
   ObjectsDeleteAll(0, "TR_");
   
   ChartRedraw(0);
   
   // Initialize Handles
   hEMA8 = iMA(_Symbol, PERIOD_CURRENT, 8, 0, MODE_EMA, PRICE_CLOSE);
   hEMA21 = iMA(_Symbol, PERIOD_CURRENT, 21, 0, MODE_EMA, PRICE_CLOSE);
   hEMA50 = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
   
   hEMAFast = iMA(_Symbol, PERIOD_CURRENT, 17, 0, MODE_EMA, PRICE_CLOSE);
   hEMAMedium = iMA(_Symbol, PERIOD_CURRENT, 72, 0, MODE_EMA, PRICE_CLOSE);
   hEMASlow = iMA(_Symbol, PERIOD_CURRENT, 305, 0, MODE_EMA, PRICE_CLOSE);
   
   hRSI = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
   hMACD = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
   hADX = iADX(_Symbol, PERIOD_CURRENT, 14);
   hATR = iATR(_Symbol, PERIOD_CURRENT, 14);
   hBB = iBands(_Symbol, PERIOD_CURRENT, 20, 0, 2, PRICE_CLOSE);
   hStoch = iStochastic(_Symbol, PERIOD_CURRENT, 14, 3, 3, MODE_SMA, STO_LOWHIGH);

   IndicatorSetString(INDICATOR_SHORTNAME, "SCALPX PRO v4.14");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < 305) return(0);
   
   // Periodic Cleanup
   static int tickCounter = 0;
   tickCounter++;
   if(tickCounter % 50 == 0) { 
      ObjectsDeleteAll(0, "Scalpx"); 
      ObjectsDeleteAll(0, "SPRO_");
      ObjectsDeleteAll(0, "SP_FINAL_");
      ObjectsDeleteAll(0, "SC_FINAL_");
      ObjectsDeleteAll(0, "SP_V12_"); 
      ObjectsDeleteAll(0, "SC_V12_");
      ObjectsDeleteAll(0, "SP_V13_"); 
      ObjectsDeleteAll(0, "SC_V13_");
      ObjectsDeleteAll(0, "TR_V13_");
   }
   
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(tick_volume, true);
   
   // --- COPY BUFFERS ---
   double ema8[], ema21[], ema50[];
   double emaF[], emaM[], emaS[];
   double rsi[], macd[], macdSig[], adx[], diP[], diM[];
   double bbUp[], bbLo[], stochK[], stochD[], atr[];
   
   CopyBuffer(hEMA8, 0, 0, 3, ema8);
   CopyBuffer(hEMA21, 0, 0, 3, ema21);
   CopyBuffer(hEMA50, 0, 0, 3, ema50);
   CopyBuffer(hEMAFast, 0, 0, rates_total, emaF);
   CopyBuffer(hEMAMedium, 0, 0, rates_total, emaM);
   CopyBuffer(hEMASlow, 0, 0, rates_total, emaS);
   CopyBuffer(hRSI, 0, 0, 3, rsi);
   CopyBuffer(hMACD, 0, 0, 3, macd);
   CopyBuffer(hMACD, 1, 0, 3, macdSig);
   CopyBuffer(hADX, 0, 0, 3, adx);
   CopyBuffer(hADX, 1, 0, 3, diP);
   CopyBuffer(hADX, 2, 0, 3, diM);
   CopyBuffer(hBB, 1, 0, 3, bbUp);
   CopyBuffer(hBB, 2, 0, 3, bbLo);
   CopyBuffer(hStoch, 0, 0, 3, stochK);
   CopyBuffer(hStoch, 1, 0, 3, stochD);
   CopyBuffer(hATR, 0, 0, 3, atr);
   
   ArraySetAsSeries(ema8, true); ArraySetAsSeries(ema21, true); ArraySetAsSeries(ema50, true);
   ArraySetAsSeries(emaF, true); ArraySetAsSeries(emaM, true); ArraySetAsSeries(emaS, true);
   ArraySetAsSeries(rsi, true); ArraySetAsSeries(macd, true); ArraySetAsSeries(macdSig, true);
   ArraySetAsSeries(adx, true); ArraySetAsSeries(diP, true); ArraySetAsSeries(diM, true);
   ArraySetAsSeries(bbUp, true); ArraySetAsSeries(bbLo, true);
   ArraySetAsSeries(stochK, true); ArraySetAsSeries(stochD, true); ArraySetAsSeries(atr, true);

   for(int i=0; i<rates_total; i++) {
      EMAFastBuf[i] = emaF[i];
      EMAMediumBuf[i] = emaM[i];
      EMASlowBuf[i] = emaS[i];
   }

   // --- 1. SESSION FILTER ---
   MqlDateTime dt;
   TimeToStruct(time[0], dt);
   int h = dt.hour;
   
   bool isAsia = (h >= InpAsiaOpen && h < 8);
   bool isLondon = (h >= InpLondonOpen && h < 16);
   bool isNY = (h >= InpNYOpen && h < 22);
   
   g_Session = isNY ? "NEW YORK" : (isLondon ? "LONDON" : (isAsia ? "ASIA" : "OFF"));
   if(isLondon && isNY) g_Session = "NY-LON";
   g_SessionOK = InpUseSession ? (isAsia || isLondon || isNY) : true;

   // --- 2. SCORING ---
   double buyScore = 0;
   double sellScore = 0;
   
   bool trendBull = (close[0] > ema50[0] && ema8[0] > ema21[0] && ema21[0] > ema50[0]);
   bool trendBear = (close[0] < ema50[0] && ema8[0] < ema21[0] && ema21[0] < ema50[0]);
   if(trendBull) buyScore += InpTrendWeight;
   if(trendBear) sellScore += InpTrendWeight;
   
   g_TrendStatus = trendBull ? "BULL" : (trendBear ? "BEAR" : "NEUTRAL");
   
   double hist = macd[0] - macdSig[0];
   double histPrev = macd[1] - macdSig[1];
   bool momUp = (macd[0] > macdSig[0] && hist > 0 && hist > histPrev);
   bool momDown = (macd[0] < macdSig[0] && hist < 0 && hist < histPrev);
   if(momUp) buyScore += InpMomWeight;
   if(momDown) sellScore += InpMomWeight;
   
   g_MomStatus = momUp ? "UP" : (momDown ? "DOWN" : "NEUTRAL");
   
   bool rsiNeutral = (rsi[0] >= 30 && rsi[0] <= 70);
   if(rsiNeutral) {
      if(rsi[0] > 50) buyScore += InpRSIWeight * 0.5;
      if(rsi[0] < 50) sellScore += InpRSIWeight * 0.5;
   }
   
   g_RSIStatus = rsiNeutral ? "OK" : (rsi[0]>70 ? "OVERBOUGHT" : "OVERSOLD");
   
   if(close[0] > bbUp[0] && momUp) buyScore += 0.3;
   if(close[0] < bbLo[0] && momDown) sellScore += 0.3;
   
   if(stochK[0] < 20 && stochD[0] < 20) buyScore += 0.2;
   if(stochK[0] > 80 && stochD[0] > 80) sellScore += 0.2;
   
   g_ADX = adx[0];
   if(adx[0] > 25 && diP[0] > diM[0]) buyScore += 0.3;
   if(adx[0] > 25 && diM[0] > diP[0]) sellScore += 0.3;
   
   // --- 3. VOLUME FILTER ---
   double volSum = 0;
   for(int k=0; k<20; k++) volSum += (double)tick_volume[k];
   double volAvg = volSum / 20.0;
   bool volConfirm = ((double)tick_volume[0] > volAvg * 1.3);
   g_VolOK = volConfirm;
   
   if(InpUseVolume && volConfirm) {
      if(momUp) buyScore += 0.2;
      if(momDown) sellScore += 0.2;
   }
   
   g_BuyScore = buyScore;
   g_SellScore = sellScore;

   // --- 4. ZONES ---
   static datetime lastBarTime = 0;
   if(time[0] != lastBarTime || rates_total - zoneCreatedBar > InpZoneExpiry)
   {
      lastBarTime = time[0];
      
      bool impulseBuy = (close[1] > open[1] && GetCandleSize(high, low, open, close, 1) > InpMinImpulseSize);
      bool impulseSell = (close[1] < open[1] && GetCandleSize(high, low, open, close, 1) > InpMinImpulseSize);
      
      if(impulseBuy) {
         int baseCnt = 0;
         double maxH = 0; double minL = 999999;
         for(int k=2; k<=2+InpMaxBaseCandles; k++) {
            if(GetCandleSize(high, low, open, close, k) <= InpMaxBaseSize) {
               baseCnt++;
               if(high[k] > maxH) maxH = high[k];
               if(low[k] < minL) minL = low[k];
            } else break;
         }
         // Confirm rally after base
         if(baseCnt >= 1 && (close[2+baseCnt] > open[2+baseCnt])) {
            lastPattern = "BUY";
            lastTop = maxH;
            lastBot = minL;
            zoneCreatedBar = rates_total;
         }
      }
      
      if(impulseSell) {
         int baseCnt = 0;
         double maxH = 0; double minL = 999999;
         for(int k=2; k<=2+InpMaxBaseCandles; k++) {
            if(GetCandleSize(high, low, open, close, k) <= InpMaxBaseSize) {
               baseCnt++;
               if(high[k] > maxH) maxH = high[k];
               if(low[k] < minL) minL = low[k];
            } else break;
         }
         // Confirm drop after base
         if(baseCnt >= 1 && (close[2+baseCnt] < open[2+baseCnt])) {
            lastPattern = "SELL";
            lastTop = maxH;
            lastBot = minL;
            zoneCreatedBar = rates_total;
         }
      }
   }
   
   // --- ZONE RESET (PRICE TOO FAR) ---
   if(lastPattern != "NEUTRAL") {
      double distPct = 0;
      if(close[0] > lastTop) distPct = (close[0] - lastTop)/lastTop * 100.0;
      else if(close[0] < lastBot) distPct = (lastBot - close[0])/lastBot * 100.0;
      
      if(distPct > InpPriceTooFar) {
         lastPattern = "NEUTRAL"; // Reset zone
         lastTop = 0;
         lastBot = 0;
      }
   }
   
   // --- 5. CHECKLIST ---
   bool signalBuy = (buyScore >= InpBuyThreshold && buyScore > sellScore);
   bool signalSell = (sellScore >= InpSellThreshold && sellScore > buyScore);
   
   if(signalBuy) { buyConfirmCount++; sellConfirmCount=0; }
   else if(signalSell) { sellConfirmCount++; buyConfirmCount=0; }
   else { buyConfirmCount=0; sellConfirmCount=0; }
   
   bool confirmed = (buyConfirmCount >= InpConfirmBars || sellConfirmCount >= InpConfirmBars);
   if(confirmed) currentSignal = (buyConfirmCount > sellConfirmCount) ? "BUY" : "SELL";
   else currentSignal = "NEUTRAL";
   
   bool zoneFresh = (rates_total - zoneCreatedBar < InpZoneExpiry);
   bool zoneInside = false;
   if(lastPattern != "NEUTRAL" && close[0] >= lastBot && close[0] <= lastTop) zoneInside = true;
   
   bool zoneConfirmed = (lastPattern != "NEUTRAL" && lastPattern == currentSignal);
   
   g_ChecksPassed = 0;
   if(currentSignal != "NEUTRAL") g_ChecksPassed++;
   if((currentSignal=="BUY" && buyScore >= InpBuyThreshold) || (currentSignal=="SELL" && sellScore >= InpSellThreshold)) g_ChecksPassed++;
   if(zoneInside || zoneConfirmed) g_ChecksPassed++; 
   if(g_ADX >= InpMinADX) g_ChecksPassed++;
   if(g_SessionOK) g_ChecksPassed++;
   
   if(zoneFresh && lastPattern != "NEUTRAL") g_ChecksPassed++;
   
   if(g_ChecksPassed == 6) g_ChecklistStatus = "READY";
   else if(g_ChecksPassed >= 4) g_ChecklistStatus = "ALMOST";
   else g_ChecklistStatus = "NOT READY";

   // --- TRADE CALCULATIONS ---
   if(g_ChecklistStatus == "READY" && currentSignal != "NEUTRAL") {
      g_Entry = close[0];
      double curATR = atr[0];
      if(currentSignal == "BUY") {
         g_SL = lastBot - (curATR * InpSLBuffer);
         g_RiskDist = g_Entry - g_SL;
         if(g_RiskDist > 0) {
            g_TP1 = g_Entry + (g_RiskDist * InpTP1RR);
            g_TP2 = g_Entry + (g_RiskDist * InpTP2RR);
            g_TP3 = g_Entry + (g_RiskDist * InpTP3RR);
         }
      } else {
         g_SL = lastTop + (curATR * InpSLBuffer);
         g_RiskDist = g_SL - g_Entry;
         if(g_RiskDist > 0) {
            g_TP1 = g_Entry - (g_RiskDist * InpTP1RR);
            g_TP2 = g_Entry - (g_RiskDist * InpTP2RR);
            g_TP3 = g_Entry - (g_RiskDist * InpTP3RR);
         }
      }
      
      if(g_RiskDist > 0) {
         g_RiskAmt = InpAccountBalance * (InpRiskPercent / 100.0);
         double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
         double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
         if(tickValue > 0 && tickSize > 0) {
            g_PosSize = g_RiskAmt / (g_RiskDist / tickSize * tickValue);
         }
         g_SLPct = (g_RiskDist / g_Entry) * 100.0;
      }
   } else {
      // Reset if not ready
      g_Entry = 0; g_SL = 0; g_PosSize = 0;
   }

   // --- DRAW ---
   if(InpShowDashboard) DrawMainDashboard(close[0], atr[0]);
   else ObjectsDeleteAll(0, DASH_PREFIX);

   if(InpShowChecklist) 
      DrawChecklistPanel(zoneConfirmed, zoneFresh); 
   else ObjectsDeleteAll(0, CHK_PREFIX);
   
   if(InpShowTradePanel)
      DrawTradePanel();
   else ObjectsDeleteAll(0, TRD_PREFIX);

   if(InpShowZoneLines && lastPattern != "NEUTRAL") DrawZones();

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
double GetCandleSize(const double &h[], const double &l[], const double &o[], const double &c[], int i) {
   double avg = (h[i] + l[i]) / 2.0;
   if(avg == 0) return 0;
   return MathAbs(c[i] - o[i]) / avg * 100.0;
}

void CreateRect(string prefix, string name, int x, int y, int w, int h, color bg, color border, ENUM_BASE_CORNER corner, ENUM_ANCHOR_POINT anchor)
{
   string n = prefix + name;
   if(ObjectFind(0, n) < 0) {
      ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, n, OBJPROP_CORNER, corner);
      ObjectSetInteger(0, n, OBJPROP_ANCHOR, anchor);
      ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
      ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, n, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, n, OBJPROP_BACK, false);
   }
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, n, OBJPROP_COLOR, border);
}

void CreateLabel(string prefix, string name, int x, int y, string text, int fontSize, color clr, ENUM_BASE_CORNER corner, ENUM_ANCHOR_POINT anchor, string font="Trebuchet MS")
{
   string n = prefix + name;
   if(ObjectFind(0, n) < 0) {
      ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, n, OBJPROP_CORNER, corner);
      ObjectSetInteger(0, n, OBJPROP_BACK, false);
   }
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, n, OBJPROP_TEXT, text);
   ObjectSetString(0, n, OBJPROP_FONT, font);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, n, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, n, OBJPROP_ANCHOR, anchor);
}

//+------------------------------------------------------------------+
//| DRAW FUNCTIONS                                                   |
//+------------------------------------------------------------------+
void DrawMainDashboard(double currentPrice, double atr)
{
   int x = InpDashX; int y = InpDashY; int w = DASH_WIDTH; int h = 360; 
   ENUM_BASE_CORNER c = CORNER_RIGHT_UPPER; ENUM_ANCHOR_POINT a = ANCHOR_RIGHT_UPPER;
   
   CreateRect(DASH_PREFIX, "BG", x, y, w, h, DASH_BG_COLOR, DASH_BORDER_COLOR, c, a);
   int curY = y + 10; 
   CreateLabel(DASH_PREFIX, "Title", x + w/2, curY, "SCALPX PRO", 11, DASH_TITLE_COLOR, c, ANCHOR_UPPER);
   curY += 25;
   CreateRect(DASH_PREFIX, "Sep1", x, curY, w, 1, clrDimGray, clrDimGray, c, a); 
   curY += 15;
   
   CreateLabel(DASH_PREFIX,"SigL", x+w-10, curY, "SIGNAL", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   color sc = (currentSignal=="BUY")?clrLime:(currentSignal=="SELL"?clrRed:clrGray);
   CreateLabel(DASH_PREFIX,"SigV", x+10, curY, currentSignal, 10, sc, c, ANCHOR_RIGHT_UPPER, "Arial Black");
   curY+=20;
   CreateLabel(DASH_PREFIX,"PrcL", x+w-10, curY, "Price", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   CreateLabel(DASH_PREFIX,"PrcV", x+10, curY, DoubleToString(currentPrice,_Digits), 8, clrWhite, c, ANCHOR_RIGHT_UPPER);
   
   curY+=25; CreateLabel(DASH_PREFIX,"AnaH", x+w/2, curY, "SCALPX ANALYSIS", 7, clrGold, c, ANCHOR_UPPER); curY+=15;
   CreateLabel(DASH_PREFIX,"BuyL", x+w-10, curY, "Buy Score", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   CreateLabel(DASH_PREFIX,"BuyV", x+10, curY, DoubleToString(g_BuyScore,1), 8, clrLime, c, ANCHOR_RIGHT_UPPER); curY+=18;
   CreateLabel(DASH_PREFIX,"SelL", x+w-10, curY, "Sell Score", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   CreateLabel(DASH_PREFIX,"SelV", x+10, curY, DoubleToString(g_SellScore,1), 8, clrRed, c, ANCHOR_RIGHT_UPPER);
   
   curY+=25; CreateLabel(DASH_PREFIX,"ZonH", x+w/2, curY, "ZONE CONFIRMATION", 7, clrGold, c, ANCHOR_UPPER); curY+=15;
   CreateLabel(DASH_PREFIX,"PatL", x+w-10, curY, "Pattern", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   color pc = (lastPattern=="BUY")?clrLime:(lastPattern=="SELL"?clrRed:clrGray);
   CreateLabel(DASH_PREFIX,"PatV", x+10, curY, lastPattern, 8, pc, c, ANCHOR_RIGHT_UPPER); curY+=18;
   CreateLabel(DASH_PREFIX,"ZTL", x+w-10, curY, "Zone Top", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   CreateLabel(DASH_PREFIX,"ZTV", x+10, curY, (lastTop>0?DoubleToString(lastTop,_Digits):"--"), 8, clrWhite, c, ANCHOR_RIGHT_UPPER); curY+=18;
   CreateLabel(DASH_PREFIX,"ZBL", x+w-10, curY, "Zone Bot", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   CreateLabel(DASH_PREFIX,"ZBV", x+10, curY, (lastBot>0?DoubleToString(lastBot,_Digits):"--"), 8, clrWhite, c, ANCHOR_RIGHT_UPPER);

   curY+=25; CreateLabel(DASH_PREFIX,"FltH", x+w/2, curY, "FILTERS", 7, clrGold, c, ANCHOR_UPPER); curY+=15;
   CreateLabel(DASH_PREFIX,"TrdL", x+w-10, curY, "Trend", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   CreateLabel(DASH_PREFIX,"TrdV", x+10, curY, g_TrendStatus, 8, (g_TrendStatus=="BULL"?clrLime:(g_TrendStatus=="BEAR"?clrRed:clrGray)), c, ANCHOR_RIGHT_UPPER); curY+=18;
   CreateLabel(DASH_PREFIX,"MomL", x+w-10, curY, "Momentum", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   CreateLabel(DASH_PREFIX,"MomV", x+10, curY, g_MomStatus, 8, (g_MomStatus=="UP"?clrLime:(g_MomStatus=="DOWN"?clrRed:clrGray)), c, ANCHOR_RIGHT_UPPER); curY+=18;
   CreateLabel(DASH_PREFIX,"RsiL", x+w-10, curY, "RSI (14)", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   CreateLabel(DASH_PREFIX,"RsiV", x+10, curY, g_RSIStatus, 8, (g_RSIStatus=="OK"?clrLime:clrOrange), c, ANCHOR_RIGHT_UPPER); curY+=18;
   CreateLabel(DASH_PREFIX,"AdxL", x+w-10, curY, "ADX", 8, DASH_TEXT_COLOR, c, ANCHOR_LEFT_UPPER);
   CreateLabel(DASH_PREFIX,"AdxV", x+10, curY, DoubleToString(g_ADX,1), 8, (g_ADX>=InpMinADX?clrLime:clrOrange), c, ANCHOR_RIGHT_UPPER);
}

void DrawChecklistPanel(bool zoneConfirmed, bool isZoneFresh)
{
   int x = InpCheckX; int y = InpCheckY; int w = CHK_WIDTH; int h = 260; 
   ENUM_BASE_CORNER c = CORNER_LEFT_LOWER; ENUM_ANCHOR_POINT a = ANCHOR_LEFT_LOWER;
   
   CreateRect(CHK_PREFIX, "BG", x, y, w, h, CHK_BG_COLOR, CHK_BORDER_COLOR, c, a);
   int curY = y + h - 10; int cx = x + w/2;
   
   CreateLabel(CHK_PREFIX,"Tit", cx, curY, "ENTRY CHECKLIST", 10, CHK_BORDER_COLOR, c, ANCHOR_UPPER, "Arial");
   CreateLabel(CHK_PREFIX,"Cnt", x+w-15, curY, IntegerToString(g_ChecksPassed)+"/6", 10, (g_ChecksPassed>=5?clrRed:clrGray), c, ANCHOR_RIGHT_UPPER, "Arial");
   curY -= 25;
   color sc = (g_ChecklistStatus=="READY")?clrLime : (g_ChecklistStatus=="ALMOST"?clrOrange:clrRed);
   CreateLabel(CHK_PREFIX,"StL", x+15, curY, "Status:", 8, clrWhite, c, ANCHOR_LEFT_UPPER);
   CreateLabel(CHK_PREFIX,"StV", cx, curY+5, g_ChecklistStatus, 14, sc, c, ANCHOR_UPPER, "Arial Black");
   curY -= 25;
   CreateRect(CHK_PREFIX, "Sp1", x+10, curY, w-20, 1, clrDimGray, clrDimGray, c, ANCHOR_LEFT_LOWER); curY -= 10;
   
   DrawCheckRow(curY, "Signal Active", currentSignal!="NEUTRAL", currentSignal, c); curY -= 25;
   DrawCheckRow(curY, "Score >= Threshold", (currentSignal=="BUY"?g_BuyScore:g_SellScore)>=InpBuyThreshold, DoubleToString(currentSignal=="BUY"?g_BuyScore:g_SellScore,1)+"/2.0", c); curY -= 25;
   DrawCheckRow(curY, "Zone Confirmed", zoneConfirmed, (zoneConfirmed?"YES":"NO"), c); curY -= 25;
   DrawCheckRow(curY, "ADX >= "+IntegerToString(InpMinADX), g_ADX>=InpMinADX, IntegerToString((int)g_ADX), c); curY -= 25;
   DrawCheckRow(curY, "Good Session", g_SessionOK, g_Session, c); curY -= 25;
   
   bool df = (lastPattern!="NEUTRAL");
   string ft = df ? (isZoneFresh?"YES":"NO") : "N/A";
   DrawCheckRow(curY, "Zone Fresh", (df&&isZoneFresh), ft, c); 
   
   curY -= 15; CreateRect(CHK_PREFIX, "Sp2", x+10, curY, w-20, 1, clrDimGray, clrDimGray, c, ANCHOR_LEFT_LOWER); curY -= 10;
   string act = (g_ChecklistStatus=="READY") ? "EXECUTE TRADE" : "DO NOT TRADE";
   CreateLabel(CHK_PREFIX,"Act", cx, curY, ((g_ChecklistStatus=="READY")?"✔ ":"✘ ") + act, 10, ((g_ChecklistStatus=="READY")?clrLime:clrRed), c, ANCHOR_UPPER, "Arial Black");
}

void DrawCheckRow(int y, string label, bool pass, string value, ENUM_BASE_CORNER corner)
{
   int x = InpCheckX;
   string ic = pass ? "✔" : "✘";
   color c = pass ? clrLime : clrDimGray;
   if(label == "Signal Active" && !pass) c = clrDimGray;
   if(value == "N/A") { c = clrDimGray; ic = "✘"; }
   
   CreateLabel(CHK_PREFIX,"I_"+label, x+20, y, ic, 10, c, corner, ANCHOR_LEFT_UPPER, "Arial");
   CreateLabel(CHK_PREFIX,"L_"+label, x+50, y+2, label, 8, CHK_TEXT_COLOR, corner, ANCHOR_LEFT_UPPER, CHK_FONT);
   CreateLabel(CHK_PREFIX,"V_"+label, x+CHK_WIDTH-20, y+2, value, 8, c, corner, ANCHOR_RIGHT_UPPER, CHK_FONT);
}

void DrawTradePanel()
{
   if(g_Entry == 0) return; // Don't draw if not ready
   
   int x = InpDashX; int y = 20; // Bottom Right
   int w = TRD_WIDTH; int h = 300; 
   ENUM_BASE_CORNER c = CORNER_RIGHT_LOWER; ENUM_ANCHOR_POINT a = ANCHOR_RIGHT_LOWER;
   
   CreateRect(TRD_PREFIX, "BG", x, y, w, h, TRD_BG_COLOR, TRD_BORDER_COLOR, c, a);
   int curY = y + h - 15; int cx = x + w/2;
   
   CreateLabel(TRD_PREFIX, "Tit", cx, curY, "📊 " + lastPattern + " SETUP", 10, clrCyan, c, ANCHOR_UPPER, "Arial Black");
   curY -= 30;
   
   string st = "✓ ACTIVE"; color sc = clrLime;
   CreateLabel(TRD_PREFIX, "StL", x+20, curY, "Status:", 8, clrWhite, c, ANCHOR_LEFT_UPPER);
   CreateLabel(TRD_PREFIX, "StV", x+w-20, curY, st, 10, sc, c, ANCHOR_RIGHT_UPPER, "Arial Black");
   curY -= 20; CreateRect(TRD_PREFIX, "Sp1", x+10, curY, w-20, 1, clrDimGray, clrDimGray, c, ANCHOR_RIGHT_LOWER); curY -= 20;
   
   DrawTradeRow(curY, "Entry:", DoubleToString(g_Entry,_Digits), clrOrange, c); curY -= 20;
   DrawTradeRow(curY, "Stop Loss:", DoubleToString(g_SL,_Digits), clrRed, c); curY -= 20;
   DrawTradeRow(curY, "TP1 (1:"+DoubleToString(InpTP1RR,1)+")", DoubleToString(g_TP1,_Digits), clrLime, c); curY -= 20;
   DrawTradeRow(curY, "TP2 (1:"+DoubleToString(InpTP2RR,1)+")", DoubleToString(g_TP2,_Digits), clrLime, c); curY -= 20;
   DrawTradeRow(curY, "TP3 (1:"+DoubleToString(InpTP3RR,1)+")", DoubleToString(g_TP3,_Digits), clrLime, c); curY -= 25;
   
   CreateRect(TRD_PREFIX, "Sp2", x+10, curY, w-20, 1, clrDimGray, clrDimGray, c, ANCHOR_RIGHT_LOWER); curY -= 20;
   
   DrawTradeRow(curY, "Risk Amount:", "$"+DoubleToString(g_RiskAmt,2), clrRed, c); curY -= 20;
   DrawTradeRow(curY, "Pos Size:", DoubleToString(g_PosSize,2)+" lots", clrCyan, c);
}

void DrawTradeRow(int y, string label, string value, color valColor, ENUM_BASE_CORNER c)
{
   int x = InpDashX;
   // FIXED: Correctly calculate left-side position for CORNER_RIGHT
   // Larger X = Further Left
   CreateLabel(TRD_PREFIX, "L_"+label, x+TRD_WIDTH-20, y, label, 8, clrWhite, c, ANCHOR_LEFT_UPPER);
   CreateLabel(TRD_PREFIX, "V_"+label, x+20, y, value, 8, valColor, c, ANCHOR_RIGHT_UPPER);
}

void DrawZones() {
   string nT = DASH_PREFIX+"ZTop"; string nB = DASH_PREFIX+"ZBot";
   ObjectDelete(0,nT); ObjectDelete(0,nB);
   color c = (lastPattern=="BUY")?clrLime:clrRed;
   ObjectCreate(0,nT,OBJ_HLINE,0,0,lastTop); ObjectSetInteger(0,nT,OBJPROP_COLOR,c);
   ObjectCreate(0,nB,OBJ_HLINE,0,0,lastBot); ObjectSetInteger(0,nB,OBJPROP_COLOR,c);
}

void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, DASH_PREFIX);
   ObjectsDeleteAll(0, CHK_PREFIX);
   ObjectsDeleteAll(0, TRD_PREFIX);
   ObjectsDeleteAll(0, "Scalpx"); 
   ObjectsDeleteAll(0, "SP_");
   ObjectsDeleteAll(0, "SC_");
   ObjectsDeleteAll(0, "SPRO_");
}
//+------------------------------------------------------------------+