//+------------------------------------------------------------------+
//|                                              StrategyManager.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Strategy Manager - Orchestrates All 8 Strategies"

#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"
#include "../Core/IndicatorCache.mqh"
#include "../Strategies/TrendFollowing.mqh"
#include "../Strategies/Breakout.mqh"
#include "../Strategies/MeanReversion.mqh"
#include "../Strategies/SupplyDemand.mqh"
#include "../Strategies/SmartMoney.mqh"
#include "../Strategies/PriceAction.mqh"
#include "../Strategies/GridRecovery.mqh"
#include "../Strategies/MomentumScalping.mqh"

//+------------------------------------------------------------------+
//| Strategy Manager Class                                           |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Initialize all 8 strategies                                  |
//|   - Manage shared IndicatorCache                                 |
//|   - Evaluate strategies on each bar                              |
//|   - Collect signals from all active strategies                   |
//|   - Track strategy states and performance                        |
//|   - Apply adaptive weights from RegimeMemory                     |
//|                                                                  |
//| Strategy Order:                                                  |
//|   0 = TrendFollowing (1.2)                                       |
//|   1 = Breakout (1.1)                                             |
//|   2 = MeanReversion (1.0)                                        |
//|   3 = SupplyDemand (1.2)                                         |
//|   4 = SmartMoney (1.3)                                           |
//|   5 = PriceAction (1.0)                                          |
//|   6 = GridRecovery (0.7)                                         |
//|   7 = MomentumScalping (1.5) ⭐                                  |
//+------------------------------------------------------------------+
class StrategyManager {
private:
    //--- Strategy instances
    TrendFollowing*     m_trendFollowing;
    Breakout*           m_breakout;
    MeanReversion*      m_meanReversion;
    SupplyDemand*       m_supplyDemand;
    SmartMoney*         m_smartMoney;
    PriceAction*        m_priceAction;
    GridRecovery*       m_gridRecovery;
    MomentumScalping*   m_momentumScalping;
    
    //--- Strategy array for iteration
    BaseStrategy*       m_strategies[8];
    
    //--- Shared indicator cache
    IndicatorCache*     m_cache;
    
    //--- Symbol and timeframe
    string              m_symbol;
    ENUM_TIMEFRAMES     m_timeframe;
    
    //--- Strategy state tracking
    bool                m_initialized;
    int                 m_activeCount;
    bool                m_strategyActive[8];
    SignalResult        m_signals[8];
    
public:
    //--- Constructor / Destructor
    StrategyManager();
    ~StrategyManager();
    
    //--- Initialization
    bool                Init(string symbol, ENUM_TIMEFRAMES timeframe);
    void                Deinit();
    
    //--- Main evaluation
    void                EvaluateAll(const MarketState &state);
    void                UpdateStrategyStates(const MarketState &state);
    
    //--- Get results
    void                GetAllSignals(SignalResult &results[]);
    int                 GetActiveStrategyCount() { return m_activeCount; }
    bool                IsStrategyActive(int index);
    string              GetStrategyStatus(int index);
    string              GetStrategyName(int index);
    double              GetStrategyWeight(int index);
    
    //--- Validation
    bool                IsInitialized() { return m_initialized; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
StrategyManager::StrategyManager(void) :
    m_trendFollowing(NULL),
    m_breakout(NULL),
    m_meanReversion(NULL),
    m_supplyDemand(NULL),
    m_smartMoney(NULL),
    m_priceAction(NULL),
    m_gridRecovery(NULL),
    m_momentumScalping(NULL),
    m_cache(NULL),
    m_initialized(false),
    m_activeCount(0)
{
    // Initialize arrays
    ArrayInitialize(m_strategyActive, false);
    
    for(int i = 0; i < 8; i++) {
        m_strategies[i] = NULL;
        m_signals[i].signal = SIGNAL_NONE;
        m_signals[i].strength = 0.0;
        m_signals[i].weight = 0.0;
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
StrategyManager::~StrategyManager(void) {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize all strategies                                        |
//+------------------------------------------------------------------+
bool StrategyManager::Init(string symbol, ENUM_TIMEFRAMES timeframe) {
    Print("========================================");
    Print("StrategyManager - Initializing");
    Print("========================================");
    
    m_symbol = symbol;
    m_timeframe = timeframe;
    
    //--- Create shared IndicatorCache
    m_cache = new IndicatorCache();
    if(m_cache == NULL) {
        Print("ERROR: Failed to create IndicatorCache");
        return false;
    }
    
    if(!m_cache.Init(symbol, timeframe)) {
        Print("ERROR: Failed to initialize IndicatorCache");
        delete m_cache;
        m_cache = NULL;
        return false;
    }
    
    Print("IndicatorCache initialized successfully");
    
    //--- Strategy 0: TrendFollowing
    m_trendFollowing = new TrendFollowing();
    if(m_trendFollowing == NULL) {
        Print("ERROR: Failed to create TrendFollowing");
        Deinit();
        return false;
    }
    m_trendFollowing.Init(m_cache, WEIGHT_TREND_FOLLOWING, symbol, timeframe);
    m_strategies[0] = m_trendFollowing;
    Print("[0] TrendFollowing initialized - Weight: ", WEIGHT_TREND_FOLLOWING);
    
    //--- Strategy 1: Breakout
    m_breakout = new Breakout();
    if(m_breakout == NULL) {
        Print("ERROR: Failed to create Breakout");
        Deinit();
        return false;
    }
    m_breakout.Init(m_cache, WEIGHT_BREAKOUT, symbol, timeframe);
    m_strategies[1] = m_breakout;
    Print("[1] Breakout initialized - Weight: ", WEIGHT_BREAKOUT);
    
    //--- Strategy 2: MeanReversion
    m_meanReversion = new MeanReversion();
    if(m_meanReversion == NULL) {
        Print("ERROR: Failed to create MeanReversion");
        Deinit();
        return false;
    }
    m_meanReversion.Init(m_cache, WEIGHT_MEAN_REVERSION, symbol, timeframe);
    m_strategies[2] = m_meanReversion;
    Print("[2] MeanReversion initialized - Weight: ", WEIGHT_MEAN_REVERSION);
    
    //--- Strategy 3: SupplyDemand
    m_supplyDemand = new SupplyDemand();
    if(m_supplyDemand == NULL) {
        Print("ERROR: Failed to create SupplyDemand");
        Deinit();
        return false;
    }
    m_supplyDemand.Init(m_cache, WEIGHT_SUPPLY_DEMAND, symbol, timeframe);
    m_strategies[3] = m_supplyDemand;
    Print("[3] SupplyDemand initialized - Weight: ", WEIGHT_SUPPLY_DEMAND);
    
    //--- Strategy 4: SmartMoney
    m_smartMoney = new SmartMoney();
    if(m_smartMoney == NULL) {
        Print("ERROR: Failed to create SmartMoney");
        Deinit();
        return false;
    }
    m_smartMoney.Init(m_cache, WEIGHT_SMART_MONEY, symbol, timeframe);
    m_strategies[4] = m_smartMoney;
    Print("[4] SmartMoney initialized - Weight: ", WEIGHT_SMART_MONEY);
    
    //--- Strategy 5: PriceAction
    m_priceAction = new PriceAction();
    if(m_priceAction == NULL) {
        Print("ERROR: Failed to create PriceAction");
        Deinit();
        return false;
    }
    m_priceAction.Init(m_cache, WEIGHT_PRICE_ACTION, symbol, timeframe);
    m_strategies[5] = m_priceAction;
    Print("[5] PriceAction initialized - Weight: ", WEIGHT_PRICE_ACTION);
    
    //--- Strategy 6: GridRecovery
    m_gridRecovery = new GridRecovery();
    if(m_gridRecovery == NULL) {
        Print("ERROR: Failed to create GridRecovery");
        Deinit();
        return false;
    }
    m_gridRecovery.Init(m_cache, WEIGHT_GRID_RECOVERY, symbol, timeframe);
    m_strategies[6] = m_gridRecovery;
    Print("[6] GridRecovery initialized - Weight: ", WEIGHT_GRID_RECOVERY);
    
    //--- Strategy 7: MomentumScalping
    m_momentumScalping = new MomentumScalping();
    if(m_momentumScalping == NULL) {
        Print("ERROR: Failed to create MomentumScalping");
        Deinit();
        return false;
    }
    m_momentumScalping.Init(m_cache, WEIGHT_MOMENTUM_SCALP, symbol, timeframe);
    m_strategies[7] = m_momentumScalping;
    Print("[7] MomentumScalping initialized - Weight: ", WEIGHT_MOMENTUM_SCALP, " ⭐");
    
    m_initialized = true;
    
    Print("========================================");
    Print("All 8 strategies initialized successfully!");
    Print("Total weighted power: ", 
          WEIGHT_TREND_FOLLOWING + WEIGHT_BREAKOUT + WEIGHT_MEAN_REVERSION + 
          WEIGHT_SUPPLY_DEMAND + WEIGHT_SMART_MONEY + WEIGHT_PRICE_ACTION + 
          WEIGHT_GRID_RECOVERY + WEIGHT_MOMENTUM_SCALP);
    Print("========================================");
    
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup all strategies                                           |
//+------------------------------------------------------------------+
void StrategyManager::Deinit(void) {
    Print("StrategyManager - Cleaning up");
    
    // Delete strategies in reverse order
    if(m_momentumScalping != NULL) {
        delete m_momentumScalping;
        m_momentumScalping = NULL;
    }
    
    if(m_gridRecovery != NULL) {
        delete m_gridRecovery;
        m_gridRecovery = NULL;
    }
    
    if(m_priceAction != NULL) {
        delete m_priceAction;
        m_priceAction = NULL;
    }
    
    if(m_smartMoney != NULL) {
        delete m_smartMoney;
        m_smartMoney = NULL;
    }
    
    if(m_supplyDemand != NULL) {
        delete m_supplyDemand;
        m_supplyDemand = NULL;
    }
    
    if(m_meanReversion != NULL) {
        delete m_meanReversion;
        m_meanReversion = NULL;
    }
    
    if(m_breakout != NULL) {
        delete m_breakout;
        m_breakout = NULL;
    }
    
    if(m_trendFollowing != NULL) {
        delete m_trendFollowing;
        m_trendFollowing = NULL;
    }
    
    // Delete indicator cache
    if(m_cache != NULL) {
        m_cache.Deinit();
        delete m_cache;
        m_cache = NULL;
    }
    
    // Clear strategy array
    for(int i = 0; i < 8; i++) {
        m_strategies[i] = NULL;
    }
    
    m_initialized = false;
    Print("StrategyManager - Cleanup complete");
}

//+------------------------------------------------------------------+
//| Evaluate all strategies                                          |
//+------------------------------------------------------------------+
void StrategyManager::EvaluateAll(const MarketState &state) {
    if(!m_initialized) {
        Print("ERROR: StrategyManager not initialized");
        return;
    }
    
    // Refresh indicator cache
    if(!m_cache.Refresh(state)) {
        Print("WARNING: IndicatorCache refresh failed");
        return;
    }
    
    // Update strategy states and evaluate
    m_activeCount = 0;
    
    for(int i = 0; i < 8; i++) {
        if(m_strategies[i] == NULL) continue;
        
        // Evaluate strategy
        m_strategies[i].Evaluate(state);
        
        // Track active status
        m_strategyActive[i] = m_strategies[i].IsActive();
        if(m_strategyActive[i]) {
            m_activeCount++;
        }
        
        // Store signal results
        m_signals[i].signal = m_strategies[i].GetSignal();
        m_signals[i].strength = m_strategies[i].GetStrength();
        m_signals[i].weight = m_strategies[i].GetWeight();
        m_signals[i].strategyName = m_strategies[i].GetName();
    }
}

//+------------------------------------------------------------------+
//| Update strategy states based on market conditions                |
//+------------------------------------------------------------------+
void StrategyManager::UpdateStrategyStates(const MarketState &state) {
    // This is called as part of EvaluateAll
    // Strategies automatically activate/deactivate based on their CheckActivation() method
    // This method is kept for explicit state updates if needed
    
    m_activeCount = 0;
    for(int i = 0; i < 8; i++) {
        if(m_strategies[i] != NULL) {
            m_strategyActive[i] = m_strategies[i].IsActive();
            if(m_strategyActive[i]) {
                m_activeCount++;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Get all signal results                                           |
//+------------------------------------------------------------------+
void StrategyManager::GetAllSignals(SignalResult &results[]) {
    // IMPORTANT:
    // Do NOT call ArrayResize() here. Callers may pass a fixed-size array (static array),
    // and resizing a static array is undefined behavior and can corrupt memory/runtime state.
    // Instead, copy up to the available capacity.
    int capacity = ArraySize(results);
    // MQL5: some caller stacks report ArraySize==0 for fixed `SignalResult s[8]` — always copy 8.
    if(capacity < 1)
        capacity = 8;
    int n = MathMin(capacity, 8);
    for(int i = 0; i < n; i++) {
        results[i].signal = m_signals[i].signal;
        results[i].strength = m_signals[i].strength;
        results[i].weight = m_signals[i].weight;
        results[i].strategyName = m_signals[i].strategyName;
    }
    // If caller provided >8, clear the rest to safe defaults
    for(int j = n; j < capacity; j++) {
        results[j].signal = SIGNAL_NONE;
        results[j].strength = 0.0;
        results[j].weight = 0.0;
        results[j].strategyName = "";
    }
}

//+------------------------------------------------------------------+
//| Check if specific strategy is active                             |
//+------------------------------------------------------------------+
bool StrategyManager::IsStrategyActive(int index) {
    if(index < 0 || index >= 8) return false;
    return m_strategyActive[index];
}

//+------------------------------------------------------------------+
//| Get strategy status string                                       |
//+------------------------------------------------------------------+
string StrategyManager::GetStrategyStatus(int index) {
    if(index < 0 || index >= 8) return "INVALID";
    if(m_strategies[index] == NULL) return "NULL";
    
    string status = "";
    status += m_strategies[index].GetName();
    status += ": ";
    status += (m_strategyActive[index] ? "ACTIVE" : "INACTIVE");
    
    if(m_signals[index].signal != SIGNAL_NONE) {
        status += " | Signal: ";
        status += (m_signals[index].signal == SIGNAL_BUY ? "BUY" : "SELL");
        status += " (" + DoubleToString(m_signals[index].strength * 100, 1) + "%)";
    }
    
    return status;
}

//+------------------------------------------------------------------+
//| Get strategy name                                                |
//+------------------------------------------------------------------+
string StrategyManager::GetStrategyName(int index) {
    if(index < 0 || index >= 8) return "INVALID";
    if(m_strategies[index] == NULL) return "NULL";
    return m_strategies[index].GetName();
}

//+------------------------------------------------------------------+
//| Get strategy weight                                              |
//+------------------------------------------------------------------+
double StrategyManager::GetStrategyWeight(int index) {
    if(index < 0 || index >= 8) return 0.0;
    if(m_strategies[index] == NULL) return 0.0;
    return m_strategies[index].GetWeight();
}

//+------------------------------------------------------------------+
//| END OF STRATEGY MANAGER                                          |
//+------------------------------------------------------------------+
