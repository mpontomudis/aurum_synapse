//+------------------------------------------------------------------+
//|                                          StrategyFitness.mqh     |
//|     Slot × REGIME_PROXY descriptive matrix (no $ P/L).         |
//+------------------------------------------------------------------+
#ifndef __AURUM_STRATEGY_FITNESS_MQH__
#define __AURUM_STRATEGY_FITNESS_MQH__

#include "AnalyticsTypes.mqh"
#include "RegimeLabels.mqh"

struct StrategySlotRegimeStats {
    ulong  bars;
    ulong  activeBars;
    ulong  signalMatchesConsensus;
    RunningStatD strengthWhenActive;
};

struct StrategyFitnessState {
    StrategySlotRegimeStats cell[REGIME_PROXY_COUNT][TELEMETRY_STRATEGY_SLOTS];
};

void StrategyFitness_Reset(StrategyFitnessState &s) {
    for(int r = 0; r < REGIME_PROXY_COUNT; r++) {
        for(int c = 0; c < TELEMETRY_STRATEGY_SLOTS; c++) {
            s.cell[r][c].bars = 0;
            s.cell[r][c].activeBars = 0;
            s.cell[r][c].signalMatchesConsensus = 0;
            s.cell[r][c].strengthWhenActive.Reset();
        }
    }
}

void StrategyFitness_Feed(StrategyFitnessState &s, const TelemetryCsvRow &row, const ENUM_REGIME_PROXY rp) {
    const int ri = (int)rp;
    if(ri < 0 || ri >= REGIME_PROXY_COUNT)
        return;
    const bool haveCons = !row.null_consensus;
    for(int slot = 0; slot < TELEMETRY_STRATEGY_SLOTS; slot++) {
        StrategySlotRegimeStats z = s.cell[ri][slot];
        z.bars++;
        if(!row.null_str_active[slot] && row.strategy_active[slot] != 0) {
            z.activeBars++;
            z.strengthWhenActive.Add(row.strategy_strength[slot], row.null_str_strength[slot]);
        }
        if(haveCons && row.consensus_code != 0 && !row.null_str_sig[slot] &&
           !row.null_str_active[slot] && row.strategy_active[slot] != 0) {
            if(row.strategy_signal[slot] == row.consensus_code)
                z.signalMatchesConsensus++;
        }
        s.cell[ri][slot] = z;
    }
}

string StrategyFitness_SlotName(const int slot) {
    switch(slot) {
        case 0: return "TrendFollowing";
        case 1: return "Breakout";
        case 2: return "MeanReversion";
        case 3: return "SupplyDemand";
        case 4: return "SmartMoney";
        case 5: return "PriceAction";
        case 6: return "GridRecovery";
        case 7: return "MomentumScalp";
        default: return "Slot?";
    }
}

#endif // __AURUM_STRATEGY_FITNESS_MQH__
