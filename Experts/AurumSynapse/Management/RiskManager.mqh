//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Risk Manager - Circuit Breakers & Risk Tracking"

#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"
#include "../Core/TradeDiag.mqh"

//+------------------------------------------------------------------+
//| Risk Manager Class                                               |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Track daily P/L and enforce daily loss limits (5%)           |
//|   - Monitor equity drawdown and protect against DD >12%          |
//|   - Count consecutive wins/losses and pause after 3 losses       |
//|   - Implement circuit breakers for emergency situations          |
//|   - Reset counters daily and update peak equity                  |
//|                                                                  |
//| Risk Limits (from specs):                                        |
//|   - Daily loss: 5% of equity or $50 (whichever is lower)         |
//|   - Equity DD: 12% from peak equity                              |
//|   - Consecutive losses: Pause after 3 losses (30 min cooldown)   |
//|   - Position limits: Max 5 concurrent, max 0.1 lot per position  |
//+------------------------------------------------------------------+
class RiskManager {
private:
    //--- Daily tracking
    datetime         m_lastResetDate;
    double           m_dailyPnL;
    double           m_startingEquity;
    int              m_tradesToday;
    
    //--- Equity tracking
    double           m_peakEquity;
    double           m_currentEquity;
    double           m_equityDD;
    
    //--- Consecutive tracking
    int              m_consecutiveWins;
    int              m_consecutiveLosses;
    
    //--- Circuit breaker
    bool             m_isHalted;
    datetime         m_haltUntil;
    ENUM_HALT_REASON m_haltReason;
    string           m_haltMessage;
    
    //--- Configuration
    double           m_maxDailyLossPercent;
    double           m_maxDailyLossDollars;
    double           m_maxEquityDDPercent;
    int              m_maxConsecutiveLosses;
    
    //--- Helper methods
    void             CheckDailyReset();
    void             UpdatePeakEquity();
    
public:
    //--- Constructor / Destructor
    RiskManager();
    ~RiskManager();
    
    //--- Initialization
    bool             Init();
    //--- Sync EA Inputs with internal limits (defaults come from Constants.mqh until this runs)
    void             SetRiskLimitsFromInputs(double maxEquityDDPct, int maxConsecutiveLosses, double maxDailyLossPct);
    
    //--- Main risk checks
    bool             IsDailyLossExceeded(double maxPct);
    bool             IsEquityDDExceeded(double maxPct);
    bool             IsMaxConsecutiveLossesReached();
    bool             CanTrade();
    
    //--- Trade event handlers
    void             OnTradeClosed(bool wasProfit, double amount);
    void             OnTradeOpened(double lotSize);
    
    //--- Circuit breaker management
    void             ActivateCircuitBreaker(ENUM_HALT_REASON reason, string message, int durationMinutes);
    void             ResetCircuitBreaker();
    bool             IsHalted() { return m_isHalted; }
    string           GetHaltReason();
    
    //--- Accessors
    int              GetConsecutiveLosses() { return m_consecutiveLosses; }
    int              GetConsecutiveWins() { return m_consecutiveWins; }
    double           GetDailyPnL() { return m_dailyPnL; }
    double           GetEquityDD() { return m_equityDD; }
    double           GetPeakEquity() { return m_peakEquity; }
    
    //--- Daily reset
    void             ResetDaily();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
RiskManager::RiskManager(void) :
    m_lastResetDate(0),
    m_dailyPnL(0),
    m_startingEquity(0),
    m_tradesToday(0),
    m_peakEquity(0),
    m_currentEquity(0),
    m_equityDD(0),
    m_consecutiveWins(0),
    m_consecutiveLosses(0),
    m_isHalted(false),
    m_haltUntil(0),
    m_haltReason(HALT_NONE),
    m_maxDailyLossPercent(MAX_DAILY_LOSS_PERCENT),
    m_maxDailyLossDollars(MAX_DAILY_LOSS_DOLLARS),
    m_maxEquityDDPercent(MAX_DRAWDOWN_PERCENT),
    m_maxConsecutiveLosses(MAX_CONSECUTIVE_LOSSES)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
RiskManager::~RiskManager(void) {
}

//+------------------------------------------------------------------+
//| Initialize risk manager                                          |
//+------------------------------------------------------------------+
bool RiskManager::Init(void) {
    Print("RiskManager - Initializing");
    
    //--- Initialize equity tracking
    m_currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    m_peakEquity = m_currentEquity;
    m_startingEquity = m_currentEquity;
    
    //--- Set last reset date to today
    MqlDateTime dt;
    TimeCurrent(dt);
    m_lastResetDate = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00", 
                                                  dt.year, dt.mon, dt.day));
    
    Print("RiskManager initialized - Starting Equity: $", m_startingEquity,
          " (risk limits: apply Inputs via SetRiskLimitsFromInputs)");
    
    return true;
}

//+------------------------------------------------------------------+
//| Apply Expert inputs (was ignored — CanTrade used Constants only) |
//+------------------------------------------------------------------+
void RiskManager::SetRiskLimitsFromInputs(double maxEquityDDPct, int maxConsecutiveLosses, double maxDailyLossPct) {
    if(maxEquityDDPct > 0.0 && maxEquityDDPct <= 100.0)
        m_maxEquityDDPercent = maxEquityDDPct;
    if(maxConsecutiveLosses > 0 && maxConsecutiveLosses <= 50)
        m_maxConsecutiveLosses = maxConsecutiveLosses;
    if(maxDailyLossPct > 0.0 && maxDailyLossPct <= 100.0)
        m_maxDailyLossPercent = maxDailyLossPct;
    Print("RiskManager - Inputs applied: MaxEqDD=", m_maxEquityDDPercent, "% | MaxConsecLosses=", m_maxConsecutiveLosses,
          " | MaxDailyLoss%=", m_maxDailyLossPercent, " | DailyLoss$cap=", m_maxDailyLossDollars);
}

//+------------------------------------------------------------------+
//| Check if daily loss limit exceeded                               |
//+------------------------------------------------------------------+
bool RiskManager::IsDailyLossExceeded(double maxPct) {
    CheckDailyReset();
    
    //--- Check percentage-based loss
    double lossPercent = (m_dailyPnL / m_startingEquity) * 100.0;
    bool percentExceeded = (lossPercent <= -maxPct);
    
    //--- Check absolute dollar loss
    bool dollarExceeded = (m_dailyPnL <= -m_maxDailyLossDollars);
    
    if(percentExceeded || dollarExceeded) {
        string reason = StringFormat("Daily loss limit exceeded: %.2f%% ($%.2f)",
                                      lossPercent, m_dailyPnL);
        ActivateCircuitBreaker(HALT_DAILY_LOSS, reason, CONSECUTIVE_LOSS_COOLDOWN);
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if equity drawdown exceeded                                |
//+------------------------------------------------------------------+
bool RiskManager::IsEquityDDExceeded(double maxPct) {
    UpdatePeakEquity();
    
    //--- Calculate current drawdown
    m_currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(m_peakEquity > 0) {
        m_equityDD = ((m_peakEquity - m_currentEquity) / m_peakEquity) * 100.0;
    }
    
    //--- Check if exceeded
    if(m_equityDD >= maxPct) {
        string reason = StringFormat("Equity DD limit exceeded: %.2f%% (peak $%.2f, current $%.2f)",
                                      m_equityDD, m_peakEquity, m_currentEquity);
        ActivateCircuitBreaker(HALT_DRAWDOWN, reason, 60);  // 1 hour cooldown
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if maximum consecutive losses reached                      |
//+------------------------------------------------------------------+
bool RiskManager::IsMaxConsecutiveLossesReached(void) {
    if(m_consecutiveLosses >= m_maxConsecutiveLosses) {
        string reason = StringFormat("Consecutive loss limit reached: %d losses in a row",
                                      m_consecutiveLosses);
        ActivateCircuitBreaker(HALT_CONSECUTIVE_LOSS, reason, CONSECUTIVE_LOSS_COOLDOWN);
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool RiskManager::CanTrade(void) {
    CheckDailyReset();
    
    //--- Check circuit breaker status
    if(m_isHalted) {
        if(TimeCurrent() < m_haltUntil) {
            TradeDiag_Blocked("CooldownActive", _Symbol, 0.0, -1);
            return false;  // Still in cooldown
        }
        //--- Cooldown expired, reset circuit breaker
        ResetCircuitBreaker();
    }
    
    //--- Check all risk limits
    if(IsDailyLossExceeded(m_maxDailyLossPercent)) {
        TradeDiag_Blocked("DailyLossLimit", _Symbol, 0.0, -1);
        return false;
    }
    if(IsEquityDDExceeded(m_maxEquityDDPercent)) {
        TradeDiag_Blocked("MaxDrawdown", _Symbol, 0.0, -1);
        return false;
    }
    if(IsMaxConsecutiveLossesReached()) {
        TradeDiag_Blocked("MaxConsecutiveLosses", _Symbol, 0.0, -1);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Handle trade closed event                                        |
//+------------------------------------------------------------------+
void RiskManager::OnTradeClosed(bool wasProfit, double amount) {
    CheckDailyReset();
    
    //--- Update daily P/L
    m_dailyPnL += amount;
    m_tradesToday++;
    
    //--- Update consecutive counters
    if(wasProfit) {
        m_consecutiveWins++;
        m_consecutiveLosses = 0;  // Reset loss counter
    } else {
        m_consecutiveLosses++;
        m_consecutiveWins = 0;  // Reset win counter
    }
    
    //--- Update equity
    UpdatePeakEquity();
    
    //--- Log trade result
    Print("Trade closed - P/L: $", DoubleToString(amount, 2),
          " | Daily P/L: $", DoubleToString(m_dailyPnL, 2),
          " | Consecutive: ", wasProfit ? "+" : "-", 
          wasProfit ? m_consecutiveWins : m_consecutiveLosses);
}

//+------------------------------------------------------------------+
//| Handle trade opened event                                        |
//+------------------------------------------------------------------+
void RiskManager::OnTradeOpened(double lotSize) {
    CheckDailyReset();
    m_tradesToday++;
    
    Print("Trade opened - Lot: ", lotSize, " | Trades today: ", m_tradesToday);
}

//+------------------------------------------------------------------+
//| Activate circuit breaker                                         |
//+------------------------------------------------------------------+
void RiskManager::ActivateCircuitBreaker(ENUM_HALT_REASON reason, string message, int durationMinutes) {
    m_isHalted = true;
    m_haltReason = reason;
    m_haltMessage = message;
    m_haltUntil = TimeCurrent() + (durationMinutes * 60);
    
    Print("========================================");
    Print("🛑 CIRCUIT BREAKER ACTIVATED!");
    Print("Reason: ", message);
    Print("Cooldown: ", durationMinutes, " minutes");
    Print("Resume at: ", TimeToString(m_haltUntil, TIME_DATE|TIME_MINUTES));
    Print("========================================");
}

//+------------------------------------------------------------------+
//| Reset circuit breaker                                            |
//+------------------------------------------------------------------+
void RiskManager::ResetCircuitBreaker(void) {
    if(m_isHalted) {
        Print("✅ Circuit breaker reset - Trading resumed");
        m_isHalted = false;
        m_haltReason = HALT_NONE;
        m_haltMessage = "";
        m_haltUntil = 0;
    }
}

//+------------------------------------------------------------------+
//| Get halt reason string                                           |
//+------------------------------------------------------------------+
string RiskManager::GetHaltReason(void) {
    if(!m_isHalted) return "Not halted";
    
    return m_haltMessage;
}

//+------------------------------------------------------------------+
//| Check if daily reset needed                                      |
//+------------------------------------------------------------------+
void RiskManager::CheckDailyReset(void) {
    MqlDateTime dt;
    TimeCurrent(dt);
    datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00", 
                                                 dt.year, dt.mon, dt.day));
    
    //--- Check if new day
    if(today > m_lastResetDate) {
        ResetDaily();
    }
}

//+------------------------------------------------------------------+
//| Reset daily counters                                             |
//+------------------------------------------------------------------+
void RiskManager::ResetDaily(void) {
    MqlDateTime dt;
    TimeCurrent(dt);
    
    Print("========================================");
    Print("📅 DAILY RESET - ", TimeToString(TimeCurrent(), TIME_DATE));
    Print("Previous day P/L: $", DoubleToString(m_dailyPnL, 2));
    Print("Trades: ", m_tradesToday);
    Print("========================================");
    
    //--- Reset daily counters
    m_dailyPnL = 0;
    m_tradesToday = 0;
    m_startingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    m_lastResetDate = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00", 
                                                  dt.year, dt.mon, dt.day));
    
    //--- Reset consecutive counters (new day, fresh start)
    m_consecutiveWins = 0;
    m_consecutiveLosses = 0;
    
    //--- Reset circuit breaker if active
    if(m_haltReason == HALT_DAILY_LOSS || m_haltReason == HALT_CONSECUTIVE_LOSS) {
        ResetCircuitBreaker();
    }
}

//+------------------------------------------------------------------+
//| Update peak equity                                               |
//+------------------------------------------------------------------+
void RiskManager::UpdatePeakEquity(void) {
    m_currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(m_currentEquity > m_peakEquity) {
        m_peakEquity = m_currentEquity;
        m_equityDD = 0;  // Reset DD when new peak reached
    }
}

//+------------------------------------------------------------------+
//| END OF RISK MANAGER                                              |
//+------------------------------------------------------------------+
