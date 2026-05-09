//+------------------------------------------------------------------+
//|                                               SignalManager.mqh |
//|                                      Aurum Synapse v2.0 Pro      |
//|                          Institutional-Grade Gold Trading Engine |
//|                                   Copyright 2026, Aurum Synapse  |
//|                                          https://aurumsynapse.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Aurum Synapse"
#property link      "https://aurumsynapse.io"
#property version   "2.00"
#property description "Signal Manager - Weighted Consensus Voting Engine"

#include "../Core/Constants.mqh"
#include "../Core/Structures.mqh"

//+------------------------------------------------------------------+
//| Signal Manager Class                                             |
//|                                                                  |
//| Responsibilities:                                                |
//|   - Aggregate signals from all active strategies                 |
//|   - Calculate weighted consensus using strategy weights          |
//|   - Determine required votes based on active strategy count      |
//|   - Apply 5% dominance requirement (buy vs sell scores)          |
//|   - Calculate agreement percentage and consensus strength        |
//|                                                                  |
//| Consensus Algorithm:                                             |
//|   1. Count BUY/SELL signals from active strategies               |
//|   2. Calculate weighted scores (strength × weight)               |
//|   3. Required votes = max(3, activeCount × 0.4)                  |
//|   4. BUY if: buyCount >= required AND buyScore > sellScore×1.05  |
//|   5. SELL if: sellCount >= required AND sellScore > buyScore×1.05|
//|                                                                  |
//| Note: This is NOT democratic voting - strategy weights matter!   |
//+------------------------------------------------------------------+
class SignalManager {
private:
    //--- Consensus calculation
    ENUM_SIGNAL      m_consensusSignal;
    double           m_consensusStrength;
    double           m_agreementPct;
    
    //--- Vote tracking
    int              m_buyCount;
    int              m_sellCount;
    int              m_noneCount;
    double           m_buyScore;
    double           m_sellScore;
    int              m_totalActive;
    
    //--- Configuration
    int              m_minConsensus;     // Minimum strategies required to agree
    
public:
    //--- Constructor
    SignalManager();
    ~SignalManager();
    
    //--- Configuration
    void             SetMinConsensus(int minConsensus) { m_minConsensus = MathMax(1, MathMin(8, minConsensus)); }
    int              GetMinConsensus() { return m_minConsensus; }
    
    //--- Main consensus method
    ENUM_SIGNAL      GetConsensusSignal(SignalResult &signals[], int count);
    
    //--- Accessors
    double           GetConsensusStrength() { return m_consensusStrength; }
    double           GetAgreementPercentage() { return m_agreementPct; }
    
    //--- Vote statistics
    int              GetBuyCount() { return m_buyCount; }
    int              GetSellCount() { return m_sellCount; }
    int              GetNoneCount() { return m_noneCount; }
    double           GetBuyScore() { return m_buyScore; }
    double           GetSellScore() { return m_sellScore; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
SignalManager::SignalManager(void) :
    m_consensusSignal(SIGNAL_NONE),
    m_consensusStrength(0),
    m_agreementPct(0),
    m_buyCount(0),
    m_sellCount(0),
    m_noneCount(0),
    m_buyScore(0),
    m_sellScore(0),
    m_totalActive(0),
    m_minConsensus(3)  // Default: require 3 strategies
{
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
SignalManager::~SignalManager(void) {
}

//+------------------------------------------------------------------+
//| Get consensus signal using weighted voting                       |
//|                                                                  |
//| Algorithm:                                                       |
//|   1. Reset all counters                                          |
//|   2. Count signals and calculate weighted scores                 |
//|   3. Determine required votes (min 3, or 40% of active)          |
//|   4. Apply 5% dominance requirement                              |
//|   5. Calculate consensus strength and agreement percentage       |
//+------------------------------------------------------------------+
ENUM_SIGNAL SignalManager::GetConsensusSignal(SignalResult &signals[], int count) {
    //--- Reset all counters
    m_buyCount = 0;
    m_sellCount = 0;
    m_noneCount = 0;
    m_buyScore = 0;
    m_sellScore = 0;
    m_totalActive = 0;
    m_consensusSignal = SIGNAL_NONE;
    m_consensusStrength = 0;
    m_agreementPct = 0;
    
    //--- Count votes and calculate weighted scores
    for(int i = 0; i < count; i++) {
        if(signals[i].signal == SIGNAL_NONE) {
            m_noneCount++;
            continue;
        }
        
        m_totalActive++;
        double weightedScore = signals[i].strength * signals[i].weight;
        
        if(signals[i].signal == SIGNAL_BUY) {
            m_buyCount++;
            m_buyScore += weightedScore;
        }
        else if(signals[i].signal == SIGNAL_SELL) {
            m_sellCount++;
            m_sellScore += weightedScore;
        }
    }
    
    //--- No active signals
    if(m_totalActive == 0) {
        return SIGNAL_NONE;
    }
    
    //--- Calculate required votes using configurable minimum
    //    Use either m_minConsensus or 40% of active strategies, whichever is lower
    //    This allows ultra-permissive testing (1 strategy) or strict consensus (3+)
    int requiredVotes = (int)MathMin(m_minConsensus, MathMax(1, m_totalActive * 0.4));
    
    //--- Check BUY consensus with 5% dominance requirement
    if(m_buyCount >= requiredVotes && m_buyScore > m_sellScore * 1.05) {
        m_consensusSignal = SIGNAL_BUY;
        m_consensusStrength = m_buyScore;
        m_agreementPct = (double)m_buyCount / m_totalActive * 100.0;
        return SIGNAL_BUY;
    }
    
    //--- Check SELL consensus with 5% dominance requirement
    if(m_sellCount >= requiredVotes && m_sellScore > m_buyScore * 1.05) {
        m_consensusSignal = SIGNAL_SELL;
        m_consensusStrength = m_sellScore;
        m_agreementPct = (double)m_sellCount / m_totalActive * 100.0;
        return SIGNAL_SELL;
    }
    
    //--- No consensus reached
    return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| END OF SIGNAL MANAGER                                            |
//+------------------------------------------------------------------+
