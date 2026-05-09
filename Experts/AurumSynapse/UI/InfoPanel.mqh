//+------------------------------------------------------------------+
//|                                                    InfoPanel.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Info Panel - On-Chart Dashboard Display"

#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"

//+------------------------------------------------------------------+
//| Info Panel Class - Clean UI Design                              |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Display EA status in clean, organized 2-column layout        |
//|   - Show critical settings and strategy states                   |
//|   - Compact market state and consensus info                      |
//|   - Update max every 1 second to save resources                  |
//|   - Inspired by Quantum Queen design with Aurum theme            |
//|                                                                  |
//| Display Uses Comment() Function:                                 |
//|   - Single function call for entire panel                        |
//|   - Efficient (no graphical objects to manage)                   |
//|   - Clean 2-column layout with proper spacing                    |
//+------------------------------------------------------------------+
class InfoPanel {
private:
    //--- Update control
    datetime         m_lastUpdate;
    int              m_updateIntervalSeconds;
    
    //--- Display cache
    string           m_lastDisplay;
    bool             m_isVisible;
    
    //--- EA Settings (cached for display)
    ENUM_LOT_METHOD  m_lotMethod;
    double           m_fixedLot;
    double           m_riskPercent;
    int              m_magicNumber;
    int              m_minQualityScore;
    int              m_maxPositions;
    
    //--- Formatting helpers
    string           FormatHeader();
    string           FormatMainPanel(const MarketState &state, bool &strategyActive[], int strategyCount,
                                    ENUM_SIGNAL consensus, double consensusStrength, int qualityScore);
    string           FormatSettingsColumn();
    string           FormatStrategiesColumn(bool &active[], int count);
    string           FormatMarketInfo(const MarketState &state, ENUM_SIGNAL consensus, double strength, int quality);
    string           FormatAccountInfo(double dailyPnL, double equityDD, int consecutiveLosses);
    string           FormatFooter();
    
    //--- Helper functions
    string           PadRight(string text, int width);
    string           GetSignalIcon(ENUM_SIGNAL signal);
    string           GetRegimeIcon(ENUM_REGIME regime);
    
public:
    //--- Constructor / Destructor
    InfoPanel();
    ~InfoPanel();
    
    //--- Initialization
    bool             Init(int updateIntervalSeconds = 1);
    void             Deinit();
    
    //--- Configuration (call once after Init)
    void             SetConfig(ENUM_LOT_METHOD lotMethod, double fixedLot, double riskPercent,
                              int magicNumber, int minQuality, int maxPositions);
    
    //--- Main update method
    void             Update(const MarketState &state,
                           bool &strategyActive[],
                           int strategyCount,
                           ENUM_SIGNAL consensus,
                           double consensusStrength,
                           double agreementPct,
                           int qualityScore,
                           double dailyPnL,
                           double equityDD,
                           int consecutiveLosses);
    
    //--- Display control
    void             Show();
    void             Hide();
    void             Clear();
    bool             ShouldUpdate();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
InfoPanel::InfoPanel(void) :
    m_lastUpdate(0),
    m_updateIntervalSeconds(1),
    m_isVisible(true),
    m_lastDisplay(""),
    m_lotMethod(LOT_FIXED),
    m_fixedLot(0.01),
    m_riskPercent(1.0),
    m_magicNumber(0),
    m_minQualityScore(50),
    m_maxPositions(5)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
InfoPanel::~InfoPanel(void) {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize info panel                                            |
//+------------------------------------------------------------------+
bool InfoPanel::Init(int updateIntervalSeconds = 1) {
    m_updateIntervalSeconds = updateIntervalSeconds;
    m_lastUpdate = 0;
    m_isVisible = true;
    
    Print("InfoPanel initialized - Update interval: ", m_updateIntervalSeconds, "s");
    
    return true;
}

//+------------------------------------------------------------------+
//| Set EA configuration for display                                 |
//+------------------------------------------------------------------+
void InfoPanel::SetConfig(ENUM_LOT_METHOD lotMethod, double fixedLot, double riskPercent,
                          int magicNumber, int minQuality, int maxPositions) {
    m_lotMethod = lotMethod;
    m_fixedLot = fixedLot;
    m_riskPercent = riskPercent;
    m_magicNumber = magicNumber;
    m_minQualityScore = minQuality;
    m_maxPositions = maxPositions;
}

//+------------------------------------------------------------------+
//| Cleanup info panel                                               |
//+------------------------------------------------------------------+
void InfoPanel::Deinit(void) {
    Clear();
}

//+------------------------------------------------------------------+
//| Check if update is needed (throttle to save resources)           |
//+------------------------------------------------------------------+
bool InfoPanel::ShouldUpdate(void) {
    datetime currentTime = TimeCurrent();
    
    if(currentTime - m_lastUpdate >= m_updateIntervalSeconds) {
        m_lastUpdate = currentTime;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Main update method - builds and displays complete panel          |
//+------------------------------------------------------------------+
void InfoPanel::Update(const MarketState &state,
                       bool &strategyActive[],
                       int strategyCount,
                       ENUM_SIGNAL consensus,
                       double consensusStrength,
                       double agreementPct,
                       int qualityScore,
                       double dailyPnL,
                       double equityDD,
                       int consecutiveLosses) {
    //--- Throttle updates
    if(!ShouldUpdate()) return;
    if(!m_isVisible) return;
    
    //--- Build clean display string
    string display = "";
    
    //--- Header (compact)
    display += FormatHeader();
    display += "\n\n";
    
    //--- Main panel: 2-column layout (Settings | Strategies)
    display += FormatMainPanel(state, strategyActive, strategyCount, consensus, consensusStrength, qualityScore);
    display += "\n\n";
    
    //--- Market info (single line, compact)
    display += FormatMarketInfo(state, consensus, consensusStrength, qualityScore);
    display += "\n\n";
    
    //--- Account info (clean, organized)
    display += FormatAccountInfo(dailyPnL, equityDD, consecutiveLosses);
    display += "\n\n";
    
    //--- Footer (minimal)
    display += FormatFooter();
    
    //--- Display using Comment()
    Comment(display);
    m_lastDisplay = display;
}

//+------------------------------------------------------------------+
//| Format header section (compact)                                  |
//+------------------------------------------------------------------+
string InfoPanel::FormatHeader(void) {
    string header = "";
    header += "╔════════════════════════════════════════════════════════════╗\n";
    header += "║      ⚡ AURUM SYNAPSE v2.0 - Gold Trading Engine ⚡       ║\n";
    header += "╚════════════════════════════════════════════════════════════╝";
    return header;
}

//+------------------------------------------------------------------+
//| Format main panel with 2-column layout                           |
//+------------------------------------------------------------------+
string InfoPanel::FormatMainPanel(const MarketState &state, bool &strategyActive[], int strategyCount,
                                  ENUM_SIGNAL consensus, double consensusStrength, int qualityScore) {
    string panel = "";
    
    //--- Column headers
    panel += "┌─ CONFIGURATION ────────────────┬─ STRATEGIES STATUS ────────────┐\n";
    
    //--- Get settings and strategies columns
    string settings = FormatSettingsColumn();
    string strategies = FormatStrategiesColumn(strategyActive, strategyCount);
    
    //--- Split into lines and combine side-by-side
    string settingsLines[];
    string strategiesLines[];
    StringSplit(settings, '\n', settingsLines);
    StringSplit(strategies, '\n', strategiesLines);
    
    int maxLines = MathMax(ArraySize(settingsLines), ArraySize(strategiesLines));
    
    for(int i = 0; i < maxLines; i++) {
        string leftCol = (i < ArraySize(settingsLines)) ? settingsLines[i] : "";
        string rightCol = (i < ArraySize(strategiesLines)) ? strategiesLines[i] : "";
        
        panel += "│ " + PadRight(leftCol, 30) + " │ " + PadRight(rightCol, 30) + " │\n";
    }
    
    panel += "└────────────────────────────────┴────────────────────────────────┘";
    
    return panel;
}

//+------------------------------------------------------------------+
//| Format settings column (left side)                               |
//+------------------------------------------------------------------+
string InfoPanel::FormatSettingsColumn(void) {
    string settings = "";
    
    //--- Lot method
    string lotMethodStr = "";
    if(m_lotMethod == LOT_FIXED) lotMethodStr = "Fixed (" + DoubleToString(m_fixedLot, 2) + " lot)";
    else if(m_lotMethod == LOT_AUTO) lotMethodStr = "Auto (" + DoubleToString(m_riskPercent, 1) + "% risk)";
    else lotMethodStr = "Fixed per Balance";
    
    settings += "Lot Method: " + lotMethodStr + "\n";
    settings += "Magic Number: " + IntegerToString(m_magicNumber) + "\n";
    settings += "Min Quality: " + IntegerToString(m_minQualityScore) + "/100\n";
    settings += "Max Positions: " + IntegerToString(m_maxPositions) + "\n";
    settings += "Symbol: " + _Symbol + " (" + EnumToString(_Period) + ")";
    
    return settings;
}

//+------------------------------------------------------------------+
//| Format strategies column (right side)                            |
//+------------------------------------------------------------------+
string InfoPanel::FormatStrategiesColumn(bool &active[], int count) {
    string strategies[] = {
        "[1] TrendFollowing",
        "[2] Breakout",
        "[3] MeanReversion",
        "[4] SupplyDemand",
        "[5] SmartMoney",
        "[6] PriceAction",
        "[7] GridRecovery",
        "[8] MomentumScalp"
    };
    
    string status = "";
    
    for(int i = 0; i < MathMin(count, 8); i++) {
        string state = active[i] ? "✓ ON " : "○ OFF";
        status += strategies[i] + ": " + state;
        if(i < 7) status += "\n";
    }
    
    return status;
}

//+------------------------------------------------------------------+
//| Format market info (compact single section)                      |
//+------------------------------------------------------------------+
string InfoPanel::FormatMarketInfo(const MarketState &state, ENUM_SIGNAL consensus, double strength, int quality) {
    string info = "";
    info += "┌─ MARKET STATUS ────────────────────────────────────────────────┐\n";
    
    //--- Line 1: Regime + Session + Golden Hour
    string regime = GetRegimeIcon(state.regime) + " " + EnumToString(state.regime);
    string session = EnumToString(state.session);
    string golden = state.isGoldenHour ? "⭐ GOLDEN HOUR" : "";
    info += "│ Regime: " + PadRight(regime, 15) + " Session: " + PadRight(session, 10) + " " + golden + "\n";
    
    //--- Line 2: Consensus Signal + Strength + Quality
    string signal = GetSignalIcon(consensus) + " " + EnumToString(consensus);
    string qualityRating = "";
    if(quality >= 70) qualityRating = "⭐⭐⭐ EXCELLENT";
    else if(quality >= 60) qualityRating = "⭐⭐ GOOD";
    else if(quality >= 50) qualityRating = "⭐ ACCEPTABLE";
    else qualityRating = "POOR";
    
    info += "│ Signal: " + PadRight(signal, 12) + " Strength: " + DoubleToString(strength, 1) + 
            "  Quality: " + IntegerToString(quality) + "/100 (" + qualityRating + ")\n";
    
    info += "└────────────────────────────────────────────────────────────────┘";
    
    return info;
}

//+------------------------------------------------------------------+
//| Format account info (clean layout)                               |
//+------------------------------------------------------------------+
string InfoPanel::FormatAccountInfo(double dailyPnL, double equityDD, int consecutiveLosses) {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double marginFree = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    
    string info = "";
    info += "┌─ ACCOUNT METRICS ──────────────────────────────────────────────┐\n";
    
    //--- Line 1: Balance + Equity + Margin
    info += "│ Balance: $" + PadRight(DoubleToString(balance, 2), 10) + 
            " Equity: $" + PadRight(DoubleToString(equity, 2), 10) +
            " Margin: $" + DoubleToString(margin, 2) + "\n";
    
    //--- Line 2: Daily P/L + Equity DD + Consecutive Losses
    string pnlIcon = (dailyPnL >= 0) ? "▲" : "▼";
    string pnlColor = (dailyPnL >= 0) ? "+" : "";
    
    string ddWarning = (equityDD >= 10.0) ? " ⚠" : "";
    string lossWarning = (consecutiveLosses >= 2) ? " ⚠" : "";
    
    info += "│ Daily P/L: " + pnlIcon + " " + pnlColor + PadRight(DoubleToString(dailyPnL, 2), 8) +
            " Equity DD: " + DoubleToString(equityDD, 1) + "%" + PadRight(ddWarning, 3) +
            " Losses: " + IntegerToString(consecutiveLosses) + lossWarning + "\n";
    
    info += "└────────────────────────────────────────────────────────────────┘";
    
    return info;
}

//+------------------------------------------------------------------+
//| Format footer (minimal)                                          |
//+------------------------------------------------------------------+
string InfoPanel::FormatFooter(void) {
    string accountName = AccountInfoString(ACCOUNT_NAME);
    int accountNumber = (int)AccountInfoInteger(ACCOUNT_LOGIN);
    string server = AccountInfoString(ACCOUNT_SERVER);
    int leverage = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
    
    string footer = "";
    footer += "Account: " + accountName + " #" + IntegerToString(accountNumber) + 
              " | Server: " + server + " | Leverage: 1:" + IntegerToString(leverage) + "\n";
    footer += "© 2026 Aurum Synapse - Institutional-Grade Gold Trading Engine";
    
    return footer;
}

//+------------------------------------------------------------------+
//| Helper: Pad string to right with spaces                          |
//+------------------------------------------------------------------+
string InfoPanel::PadRight(string text, int width) {
    int len = StringLen(text);
    if(len >= width) return text;
    
    string padding = "";
    for(int i = 0; i < (width - len); i++) {
        padding += " ";
    }
    
    return text + padding;
}

//+------------------------------------------------------------------+
//| Get signal icon for display                                      |
//+------------------------------------------------------------------+
string InfoPanel::GetSignalIcon(ENUM_SIGNAL signal) {
    switch(signal) {
        case SIGNAL_BUY:  return "▲";
        case SIGNAL_SELL: return "▼";
        default:          return "●";
    }
}

//+------------------------------------------------------------------+
//| Get regime icon for display                                      |
//+------------------------------------------------------------------+
string InfoPanel::GetRegimeIcon(ENUM_REGIME regime) {
    switch(regime) {
        case REGIME_TRENDING: return "→";
        case REGIME_RANGING:  return "↔";
        case REGIME_VOLATILE: return "⚡";
        case REGIME_CALM:     return "~";
        default:              return "?";
    }
}

//+------------------------------------------------------------------+
//| Show panel                                                       |
//+------------------------------------------------------------------+
void InfoPanel::Show(void) {
    m_isVisible = true;
}

//+------------------------------------------------------------------+
//| Hide panel                                                       |
//+------------------------------------------------------------------+
void InfoPanel::Hide(void) {
    m_isVisible = false;
    Clear();
}

//+------------------------------------------------------------------+
//| Clear display                                                    |
//+------------------------------------------------------------------+
void InfoPanel::Clear(void) {
    Comment("");
    m_lastDisplay = "";
}

//+------------------------------------------------------------------+
//| END OF INFO PANEL                                                |
//+------------------------------------------------------------------+
