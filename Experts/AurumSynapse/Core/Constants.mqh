//+------------------------------------------------------------------+
//|                                                    Constants.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Constants, Enumerations, and Configuration"
#property description "8-Strategy Weighted Consensus with Adaptive Learning"
#property strict

//+------------------------------------------------------------------+
//| Core Enumerations                                                |
//+------------------------------------------------------------------+

// Trading signal directions
enum ENUM_SIGNAL {
    SIGNAL_NONE = 0,     // No signal, do not trade
    SIGNAL_BUY  = 1,     // Buy signal
    SIGNAL_SELL = -1     // Sell signal
};

// Market regime classifications
enum ENUM_REGIME {
    REGIME_TRENDING = 0,  // Directional movement, ADX > 25
    REGIME_RANGING  = 1,  // Sideways consolidation, tight range
    REGIME_VOLATILE = 2,  // High ATR, erratic movement
    REGIME_CALM     = 3   // Low volatility, stable
};

// Trend direction
enum ENUM_TREND_DIR {
    TREND_UP   = 1,      // Uptrend (HH/HL)
    TREND_DOWN = -1,     // Downtrend (LL/LH)
    TREND_FLAT = 0       // No clear trend
};

// Market structure patterns
enum ENUM_STRUCTURE {
    STRUCTURE_HH_HL = 1,  // Higher highs, higher lows (bullish)
    STRUCTURE_LL_LH = -1, // Lower lows, lower highs (bearish)
    STRUCTURE_NONE  = 0   // No clear structure
};

// Trading session classifications
enum ENUM_SESSION {
    SESSION_ASIAN    = 0,  // Asian session (Tokyo)
    SESSION_LONDON   = 1,  // London session
    SESSION_NEWYORK  = 2,  // New York session
    SESSION_OVERLAP  = 3   // Session overlap (high liquidity)
};

// Trading profile risk levels
enum ENUM_PROFILE {
    PROFILE_CONSERVATIVE = 0,  // Low risk, 70pt quality, 5-10 trades/day
    PROFILE_BALANCED     = 1,  // Medium risk, 60pt quality, 10-15 trades/day
    PROFILE_AGGRESSIVE   = 2   // High risk, 50pt quality, 15-25 trades/day
};

// Strategy indices (for array access)
enum ENUM_STRATEGY_INDEX {
    STRATEGY_TREND_FOLLOWING  = 0,
    STRATEGY_BREAKOUT         = 1,
    STRATEGY_MEAN_REVERSION   = 2,
    STRATEGY_SUPPLY_DEMAND    = 3,
    STRATEGY_SMART_MONEY      = 4,
    STRATEGY_PRICE_ACTION     = 5,
    STRATEGY_GRID_RECOVERY    = 6,
    STRATEGY_MOMENTUM_SCALP   = 7
};

// Circuit breaker reasons
enum ENUM_HALT_REASON {
    HALT_NONE              = 0,
    HALT_DRAWDOWN          = 1,   // Max drawdown exceeded
    HALT_DAILY_LOSS        = 2,   // Daily loss limit hit
    HALT_CONSECUTIVE_LOSS  = 3,   // Too many consecutive losses
    HALT_SPREAD_BLOWOUT    = 4,   // Spread abnormally high
    HALT_CONNECTION_LOST   = 5,   // No ticks received
    HALT_MANUAL            = 6    // User-initiated halt
};

//--- Signal / gate rejection (H2 diagnostic & tooling)
enum ENUM_SIGNAL_REJECT_REASON {
    SIGNAL_REJECT_NONE                 = 0,
    SIGNAL_REJECT_NO_CONSENSUS         = 1,
    SIGNAL_REJECT_QUALITY_LOW          = 2,
    SIGNAL_REJECT_REQUIRE_TREND        = 3,
    SIGNAL_REJECT_REQUIRE_KEYLEVEL     = 4,
    SIGNAL_REJECT_REQUIRE_MOMENTUM     = 5,
    SIGNAL_REJECT_MAX_POSITIONS        = 6,
    SIGNAL_REJECT_MAX_CONSEC_LOSSES    = 7,
    SIGNAL_REJECT_RISK_HALT           = 8,
    SIGNAL_REJECT_TIME_FILTER          = 9,
    SIGNAL_REJECT_SPREAD               = 10,
    SIGNAL_REJECT_MARKET_UPDATE_FAIL   = 11
};

// Lot sizing methods (MT5 Inputs list order: Automatic, Fixed, Fixed per Balance)
// NOTE: numeric values changed vs older builds — re-save .set: 0=Automatic, 1=Fixed, 2=Fixed per Balance
enum ENUM_LOT_METHOD {
    LOT_AUTO               = 0,   // Automatic
    LOT_FIXED              = 1,   // Fixed
    LOT_FIXED_PER_BALANCE  = 2   // Fixed per Balance
};

//+------------------------------------------------------------------+
//| EA Identity & Version                                            |
//+------------------------------------------------------------------+
#define EA_NAME             "Aurum Synapse"
#define EA_VERSION          "2.00"
#define EA_DESCRIPTION      "Institutional-Grade Gold Trading Engine"
#define EA_MAGIC_NUMBER     20260505
#define EA_BUILD_DATE       "2026.05.05"

//+------------------------------------------------------------------+
//| Quality Scoring System (11 Components, 100 points max)           |
//+------------------------------------------------------------------+
// Component maximum scores
#define QUALITY_TREND_ALIGNMENT_MAX      12
#define QUALITY_KEY_LEVEL_PROXIMITY_MAX  12
#define QUALITY_MOMENTUM_CONFIRM_MAX     10
#define QUALITY_VOLUME_ACTIVITY_MAX       8
#define QUALITY_SESSION_QUALITY_MAX      15  // Golden hours = max points
#define QUALITY_VOLATILITY_FIT_MAX        8
#define QUALITY_CONSENSUS_STRENGTH_MAX   10
#define QUALITY_MARKET_STRUCTURE_MAX     10
#define QUALITY_LIQUIDITY_HUNT_MAX        5
#define QUALITY_SPREAD_EXECUTION_MAX      5
#define QUALITY_TIME_EXIT_POTENTIAL_MAX   5

// Profile thresholds
#define QUALITY_THRESHOLD_CONSERVATIVE   70  // 70+ pts required
#define QUALITY_THRESHOLD_BALANCED       60  // 60+ pts required
#define QUALITY_THRESHOLD_AGGRESSIVE     50  // 50+ pts required

// Quality scoring multipliers
#define QUALITY_GOLDEN_HOUR_MULTIPLIER   1.0  // Full points during golden hours
#define QUALITY_NORMAL_HOUR_MULTIPLIER   0.6  // Reduced points outside golden hours
#define QUALITY_DEAD_HOUR_MULTIPLIER     0.3  // Minimal points in dead zones

//+------------------------------------------------------------------+
//| Frequency Control Limits                                         |
//+------------------------------------------------------------------+
#define MAX_TRADES_PER_DAY          25   // Daily trade limit
#define MAX_TRADES_PER_HOUR          5   // Hourly trade limit
#define MIN_TRADE_GAP_SECONDS      120   // Minimum 2 minutes between trades
#define COOLDOWN_DURATION_MINUTES   30   // Cooldown after trigger events

// Performance throttling
#define THROTTLE_WIN_RATE_THRESHOLD 50.0 // Reduce frequency if WR < 50%
#define THROTTLE_FREQUENCY_DIVISOR   2.0 // Halve frequency when throttled

//+------------------------------------------------------------------+
//| Risk Management Limits                                           |
//+------------------------------------------------------------------+
// Drawdown protection
#define MAX_DRAWDOWN_PERCENT        12.0  // Max DD from peak equity
#define MAX_DAILY_LOSS_PERCENT       5.0  // Max daily loss as % of equity
#define MAX_DAILY_LOSS_DOLLARS      50.0  // Absolute daily loss cap (USD)

// Consecutive loss protection
#define MAX_CONSECUTIVE_LOSSES       3    // Pause after N losses in a row
#define CONSECUTIVE_LOSS_COOLDOWN   30    // Minutes to pause

// Position limits
#define MAX_OPEN_POSITIONS           5    // Maximum concurrent positions
#define MAX_GRID_LEVELS              3    // Maximum grid levels (strict!)
#define MAX_POSITION_SIZE_LOTS       0.1  // Maximum lot size per position

// Lot sizing
#define LOT_SIZE_MIN                 0.01 // Minimum lot size
#define LOT_SIZE_BASE                0.01 // Base lot for scalping
#define LOT_SIZE_MAX_BASE            0.03 // Scalper ceiling for LOT_AUTO only (not LOT_FIXED / LOT_FIXED_PER_BALANCE)
#define LOT_SIZE_STEP                0.01 // Lot size increment

//+------------------------------------------------------------------+
//| Spread & Execution Limits (in points)                            |
//+------------------------------------------------------------------+
#define MAX_SPREAD_NORMAL            30   // Normal spread threshold
#define MAX_SPREAD_OPTIMAL           20   // Optimal spread for entries
#define MAX_SPREAD_EMERGENCY         50   // Emergency threshold (halt if exceeded)
#define MAX_SLIPPAGE_POINTS          20   // Maximum acceptable slippage
#define MAX_SLIPPAGE_PIPS             2   // Maximum slippage in pips

// Execution retry settings
#define ORDER_RETRY_MAX_ATTEMPTS      3   // Maximum order send retries
#define ORDER_RETRY_DELAY_MS        100   // Milliseconds between retries
#define ORDER_TIMEOUT_SECONDS        10   // Order execution timeout

//+------------------------------------------------------------------+
//| Time-Based Exit System (Quantum Queen Edge)                      |
//+------------------------------------------------------------------+
// Duration thresholds (minutes)
#define TIME_EXIT_TARGET             5    // Target: <5 min (94-96% WR)
#define TIME_EXIT_ACCEPTABLE        30    // Acceptable: <30 min (70%+ WR)
#define TIME_EXIT_WARNING           60    // Warning: 60 min (monitor closely)
#define TIME_EXIT_EMERGENCY        120    // Emergency: 120 min (44% WR - CLOSE!)
#define TIME_EXIT_MAXIMUM          240    // Maximum: 240 min (hard limit)

// Time-based SL tightening
#define TIME_TIGHTEN_START_MIN      30    // Start tightening after 30 min
#define TIME_TIGHTEN_INTERVAL_MIN   15    // Tighten every 15 min
#define TIME_TIGHTEN_PERCENT        10    // Reduce SL distance by 10% each time

//+------------------------------------------------------------------+
//| Trade Management AI Settings                                     |
//+------------------------------------------------------------------+
// Breakeven move
#define BE_MOVE_THRESHOLD_PERCENT   70    // Move to BE at 70% to TP
#define BE_BUFFER_POINTS             5    // Buffer above BE (points)

// Partial close
#define PARTIAL_CLOSE_PERCENT       50    // Close 50% of position
#define PARTIAL_CLOSE_AT_PERCENT    90    // Trigger at 90% to TP

// TP extension (for strong momentum)
#define TP_EXTEND_MULTIPLIER        1.5   // Extend TP by 1.5×
#define TP_EXTEND_MOMENTUM_MIN      1.3   // Require 1.3× avg momentum

// Trailing stop
#define TRAIL_START_MULTIPLIER      1.5   // Start trail after 1.5× TP distance
#define TRAIL_STEP_POINTS           10    // Trail every 10 points
#define TRAIL_DISTANCE_POINTS       50    // Keep SL 50 points behind

//+------------------------------------------------------------------+
//| Golden Hours (WIT Timezone, UTC+7)                               |
//+------------------------------------------------------------------+
#define GOLDEN_HOUR_1_START         22    // 22:00 WIT (Asian/Europe overlap)
#define GOLDEN_HOUR_1_END           23    // 23:00 WIT
#define GOLDEN_HOUR_2_START          8    // 08:00 WIT (London open)
#define GOLDEN_HOUR_2_END            9    // 09:00 WIT

// Session times (UTC+7 / WIT)
#define SESSION_ASIAN_START          0    // 00:00 WIT
#define SESSION_ASIAN_END            9    // 09:00 WIT
#define SESSION_LONDON_START         7    // 07:00 WIT (15:00 London local)
#define SESSION_LONDON_END          16    // 16:00 WIT
#define SESSION_NEWYORK_START       14    // 14:00 WIT (20:00 NY local)
#define SESSION_NEWYORK_END         23    // 23:00 WIT

// Dead zones (low liquidity periods)
#define DEAD_ZONE_1_START            3    // 03:00-06:00 WIT (post-Asian)
#define DEAD_ZONE_1_END              6
#define DEAD_ZONE_2_START           17    // 17:00-19:00 WIT (London close)
#define DEAD_ZONE_2_END             19

//+------------------------------------------------------------------+
//| Strategy Base Weights (from Quantum Queen analysis)              |
//+------------------------------------------------------------------+
#define WEIGHT_TREND_FOLLOWING      1.2   // Strong in trending markets
#define WEIGHT_BREAKOUT             1.1   // Expansion plays
#define WEIGHT_MEAN_REVERSION       1.0   // Range returns
#define WEIGHT_SUPPLY_DEMAND        1.2   // Zone reactions
#define WEIGHT_SMART_MONEY          1.3   // Order flow edge
#define WEIGHT_PRICE_ACTION         1.0   // Candle confirmation
#define WEIGHT_GRID_RECOVERY        0.7   // Risk averaging (restricted)
#define WEIGHT_MOMENTUM_SCALP       1.5   // ⭐ Primary edge (<5min = 94-96% WR)

// Weight adaptation settings
#define MIN_ADAPTIVE_WEIGHT         0.3   // Minimum weight (never disable completely)
#define MAX_ADAPTIVE_WEIGHT         2.0   // Maximum weight (prevent over-reliance)
#define WEIGHT_BOOST_HIGH_WR        0.20  // +20% if WR > 80%
#define WEIGHT_REDUCE_LOW_WR        0.30  // -30% if WR < 50%
#define WEIGHT_BOOST_HIGH_PF        0.15  // +15% if PF > 3.0
#define WEIGHT_REDUCE_LOW_PF        0.20  // -20% if PF < 1.5

//+------------------------------------------------------------------+
//| Regime Memory Settings (Adaptive Learning)                       |
//+------------------------------------------------------------------+
#define REGIME_MEMORY_WINDOW        50    // Last 50 trades per regime×strategy cell
#define REGIME_MEMORY_MIN_TRADES    10    // Minimum trades before adapting weights
#define REGIME_MEMORY_SAVE_INTERVAL 10    // Save to file every N trades

// Learning thresholds
#define LEARNING_WIN_RATE_EXCELLENT 80.0  // WR > 80% = excellent
#define LEARNING_WIN_RATE_POOR      50.0  // WR < 50% = poor
#define LEARNING_PROFIT_FACTOR_HIGH  3.0  // PF > 3.0 = high
#define LEARNING_PROFIT_FACTOR_LOW   1.5  // PF < 1.5 = low

//+------------------------------------------------------------------+
//| Indicator Settings                                               |
//+------------------------------------------------------------------+
// Moving averages
#define EMA_PERIOD_FAST             21
#define EMA_PERIOD_MEDIUM           50
#define EMA_PERIOD_SLOW            200

// RSI
#define RSI_PERIOD                  14
#define RSI_OVERBOUGHT              70
#define RSI_OVERSOLD                30
#define RSI_EXTREME_HIGH            80
#define RSI_EXTREME_LOW             20

// MACD
#define MACD_FAST_PERIOD            12
#define MACD_SLOW_PERIOD            26
#define MACD_SIGNAL_PERIOD           9

// Bollinger Bands
#define BB_PERIOD                   20
#define BB_DEVIATION                 2.0
#define BB_SQUEEZE_THRESHOLD         0.8  // Band width < 0.8× avg = squeeze

// ATR
#define ATR_PERIOD                  14
#define ATR_MULTIPLIER_SL            2.0  // SL = 2× ATR
#define ATR_MULTIPLIER_TP            3.0  // TP = 3× ATR
#define ATR_HIGH_VOLATILITY          2.0  // ATR > 2× avg = high volatility
#define ATR_LOW_VOLATILITY           0.5  // ATR < 0.5× avg = low volatility

// ADX
#define ADX_PERIOD                  14
#define ADX_TREND_THRESHOLD         25    // ADX > 25 = trending
#define ADX_STRONG_TREND            40    // ADX > 40 = strong trend

// Stochastic
#define STOCH_K_PERIOD               5
#define STOCH_D_PERIOD               3
#define STOCH_SLOWING                3
#define STOCH_OVERBOUGHT            80
#define STOCH_OVERSOLD              20

// Volume
#define VOLUME_MULTIPLIER_HIGH       1.2  // Volume > 1.2× avg = high
#define VOLUME_MULTIPLIER_LOW        0.7  // Volume < 0.7× avg = low

//+------------------------------------------------------------------+
//| Key Level Detection                                              |
//+------------------------------------------------------------------+
#define KEY_LEVEL_LOOKBACK_BARS    100   // Bars to scan for S/R levels
#define KEY_LEVEL_PROXIMITY_PIPS    50   // Within 50 pips = "at key level"
#define KEY_LEVEL_STRENGTH_MIN       3   // Min touches to qualify as key level
#define ZONE_WIDTH_PIPS             20   // Supply/demand zone width

//+------------------------------------------------------------------+
//| File System Paths                                                |
//+------------------------------------------------------------------+
#define REGIME_MEMORY_FILE      "AurumSynapse\\RegimeMemory.bin"
#define REGIME_MEMORY_BACKUP    "AurumSynapse\\RegimeMemory.bak"
#define LOG_FOLDER              "AurumSynapse\\Logs\\"
#define LOG_FILE_PREFIX         "AurumSynapse\\Logs\\AS_"
#define TELEMETRY_FILE          "AurumSynapse\\Telemetry.csv"
#define TELEMETRY_ARCHIVE       "AurumSynapse\\Telemetry_Archive\\"
#define CONFIG_FILE             "AurumSynapse\\Config.ini"

//+------------------------------------------------------------------+
//| Aurum Synapse Color Scheme                                       |
//+------------------------------------------------------------------+
// Primary colors (Gold theme)
#define COLOR_GOLD              C'255,215,0'    // Pure gold
#define COLOR_GOLD_DARK         C'184,134,11'   // Dark gold
#define COLOR_GOLD_LIGHT        C'255,236,139'  // Light gold
#define COLOR_BLACK             C'0,0,0'        // Pure black
#define COLOR_CHARCOAL          C'36,36,36'     // Dark gray

// Signal colors
#define COLOR_BUY_SIGNAL        C'0,255,0'      // Green
#define COLOR_SELL_SIGNAL       C'255,0,0'      // Red
#define COLOR_NEUTRAL           C'169,169,169'  // Gray

// Status colors
#define COLOR_PROFIT            C'0,200,0'      // Dark green
#define COLOR_LOSS              C'200,0,0'      // Dark red
#define COLOR_BREAKEVEN         C'255,255,0'    // Yellow
#define COLOR_WARNING           C'255,140,0'    // Orange
#define COLOR_CRITICAL          C'255,0,255'    // Magenta

// UI colors
#define COLOR_PANEL_BG          C'24,24,24'     // Dark panel background
#define COLOR_PANEL_BORDER      COLOR_GOLD      // Gold border
#define COLOR_TEXT_MAIN         COLOR_GOLD      // Gold text
#define COLOR_TEXT_SECONDARY    C'192,192,192'  // Light gray text
#define COLOR_TEXT_DIM          C'128,128,128'  // Dim gray text

// Regime colors
#define COLOR_REGIME_TRENDING   C'0,191,255'    // Deep sky blue
#define COLOR_REGIME_RANGING    C'255,165,0'    // Orange
#define COLOR_REGIME_VOLATILE   C'255,69,0'     // Red-orange
#define COLOR_REGIME_CALM       C'152,251,152'  // Pale green

// Info panel settings
#define PANEL_X_OFFSET          10
#define PANEL_Y_OFFSET          30
#define PANEL_FONT_SIZE         9
#define PANEL_FONT_NAME         "Consolas"
#define PANEL_LINE_HEIGHT       16

//+------------------------------------------------------------------+
//| Logging & Debug Settings                                         |
//+------------------------------------------------------------------+
#define LOG_LEVEL_NONE          0   // No logging
#define LOG_LEVEL_ERROR         1   // Errors only
#define LOG_LEVEL_WARNING       2   // Warnings + errors
#define LOG_LEVEL_INFO          3   // Info + warnings + errors
#define LOG_LEVEL_DEBUG         4   // Everything including debug
#define LOG_LEVEL_TRACE         5   // Verbose trace logging

// Default log level (can be overridden by input)
#define DEFAULT_LOG_LEVEL       LOG_LEVEL_INFO

// Log file rotation
#define LOG_MAX_SIZE_MB         10  // Rotate log after 10 MB
#define LOG_MAX_FILES           5   // Keep last 5 log files

//+------------------------------------------------------------------+
//| Performance & Optimization                                       |
//+------------------------------------------------------------------+
#define ANALYSIS_THROTTLE_MS    1000  // Full analysis max once per second
#define INDICATOR_CACHE_MS      500   // Cache indicator values for 500ms
#define TIMER_INTERVAL_SEC      30    // OnTimer() called every 30 seconds

// Memory optimization
#define MAX_HISTORY_BARS        1000  // Maximum bars to load in memory
#define MAX_SIGNAL_BUFFER       100   // Signal history buffer size

//+------------------------------------------------------------------+
//| News Filter Settings                                             |
//+------------------------------------------------------------------+
#define NEWS_AVOID_MINUTES_BEFORE  30  // Stop trading 30 min before news
#define NEWS_AVOID_MINUTES_AFTER   30  // Resume trading 30 min after news

// High-impact news events to avoid (manual list, enhance with calendar later)
// NFP, FOMC, CPI, ECB, BOE decisions, GDP releases

//+------------------------------------------------------------------+
//| Backtesting & Optimization                                       |
//+------------------------------------------------------------------+
#define BACKTEST_START_YEAR     2020
#define BACKTEST_END_YEAR       2024
#define BACKTEST_MIN_TRADES     100   // Minimum trades for valid backtest

// Optimization targets
#define OPTIMIZATION_TARGET_WR   70.0  // Target win rate %
#define OPTIMIZATION_TARGET_PF    2.5  // Target profit factor
#define OPTIMIZATION_TARGET_DD   10.0  // Target max DD %

//+------------------------------------------------------------------+
//| Symbol-Specific Settings (XAUUSD)                                |
//+------------------------------------------------------------------+
#define GOLD_POINT_VALUE        0.01   // 1 point = $0.01 per lot
#define GOLD_TICK_SIZE          0.01   // Minimum price change
#define GOLD_TYPICAL_SPREAD     30     // Typical spread in points
#define GOLD_COMMISSION_USD     0.10   // Round-trip commission per lot

//+------------------------------------------------------------------+
//| Error Codes & Messages                                           |
//+------------------------------------------------------------------+
#define ERROR_INIT_FAILED           -1
#define ERROR_INVALID_PARAMS        -2
#define ERROR_MEMORY_ALLOCATION     -3
#define ERROR_FILE_OPERATION        -4
#define ERROR_INDICATOR_CREATE      -5
#define ERROR_TRADING_DISABLED      -6

//+------------------------------------------------------------------+
//| Consensus Voting Constants                                       |
//+------------------------------------------------------------------+
#define CONSENSUS_MIN_VOTERS         3      // Minimum 3 strategies must vote
#define CONSENSUS_QUORUM_PERCENT     0.4    // 40% of active strategies
#define CONSENSUS_MARGIN_PERCENT     1.05   // 5% margin to prevent flip-flop

//+------------------------------------------------------------------+
//| Magic Number Generator (for multi-instance support)              |
//+------------------------------------------------------------------+
#define MAGIC_OFFSET_CONSERVATIVE    0      // Base + 0
#define MAGIC_OFFSET_BALANCED        1000   // Base + 1000
#define MAGIC_OFFSET_AGGRESSIVE      2000   // Base + 2000

//+------------------------------------------------------------------+
//| Version History & Build Info                                     |
//+------------------------------------------------------------------+
#define VERSION_MAJOR           2
#define VERSION_MINOR           0
#define VERSION_PATCH           0
#define BUILD_NUMBER            1

//+------------------------------------------------------------------+
//| END OF CONSTANTS                                                 |
//+------------------------------------------------------------------+
