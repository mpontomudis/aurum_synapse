//+------------------------------------------------------------------+
//|                                                    TradeDiag.mqh |
//| Structured [TRADE_BLOCKED] / [TRADE_ALLOWED] Journal helpers     |
//| Logging only — no trading logic                                   |
//+------------------------------------------------------------------+
#ifndef __TRADEDIAG_MQH__
#define __TRADEDIAG_MQH__

//+------------------------------------------------------------------+
//| Map CTrade retcode → short Reason= label (TradeDiag_Blocked)      |
//+------------------------------------------------------------------+
string TradeDiag_RetcodeToReason(const uint retcode) {
    switch((int)retcode) {
        case TRADE_RETCODE_NO_MONEY:          return "FreeMarginTooLow";
        case TRADE_RETCODE_LOCKED:            return "TradeContextBusy";
        case TRADE_RETCODE_TRADE_DISABLED:   return "TradeDisabled";
        case TRADE_RETCODE_MARKET_CLOSED:     return "MarketClosed";
        case TRADE_RETCODE_INVALID_VOLUME:    return "InvalidVolume";
        case TRADE_RETCODE_INVALID_STOPS:     return "InvalidStops";
        case TRADE_RETCODE_CONNECTION:        return "ConnectionError";
        case TRADE_RETCODE_TOO_MANY_REQUESTS: return "TooManyRequests";
        case TRADE_RETCODE_SERVER_DISABLES_AT: return "TradeDisabledServer";
        case TRADE_RETCODE_CLIENT_DISABLES_AT: return "TradeDisabledClient";
        case TRADE_RETCODE_NO_CHANGES:        return "NoChanges";
        default:                              return "OrderSendFailed";
    }
}

//+------------------------------------------------------------------+
//| [TRADE_BLOCKED] — one block per rejection (multi-line Print)      |
//+------------------------------------------------------------------+
void TradeDiag_Blocked(const string reason,
                       const string symbol,
                       const double requestedLot,
                       const int currentOpenPositions) {
    string sym = symbol;
    if(StringLen(sym) == 0)
        sym = "-";
    string opStr = (currentOpenPositions < 0) ? "N/A" : IntegerToString(currentOpenPositions);
    
    Print("[TRADE_BLOCKED]");
    Print("Reason=", reason);
    Print("Balance=", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
    Print("Equity=", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
    Print("FreeMargin=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2));
    Print("MarginLevel=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2));
    Print("RequestedLot=", DoubleToString(requestedLot, 4));
    Print("CurrentOpenPositions=", opStr);
    Print("Symbol=", sym);
    Print("Timestamp=", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
}

//+------------------------------------------------------------------+
//| [TRADE_ALLOWED] — immediately before sending order to server      |
//+------------------------------------------------------------------+
void TradeDiag_Allowed(const string symbol,
                       const double lot,
                       const double marginRequired,
                       const int openPositions) {
    string sym = symbol;
    if(StringLen(sym) == 0)
        sym = "-";
    
    Print("[TRADE_ALLOWED]");
    Print("Lot=", DoubleToString(lot, 4));
    Print("Balance=", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
    Print("FreeMargin=", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2));
    Print("MarginRequired=", DoubleToString(marginRequired, 2));
    Print("OpenPositions=", IntegerToString(openPositions));
    Print("Symbol=", sym);
    Print("Timestamp=", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
}

#endif // __TRADEDIAG_MQH__
