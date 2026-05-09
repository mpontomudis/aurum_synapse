//+------------------------------------------------------------------+
//|                                                 MoneyManager.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Money Manager - Lot Sizing & Position Calculation"

#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"

//+------------------------------------------------------------------+
//| Money Manager Class                                              |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Calculate lot sizes using multiple methods                   |
//|   - Normalize lots to broker requirements                        |
//|   - Calculate risk amount for position sizing                    |
//|   - Validate margin requirements                                 |
//|                                                                  |
//| Lot Sizing Methods:                                              |
//|   LOT_FIXED: Simple fixed lot (e.g., 0.01)                       |
//|   LOT_AUTO: Risk-based (% of equity)                             |
//|   LOT_FIXED_PER_BALANCE: Fixed lot per $X balance                |
//|                                                                  |
//| Risk Multipliers (from specs):                                   |
//|   Conservative: 0.5-1.0% risk per trade                          |
//|   Balanced: 1.0-2.0% risk per trade                              |
//|   Aggressive: 2.0-3.0% risk per trade                            |
//+------------------------------------------------------------------+
class MoneyManager {
private:
    //--- Symbol information
    string           m_symbol;
    double           m_pointValue;
    double           m_tickSize;
    double           m_tickValue;
    double           m_contractSize;
    
    //--- Broker lot limits
    double           m_minLot;
    double           m_maxLot;
    double           m_lotStep;
    
    //--- Risk parameters
    ENUM_LOT_METHOD  m_lotMethod;
    double           m_fixedLot;
    double           m_riskPercent;
    double           m_fixedLotPerBalance;
    double           m_balanceIncrement;
    
    //--- Helper methods
    double CalculateLotByRisk(double slDistancePoints, double riskPercent);
    double CalculateLotByBalance(double balance);
    
public:
    //--- Constructor / Destructor
    MoneyManager();
    ~MoneyManager();
    
    //--- Initialization
    bool             Init(string symbol);
    
    //--- Main lot calculation method
    double           CalculateLotSize(ENUM_LOT_METHOD method,
                                      double riskLevel,
                                      double fixedLot,
                                      double fixedPerBalance,
                                      double maxRiskPct,
                                      double slDistancePoints = 0);
    
    //--- Lot normalization
    double           NormalizeLot(double lot);
    
    //--- Risk calculation
    double           CalculateRiskAmount(double lot, double slDistance);
    
    //--- Margin check
    bool             CheckMarginRequirement(double lot, ENUM_ORDER_TYPE orderType);
    
    //--- Accessors
    double           GetMinLot() { return m_minLot; }
    double           GetMaxLot() { return m_maxLot; }
    double           GetLotStep() { return m_lotStep; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
MoneyManager::MoneyManager(void) :
    m_minLot(0.01),
    m_maxLot(100.0),
    m_lotStep(0.01),
    m_lotMethod(LOT_FIXED),
    m_fixedLot(0.01),
    m_riskPercent(1.0),
    m_fixedLotPerBalance(0.01),
    m_balanceIncrement(1000.0),
    m_pointValue(0),
    m_tickSize(0),
    m_tickValue(0),
    m_contractSize(0)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
MoneyManager::~MoneyManager(void) {
}

//+------------------------------------------------------------------+
//| Initialize money manager                                         |
//+------------------------------------------------------------------+
bool MoneyManager::Init(string symbol) {
    m_symbol = symbol;
    
    Print("MoneyManager - Initializing for ", symbol);
    
    //--- Get symbol properties
    m_minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    m_maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    m_lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    m_tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    m_tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    m_contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    
    //--- Calculate point value
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(m_tickSize > 0) {
        m_pointValue = m_tickValue * (point / m_tickSize);
    }
    
    //--- Validate
    if(m_minLot <= 0 || m_maxLot <= 0 || m_lotStep <= 0) {
        Print("ERROR: Invalid symbol lot parameters");
        return false;
    }
    
    Print("MoneyManager initialized - MinLot: ", m_minLot, 
          " MaxLot: ", m_maxLot, " Step: ", m_lotStep);
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size using specified method                        |
//+------------------------------------------------------------------+
double MoneyManager::CalculateLotSize(ENUM_LOT_METHOD method,
                                       double riskLevel,
                                       double fixedLot,
                                       double fixedPerBalance,
                                       double maxRiskPct,
                                       double slDistancePoints = 0) {
    double lot = 0;
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    switch(method) {
        case LOT_FIXED:
            //--- Simple fixed lot
            lot = fixedLot;
            break;
            
        case LOT_AUTO:
            //--- Risk-based calculation
            if(slDistancePoints > 0) {
                lot = CalculateLotByRisk(slDistancePoints, riskLevel);
            } else {
                //--- Default to base lot if no SL distance provided
                lot = LOT_SIZE_BASE;
            }
            break;
            
        case LOT_FIXED_PER_BALANCE:
            //--- Fixed lot per $X balance
            lot = CalculateLotByBalance(balance);
            break;
            
        default:
            lot = LOT_SIZE_BASE;
            break;
    }
    
    //--- Apply maximum risk constraint
    if(method == LOT_AUTO && maxRiskPct > 0 && slDistancePoints > 0) {
        double maxLotByRisk = CalculateLotByRisk(slDistancePoints, maxRiskPct);
        lot = MathMin(lot, maxLotByRisk);
    }
    
    //--- Normalize and validate
    lot = NormalizeLot(lot);
    
    return lot;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double MoneyManager::CalculateLotByRisk(double slDistancePoints, double riskPercent) {
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double riskAmount = equity * (riskPercent / 100.0);
    
    //--- Calculate lot size based on point value
    double lot = 0;
    if(m_pointValue > 0 && slDistancePoints > 0) {
        lot = riskAmount / (slDistancePoints * m_pointValue);
    }
    
    //--- Fallback to base lot if calculation fails
    if(lot <= 0) {
        lot = LOT_SIZE_BASE;
    }
    
    return lot;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on balance increment                    |
//+------------------------------------------------------------------+
double MoneyManager::CalculateLotByBalance(double balance) {
    //--- Example: 0.01 lot per $1000 balance
    double increment = 1000.0;  // $1000 per 0.01 lot
    double baseLot = 0.01;
    
    double multiplier = MathFloor(balance / increment);
    double lot = baseLot * MathMax(1, multiplier);
    
    //--- Cap at maximum base lot
    lot = MathMin(lot, LOT_SIZE_MAX_BASE);
    
    return lot;
}

//+------------------------------------------------------------------+
//| Normalize lot size to broker requirements                        |
//+------------------------------------------------------------------+
double MoneyManager::NormalizeLot(double lot) {
    //--- Round to lot step
    if(m_lotStep > 0) {
        lot = MathFloor(lot / m_lotStep) * m_lotStep;
    }
    
    //--- Apply min/max limits
    lot = MathMax(lot, m_minLot);
    lot = MathMin(lot, m_maxLot);
    lot = MathMin(lot, LOT_SIZE_MAX_BASE);  // Also apply EA's max base lot
    
    //--- Round to 2 decimals
    lot = NormalizeDouble(lot, 2);
    
    return lot;
}

//+------------------------------------------------------------------+
//| Calculate risk amount in account currency                        |
//+------------------------------------------------------------------+
double MoneyManager::CalculateRiskAmount(double lot, double slDistance) {
    if(m_pointValue <= 0) return 0;
    
    //--- Risk = lot size × SL distance (points) × point value
    double riskAmount = lot * slDistance * m_pointValue;
    
    return riskAmount;
}

//+------------------------------------------------------------------+
//| Check if sufficient margin available                             |
//+------------------------------------------------------------------+
bool MoneyManager::CheckMarginRequirement(double lot, ENUM_ORDER_TYPE orderType) {
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double requiredMargin = 0;
    
    //--- Calculate required margin
    if(!OrderCalcMargin(orderType, m_symbol, lot, 
                        SymbolInfoDouble(m_symbol, SYMBOL_ASK),
                        requiredMargin)) {
        Print("ERROR: Failed to calculate margin requirement");
        return false;
    }
    
    //--- Check if sufficient margin available (with 20% buffer)
    if(requiredMargin * 1.2 > freeMargin) {
        Print("WARNING: Insufficient margin - Required: ", requiredMargin,
              " Free: ", freeMargin);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| END OF MONEY MANAGER                                             |
//+------------------------------------------------------------------+
