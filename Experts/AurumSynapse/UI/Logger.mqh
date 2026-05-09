//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Logger - Structured Logging to File and Journal"

//+------------------------------------------------------------------+
//| Logger Class                                                     |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Write structured logs to daily files                         |
//|   - Support multiple log levels (DEBUG, INFO, WARNING, ERROR, TRADE) |
//|   - Format messages with timestamps                              |
//|   - Organize logs by date (YYYYMMDD.log)                         |
//|   - Also print to MT5 Experts Journal                            |
//|                                                                  |
//| Log Levels:                                                      |
//|   DEBUG   - Development and troubleshooting messages             |
//|   INFO    - General information (EA start, config, etc)          |
//|   WARNING - Non-critical issues (throttling, retries)            |
//|   ERROR   - Errors that don't halt EA (failed orders, etc)       |
//|   TRADE   - Trade execution logs (open, close, modify)           |
//|                                                                  |
//| File Location:                                                   |
//|   MQL5/Files/AurumSynapse/YYYYMMDD.log                           |
//|                                                                  |
//| Format:                                                          |
//|   [YYYY.MM.DD HH:MM:SS] [LEVEL] message                          |
//+------------------------------------------------------------------+
class Logger {
private:
    //--- Static members (shared across all instances)
    static int       s_fileHandle;
    static string    s_currentFile;
    static string    s_currentDate;
    static bool      s_initialized;
    
    //--- Log levels
    enum ENUM_LOG_LEVEL {
        LOG_DEBUG   = 0,
        LOG_INFO    = 1,
        LOG_WARNING = 2,
        LOG_ERROR   = 3,
        LOG_TRADE   = 4
    };
    
    //--- Internal methods
    static string    GetTimestamp();
    static string    GetDateString();
    static string    FormatMessage(string level, string message);
    static bool      EnsureFileOpen();
    static void      WriteLine(string message);
    static void      CheckDateChange();
    static string    LevelToString(ENUM_LOG_LEVEL level);
    
public:
    //--- Initialization
    static bool      Init();
    static void      Deinit();
    
    //--- Main logging methods
    static void      Log(string message, string level);
    static void      Debug(string message);
    static void      Info(string message);
    static void      Warning(string message);
    static void      Error(string message);
    static void      Trade(string message);
    
    //--- Structured logging
    static void      LogTrade(ulong ticket, string action, double lot, 
                             double price, double sl, double tp, int quality);
    static void      LogError(string function, string message);
    static void      LogSignal(string signal, int activeStrategies, 
                              double consensusStrength, int qualityScore);
    
    //--- File management
    static void      Flush();
    static void      CloseFile();
};

//+------------------------------------------------------------------+
//| Static member initialization                                     |
//+------------------------------------------------------------------+
static int    Logger::s_fileHandle = INVALID_HANDLE;
static string Logger::s_currentFile = "";
static string Logger::s_currentDate = "";
static bool   Logger::s_initialized = false;

//+------------------------------------------------------------------+
//| Initialize logger                                                |
//+------------------------------------------------------------------+
bool Logger::Init(void) {
    if(s_initialized) return true;
    
    //--- Create log directory if needed
    string dirPath = "AurumSynapse";
    if(!FolderCreate(dirPath, FILE_COMMON)) {
        //--- Directory might already exist, check last error
        int error = GetLastError();
        if(error != 0 && error != 5019) {  // 5019 = directory already exists
            Print("WARNING: Failed to create log directory - Error: ", error);
        }
    }
    
    //--- Get current date
    s_currentDate = GetDateString();
    
    //--- Open log file
    if(!EnsureFileOpen()) {
        Print("ERROR: Failed to open log file");
        return false;
    }
    
    s_initialized = true;
    
    //--- Write initialization message
    Info("Logger initialized - File: " + s_currentFile);
    Info("Aurum Synapse v2.0 - Session started");
    
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup logger                                                   |
//+------------------------------------------------------------------+
void Logger::Deinit(void) {
    if(!s_initialized) return;
    
    Info("Aurum Synapse v2.0 - Session ended");
    Info("Logger closing - Total session logs written");
    
    CloseFile();
    s_initialized = false;
}

//+------------------------------------------------------------------+
//| Generic log method with level                                    |
//+------------------------------------------------------------------+
void Logger::Log(string message, string level) {
    if(!s_initialized && !Init()) return;
    
    CheckDateChange();
    
    string formattedMsg = FormatMessage(level, message);
    WriteLine(formattedMsg);
    Print(formattedMsg);  // Also print to Experts Journal
}

//+------------------------------------------------------------------+
//| Log debug message                                                |
//+------------------------------------------------------------------+
void Logger::Debug(string message) {
    Log(message, "DEBUG");
}

//+------------------------------------------------------------------+
//| Log info message                                                 |
//+------------------------------------------------------------------+
void Logger::Info(string message) {
    Log(message, "INFO");
}

//+------------------------------------------------------------------+
//| Log warning message                                              |
//+------------------------------------------------------------------+
void Logger::Warning(string message) {
    Log(message, "WARNING");
}

//+------------------------------------------------------------------+
//| Log error message                                                |
//+------------------------------------------------------------------+
void Logger::Error(string message) {
    Log(message, "ERROR");
}

//+------------------------------------------------------------------+
//| Log trade message                                                |
//+------------------------------------------------------------------+
void Logger::Trade(string message) {
    Log(message, "TRADE");
}

//+------------------------------------------------------------------+
//| Log trade action (structured)                                    |
//+------------------------------------------------------------------+
void Logger::LogTrade(ulong ticket, string action, double lot,
                     double price, double sl, double tp, int quality) {
    string msg = StringFormat("TRADE %s | Ticket: %I64u | Lot: %.2f | Price: %.2f | SL: %.2f | TP: %.2f | Quality: %d",
                              action, ticket, lot, price, sl, tp, quality);
    Trade(msg);
}

//+------------------------------------------------------------------+
//| Log error with function name (structured)                        |
//+------------------------------------------------------------------+
void Logger::LogError(string function, string message) {
    string msg = StringFormat("%s() - %s", function, message);
    Error(msg);
}

//+------------------------------------------------------------------+
//| Log signal information (structured)                              |
//+------------------------------------------------------------------+
void Logger::LogSignal(string signal, int activeStrategies,
                      double consensusStrength, int qualityScore) {
    string msg = StringFormat("SIGNAL %s | Active: %d | Strength: %.1f | Quality: %d/100",
                              signal, activeStrategies, consensusStrength, qualityScore);
    Info(msg);
}

//+------------------------------------------------------------------+
//| Get current timestamp string                                     |
//+------------------------------------------------------------------+
string Logger::GetTimestamp(void) {
    return TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
}

//+------------------------------------------------------------------+
//| Get date string for filename (YYYYMMDD)                          |
//+------------------------------------------------------------------+
string Logger::GetDateString(void) {
    MqlDateTime dt;
    TimeCurrent(dt);
    return StringFormat("%04d%02d%02d", dt.year, dt.mon, dt.day);
}

//+------------------------------------------------------------------+
//| Format log message with timestamp and level                      |
//+------------------------------------------------------------------+
string Logger::FormatMessage(string level, string message) {
    return StringFormat("[%s] [%-7s] %s", GetTimestamp(), level, message);
}

//+------------------------------------------------------------------+
//| Ensure log file is open (create if needed)                       |
//+------------------------------------------------------------------+
bool Logger::EnsureFileOpen(void) {
    //--- Check if file is already open
    if(s_fileHandle != INVALID_HANDLE) {
        return true;
    }
    
    //--- Build filename: AurumSynapse/YYYYMMDD.log
    s_currentDate = GetDateString();
    s_currentFile = "AurumSynapse\\" + s_currentDate + ".log";
    
    //--- Open file for writing (append mode)
    s_fileHandle = FileOpen(s_currentFile, 
                            FILE_WRITE|FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
    
    if(s_fileHandle == INVALID_HANDLE) {
        int error = GetLastError();
        Print("ERROR: Failed to open log file: ", s_currentFile, " Error: ", error);
        return false;
    }
    
    //--- Move to end of file (append mode)
    FileSeek(s_fileHandle, 0, SEEK_END);
    
    return true;
}

//+------------------------------------------------------------------+
//| Write line to log file                                           |
//+------------------------------------------------------------------+
void Logger::WriteLine(string message) {
    if(!EnsureFileOpen()) return;
    
    //--- Write to file
    FileWriteString(s_fileHandle, message + "\n");
}

//+------------------------------------------------------------------+
//| Check if date changed and rotate log file                        |
//+------------------------------------------------------------------+
void Logger::CheckDateChange(void) {
    string currentDate = GetDateString();
    
    //--- Check if date changed
    if(currentDate != s_currentDate) {
        // IMPORTANT:
        // Do NOT call Info()/Log() from inside CheckDateChange().
        // Info() -> Log() -> CheckDateChange() would recurse infinitely and crash (stack overflow),
        // especially on long backtests that cross midnight.
        static bool s_rotating = false;
        if(s_rotating) return;
        s_rotating = true;
        
        string msg1 = FormatMessage("INFO", "Date changed - Rotating log file");
        WriteLine(msg1);
        Print(msg1);
        
        CloseFile();
        s_currentDate = currentDate;
        EnsureFileOpen();
        
        string msg2 = FormatMessage("INFO", "New log file opened - Date: " + currentDate);
        WriteLine(msg2);
        Print(msg2);
        
        s_rotating = false;
    }
}

//+------------------------------------------------------------------+
//| Flush log buffer to disk                                         |
//+------------------------------------------------------------------+
void Logger::Flush(void) {
    if(s_fileHandle != INVALID_HANDLE) {
        FileFlush(s_fileHandle);
    }
}

//+------------------------------------------------------------------+
//| Close log file                                                   |
//+------------------------------------------------------------------+
void Logger::CloseFile(void) {
    if(s_fileHandle != INVALID_HANDLE) {
        FileFlush(s_fileHandle);
        FileClose(s_fileHandle);
        s_fileHandle = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Convert log level enum to string                                 |
//+------------------------------------------------------------------+
string Logger::LevelToString(ENUM_LOG_LEVEL level) {
    switch(level) {
        case LOG_DEBUG:   return "DEBUG";
        case LOG_INFO:    return "INFO";
        case LOG_WARNING: return "WARNING";
        case LOG_ERROR:   return "ERROR";
        case LOG_TRADE:   return "TRADE";
        default:          return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| END OF LOGGER                                                    |
//+------------------------------------------------------------------+
