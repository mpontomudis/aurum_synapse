//+------------------------------------------------------------------+
//|                                           DiagnosticMinimal.mq5 |
//|                                      Minimal Diagnostic Test EA |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property version   "1.00"
#property description "Minimal EA to test if OnTick() is being called"

int g_tickCount = 0;
int g_barCount = 0;
datetime g_lastBar = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("========================================");
    Print("DIAGNOSTIC EA INITIALIZED");
    Print("Symbol: ", _Symbol);
    Print("Timeframe: ", EnumToString(_Period));
    Print("========================================");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("========================================");
    Print("DIAGNOSTIC EA STOPPED");
    Print("Total Ticks: ", g_tickCount);
    Print("Total Bars: ", g_barCount);
    Print("========================================");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    g_tickCount++;
    
    // Log every tick for first 10 ticks
    if(g_tickCount <= 10) {
        Print("TICK #", g_tickCount, " - Time: ", TimeToString(TimeCurrent()));
    }
    
    // Log every 100th tick
    if(g_tickCount % 100 == 0) {
        Print("TICK #", g_tickCount, " - Still running...");
    }
    
    // Count new bars
    datetime currentBar = iTime(_Symbol, _Period, 0);
    if(currentBar != g_lastBar) {
        g_lastBar = currentBar;
        g_barCount++;
        
        if(g_barCount <= 10 || g_barCount % 10 == 0) {
            Print("NEW BAR #", g_barCount, " @ ", TimeToString(currentBar));
        }
    }
}
//+------------------------------------------------------------------+
