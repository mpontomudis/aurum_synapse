//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Trade Manager - Order Execution with Retry Logic"

#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"
#include "../Core/TradeDiag.mqh"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Trade Manager Class                                              |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Execute trades using CTrade class                            |
//|   - Implement retry logic (3 attempts with delays)               |
//|   - Check margin requirements before opening                     |
//|   - Control slippage (<2 pips)                                   |
//|   - Log all errors and execution details                         |
//|   - Modify positions (SL/TP adjustments)                         |
//|   - Close positions (individual and batch)                       |
//|   - Manage trailing stops                                        |
//|                                                                  |
//| Error Handling:                                                  |
//|   - Retry on temporary errors (requote, timeout, busy)           |
//|   - Fail immediately on permanent errors (invalid parameters)    |
//|   - Log all attempts with detailed error information             |
//+------------------------------------------------------------------+
class TradeManager {
private:
    //--- Trade object
    CTrade           m_trade;
    
    //--- Configuration
    string           m_symbol;
    int              m_magicNumber;
    int              m_maxRetries;
    int              m_retryDelayMs;
    int              m_maxSlippagePoints;
    int              m_deviation;
    
    //--- Statistics
    int              m_ordersOpened;
    int              m_ordersClosed;
    int              m_ordersFailed;
    int              m_ordersModified;
    
    //--- Helper methods
    bool             RetryOrder(ENUM_ORDER_TYPE orderType, double lot, double price,
                                double sl, double tp, string comment, int attempt);
    void             HandleOrderError(uint retcode, int attempt);
    bool             IsRetryableError(uint retcode);
    string           ErrorCodeToString(uint retcode);
    
public:
    //--- Constructor / Destructor
    TradeManager();
    ~TradeManager();
    
    //--- Initialization
    bool             Init(string symbol, int magicNumber);
    
    //--- Order execution
    ulong            OpenBuy(double lot, double sl, double tp, int qualityScore, string comment = "", double requestedLotForDiag = -1.0);
    ulong            OpenSell(double lot, double sl, double tp, int qualityScore, string comment = "", double requestedLotForDiag = -1.0);
    bool             ClosePosition(ulong ticket);
    bool             CloseAllPositions();
    
    //--- Position modification
    bool             ModifyPosition(ulong ticket, double newSL, double newTP);
    bool             SetBreakeven(ulong ticket, double lockPips = 0);
    
    //--- Position management
    bool             ManagePositions(bool useTrailing, double startPips, double distPips);
    int              CountOpenPositions();
    bool             HasOpenPosition(ulong ticket);
    
    //--- Accessors
    int              GetOrdersOpened() { return m_ordersOpened; }
    int              GetOrdersClosed() { return m_ordersClosed; }
    int              GetOrdersFailed() { return m_ordersFailed; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
TradeManager::TradeManager(void) :
    m_maxRetries(ORDER_RETRY_MAX_ATTEMPTS),
    m_retryDelayMs(ORDER_RETRY_DELAY_MS),
    m_maxSlippagePoints(MAX_SLIPPAGE_POINTS),
    m_deviation(MAX_SLIPPAGE_POINTS),
    m_ordersOpened(0),
    m_ordersClosed(0),
    m_ordersFailed(0),
    m_ordersModified(0)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
TradeManager::~TradeManager(void) {
}

//+------------------------------------------------------------------+
//| Initialize trade manager                                         |
//+------------------------------------------------------------------+
bool TradeManager::Init(string symbol, int magicNumber) {
    m_symbol = symbol;
    m_magicNumber = magicNumber;
    
    Print("TradeManager - Initializing for ", symbol);
    
    //--- Configure CTrade object
    m_trade.SetExpertMagicNumber(magicNumber);
    m_trade.SetDeviationInPoints(m_deviation);
    m_trade.SetTypeFilling(ORDER_FILLING_FOK);  // Fill or Kill
    m_trade.SetAsyncMode(false);  // Synchronous execution
    
    //--- Validate symbol
    if(!SymbolSelect(symbol, true)) {
        Print("ERROR: Failed to select symbol ", symbol);
        TradeDiag_Blocked("SymbolSelectFailed", symbol, 0.0, -1);
        return false;
    }
    
    Print("TradeManager initialized - Magic: ", magicNumber, 
          " | Max Retries: ", m_maxRetries,
          " | Max Slippage: ", m_maxSlippagePoints, " points");
    
    return true;
}

//+------------------------------------------------------------------+
//| Open BUY position with retry logic                               |
//+------------------------------------------------------------------+
ulong TradeManager::OpenBuy(double lot, double sl, double tp, int qualityScore, string comment, double requestedLotForDiag) {
    double price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    int    openPos = CountOpenPositions();
    uint   lastRetcode = 0;
    
    //--- Check margin
    double requiredMargin = 0;
    if(!OrderCalcMargin(ORDER_TYPE_BUY, m_symbol, lot, price, requiredMargin)) {
        Print("ERROR: Failed to calculate margin for BUY order");
        TradeDiag_Blocked("OrderCalcMarginFailed", m_symbol, lot, openPos);
        m_ordersFailed++;
        return 0;
    }
    
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    if(requiredMargin * 1.2 > freeMargin) {
        Print("ERROR: Insufficient margin - Required: ", requiredMargin, " Free: ", freeMargin);
        TradeDiag_Blocked("FreeMarginTooLow", m_symbol, lot, openPos);
        m_ordersFailed++;
        return 0;
    }
    
    //--- Prepare comment
    if(comment == "") {
        comment = StringFormat("BUY Q:%d", qualityScore);
    }
    
    if(requestedLotForDiag >= 0.0)
        Print("[LOT_EXEC] RequestedLot=", DoubleToString(requestedLotForDiag, 4),
              " FinalLot=", DoubleToString(lot, 4),
              " FreeMargin=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2),
              " SYM_VOL_MAX=", DoubleToString(SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX), 4),
              " SYM_VOL_STEP=", DoubleToString(SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP), 4),
              " (pre CTrade::Buy)");
    else
        Print("[LOT_EXEC] FinalLot=", DoubleToString(lot, 4),
              " FreeMargin=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2),
              " SYM_VOL_MAX=", DoubleToString(SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX), 4),
              " (pre CTrade::Buy)");
    
    //--- Execute with retry logic
    for(int attempt = 1; attempt <= m_maxRetries; attempt++) {
        if(m_trade.Buy(lot, m_symbol, price, sl, tp, comment)) {
            ulong ticket = m_trade.ResultOrder();
            m_ordersOpened++;
            
            Print("✅ BUY order opened - Ticket: ", ticket,
                  " | Lot: ", lot,
                  " | Price: ", price,
                  " | SL: ", sl,
                  " | TP: ", tp,
                  " | Quality: ", qualityScore);
            
            return ticket;
        }
        
        //--- Handle error
        lastRetcode = m_trade.ResultRetcode();
        HandleOrderError(lastRetcode, attempt);
        
        //--- Check if retryable
        if(!IsRetryableError(lastRetcode) || attempt >= m_maxRetries) {
            m_ordersFailed++;
            TradeDiag_Blocked(TradeDiag_RetcodeToReason(lastRetcode), m_symbol, lot, openPos);
            return 0;
        }
        
        //--- Wait before retry (skip in strategy tester to avoid database errors)
        if(!MQLInfoInteger(MQL_TESTER)) {
            Sleep(m_retryDelayMs);
        }
    }
    
    m_ordersFailed++;
    TradeDiag_Blocked(TradeDiag_RetcodeToReason(lastRetcode), m_symbol, lot, openPos);
    return 0;
}

//+------------------------------------------------------------------+
//| Open SELL position with retry logic                              |
//+------------------------------------------------------------------+
ulong TradeManager::OpenSell(double lot, double sl, double tp, int qualityScore, string comment, double requestedLotForDiag) {
    double price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    int    openPos = CountOpenPositions();
    uint   lastRetcode = 0;
    
    //--- Check margin
    double requiredMargin = 0;
    if(!OrderCalcMargin(ORDER_TYPE_SELL, m_symbol, lot, price, requiredMargin)) {
        Print("ERROR: Failed to calculate margin for SELL order");
        TradeDiag_Blocked("OrderCalcMarginFailed", m_symbol, lot, openPos);
        m_ordersFailed++;
        return 0;
    }
    
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    if(requiredMargin * 1.2 > freeMargin) {
        Print("ERROR: Insufficient margin - Required: ", requiredMargin, " Free: ", freeMargin);
        TradeDiag_Blocked("FreeMarginTooLow", m_symbol, lot, openPos);
        m_ordersFailed++;
        return 0;
    }
    
    //--- Prepare comment
    if(comment == "") {
        comment = StringFormat("SELL Q:%d", qualityScore);
    }
    
    if(requestedLotForDiag >= 0.0)
        Print("[LOT_EXEC] RequestedLot=", DoubleToString(requestedLotForDiag, 4),
              " FinalLot=", DoubleToString(lot, 4),
              " FreeMargin=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2),
              " SYM_VOL_MAX=", DoubleToString(SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX), 4),
              " SYM_VOL_STEP=", DoubleToString(SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP), 4),
              " (pre CTrade::Sell)");
    else
        Print("[LOT_EXEC] FinalLot=", DoubleToString(lot, 4),
              " FreeMargin=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2),
              " SYM_VOL_MAX=", DoubleToString(SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX), 4),
              " (pre CTrade::Sell)");
    
    Print("[TradeManager::OpenSell] About to call CTrade::Sell()");
    Print("  lot: ", lot);
    Print("  symbol: ", m_symbol);
    Print("  price: ", price);
    Print("  sl: ", sl);
    Print("  tp: ", tp);
    Print("  comment: ", comment);
    
    //--- Execute with retry logic
    for(int attempt = 1; attempt <= m_maxRetries; attempt++) {
        if(m_trade.Sell(lot, m_symbol, price, sl, tp, comment)) {
            ulong ticket = m_trade.ResultOrder();
            m_ordersOpened++;
            
            Print("✅ SELL order opened - Ticket: ", ticket,
                  " | Lot: ", lot,
                  " | Price: ", price,
                  " | SL: ", sl,
                  " | TP: ", tp,
                  " | Quality: ", qualityScore);
            
            return ticket;
        }
        
        //--- Handle error
        lastRetcode = m_trade.ResultRetcode();
        HandleOrderError(lastRetcode, attempt);
        
        //--- Check if retryable
        if(!IsRetryableError(lastRetcode) || attempt >= m_maxRetries) {
            m_ordersFailed++;
            TradeDiag_Blocked(TradeDiag_RetcodeToReason(lastRetcode), m_symbol, lot, openPos);
            return 0;
        }
        
        //--- Wait before retry (skip in strategy tester to avoid database errors)
        if(!MQLInfoInteger(MQL_TESTER)) {
            Sleep(m_retryDelayMs);
        }
    }
    
    m_ordersFailed++;
    TradeDiag_Blocked(TradeDiag_RetcodeToReason(lastRetcode), m_symbol, lot, openPos);
    return 0;
}

//+------------------------------------------------------------------+
//| Close position by ticket                                         |
//+------------------------------------------------------------------+
bool TradeManager::ClosePosition(ulong ticket) {
    if(!PositionSelectByTicket(ticket)) {
        Print("ERROR: Position ", ticket, " not found");
        return false;
    }
    
    //--- Execute with retry logic
    for(int attempt = 1; attempt <= m_maxRetries; attempt++) {
        if(m_trade.PositionClose(ticket, m_deviation)) {
            m_ordersClosed++;
            Print("✅ Position closed - Ticket: ", ticket);
            return true;
        }
        
        //--- Handle error
        uint retcode = m_trade.ResultRetcode();
        HandleOrderError(retcode, attempt);
        
        //--- Check if retryable
        if(!IsRetryableError(retcode) || attempt >= m_maxRetries) {
            return false;
        }
        
        //--- Wait before retry (skip in strategy tester to avoid database errors)
        if(!MQLInfoInteger(MQL_TESTER)) {
            Sleep(m_retryDelayMs);
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
bool TradeManager::CloseAllPositions(void) {
    int total = PositionsTotal();
    int closed = 0;
    
    Print("Closing all positions - Total: ", total);
    
    //--- Loop through all positions
    for(int i = total - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        
        //--- Check if position belongs to this EA
        if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber) continue;
        if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
        
        //--- Close position
        if(ClosePosition(ticket)) {
            closed++;
        }
    }
    
    Print("Closed ", closed, " / ", total, " positions");
    
    return (closed == total);
}

//+------------------------------------------------------------------+
//| Modify position SL/TP                                            |
//+------------------------------------------------------------------+
bool TradeManager::ModifyPosition(ulong ticket, double newSL, double newTP) {
    if(!PositionSelectByTicket(ticket)) {
        Print("ERROR: Position ", ticket, " not found");
        return false;
    }
    
    //--- Execute with retry logic
    for(int attempt = 1; attempt <= m_maxRetries; attempt++) {
        if(m_trade.PositionModify(ticket, newSL, newTP)) {
            m_ordersModified++;
            Print("✅ Position modified - Ticket: ", ticket,
                  " | New SL: ", newSL,
                  " | New TP: ", newTP);
            return true;
        }
        
        //--- Handle error
        uint retcode = m_trade.ResultRetcode();
        HandleOrderError(retcode, attempt);
        
        //--- Check if retryable
        if(!IsRetryableError(retcode) || attempt >= m_maxRetries) {
            return false;
        }
        
        //--- Wait before retry (skip in strategy tester to avoid database errors)
        if(!MQLInfoInteger(MQL_TESTER)) {
            Sleep(m_retryDelayMs);
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Set position to breakeven                                        |
//+------------------------------------------------------------------+
bool TradeManager::SetBreakeven(ulong ticket, double lockPips = 0) {
    if(!PositionSelectByTicket(ticket)) return false;
    
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    //--- Calculate breakeven level
    double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    double newSL = openPrice;
    
    if(lockPips > 0) {
        if(type == POSITION_TYPE_BUY) {
            newSL = openPrice + (lockPips * 10 * point);  // Convert pips to points
        } else {
            newSL = openPrice - (lockPips * 10 * point);
        }
    }
    
    //--- Check if already at or better than breakeven
    if(type == POSITION_TYPE_BUY && currentSL >= newSL) return true;
    if(type == POSITION_TYPE_SELL && currentSL <= newSL && currentSL > 0) return true;
    
    //--- Modify position
    double currentTP = PositionGetDouble(POSITION_TP);
    return ModifyPosition(ticket, newSL, currentTP);
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stops)                           |
//+------------------------------------------------------------------+
bool TradeManager::ManagePositions(bool useTrailing, double startPips, double distPips) {
    if(!useTrailing) return true;
    
    double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    int managed = 0;
    
    //--- Loop through all positions
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        
        //--- Check if position belongs to this EA
        if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber) continue;
        if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
        
        //--- Get position info
        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentPrice = (type == POSITION_TYPE_BUY) ? 
                              SymbolInfoDouble(m_symbol, SYMBOL_BID) :
                              SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        
        //--- Calculate profit in pips
        double profitPoints = (type == POSITION_TYPE_BUY) ?
                              (currentPrice - openPrice) :
                              (openPrice - currentPrice);
        double profitPips = profitPoints / (point * 10);
        
        //--- Check if trailing should start
        if(profitPips < startPips) continue;
        
        //--- Calculate new SL
        double newSL = 0;
        if(type == POSITION_TYPE_BUY) {
            newSL = currentPrice - (distPips * 10 * point);
            if(newSL <= currentSL) continue;  // Don't move SL backwards
        } else {
            newSL = currentPrice + (distPips * 10 * point);
            if(newSL >= currentSL && currentSL > 0) continue;  // Don't move SL backwards
        }
        
        //--- Modify position
        if(ModifyPosition(ticket, newSL, currentTP)) {
            managed++;
        }
    }
    
    if(managed > 0) {
        Print("Trailing stops updated - Positions: ", managed);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Count open positions for this EA                                 |
//+------------------------------------------------------------------+
int TradeManager::CountOpenPositions(void) {
    int count = 0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        
        if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber &&
           PositionGetString(POSITION_SYMBOL) == m_symbol) {
            count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Check if position exists                                         |
//+------------------------------------------------------------------+
bool TradeManager::HasOpenPosition(ulong ticket) {
    return PositionSelectByTicket(ticket);
}

//+------------------------------------------------------------------+
//| Handle order error                                               |
//+------------------------------------------------------------------+
void TradeManager::HandleOrderError(uint retcode, int attempt) {
    string errorMsg = ErrorCodeToString(retcode);
    
    Print("⚠️ Order error (attempt ", attempt, "/", m_maxRetries, "): ",
          errorMsg, " (", retcode, ")");
}

//+------------------------------------------------------------------+
//| Check if error is retryable                                      |
//+------------------------------------------------------------------+
bool TradeManager::IsRetryableError(uint retcode) {
    switch(retcode) {
        case TRADE_RETCODE_REQUOTE:
        case TRADE_RETCODE_CONNECTION:
        case TRADE_RETCODE_PRICE_CHANGED:
        case TRADE_RETCODE_TIMEOUT:
        case TRADE_RETCODE_PRICE_OFF:
        case TRADE_RETCODE_REJECT:
        case TRADE_RETCODE_ERROR:
            return true;
            
        default:
            return false;
    }
}

//+------------------------------------------------------------------+
//| Convert error code to string                                     |
//+------------------------------------------------------------------+
string TradeManager::ErrorCodeToString(uint retcode) {
    switch(retcode) {
        case TRADE_RETCODE_DONE: return "Request completed";
        case TRADE_RETCODE_REQUOTE: return "Requote";
        case TRADE_RETCODE_REJECT: return "Request rejected";
        case TRADE_RETCODE_CANCEL: return "Request canceled";
        case TRADE_RETCODE_PLACED: return "Order placed";
        case TRADE_RETCODE_DONE_PARTIAL: return "Partial fill";
        case TRADE_RETCODE_ERROR: return "Request error";
        case TRADE_RETCODE_TIMEOUT: return "Timeout";
        case TRADE_RETCODE_INVALID: return "Invalid request";
        case TRADE_RETCODE_INVALID_VOLUME: return "Invalid volume";
        case TRADE_RETCODE_INVALID_PRICE: return "Invalid price";
        case TRADE_RETCODE_INVALID_STOPS: return "Invalid stops";
        case TRADE_RETCODE_TRADE_DISABLED: return "Trade disabled";
        case TRADE_RETCODE_MARKET_CLOSED: return "Market closed";
        case TRADE_RETCODE_NO_MONEY: return "Insufficient funds";
        case TRADE_RETCODE_PRICE_CHANGED: return "Price changed";
        case TRADE_RETCODE_PRICE_OFF: return "No prices";
        case TRADE_RETCODE_INVALID_EXPIRATION: return "Invalid expiration";
        case TRADE_RETCODE_ORDER_CHANGED: return "Order changed";
        case TRADE_RETCODE_TOO_MANY_REQUESTS: return "Too many requests";
        case TRADE_RETCODE_NO_CHANGES: return "No changes";
        case TRADE_RETCODE_SERVER_DISABLES_AT: return "Autotrading disabled";
        case TRADE_RETCODE_CLIENT_DISABLES_AT: return "Autotrading disabled by client";
        case TRADE_RETCODE_LOCKED: return "Locked";
        case TRADE_RETCODE_FROZEN: return "Frozen";
        case TRADE_RETCODE_INVALID_FILL: return "Invalid fill type";
        case TRADE_RETCODE_CONNECTION: return "No connection";
        case TRADE_RETCODE_ONLY_REAL: return "Only real accounts";
        case TRADE_RETCODE_LIMIT_ORDERS: return "Orders limit reached";
        case TRADE_RETCODE_LIMIT_VOLUME: return "Volume limit reached";
        default: return "Unknown error";
    }
}

//+------------------------------------------------------------------+
//| END OF TRADE MANAGER                                             |
//+------------------------------------------------------------------+
