//+------------------------------------------------------------------+
//| GovernanceRegimeDatasetV1.mqh                                   |
//| PHASE 22 — regime contracts, telemetry structs, runtime store     |
//| EAurumMarketRegime uses AURUM_REGIME_* identifiers to avoid        |
//| collision with core ENUM_REGIME (REGIME_TRENDING, ...).            |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_DATASET_V1_MQH__
#define __AURUM_GOV_REGIME_DATASET_V1_MQH__

#define GOV_REGIME_ABI_VER_V1            ((uint)1)
#define GOV_REGIME_STRAT_SLOTS_V1        8
#define GOV_REGIME_AURUM_SLOT_COUNT_V1   12
#define GOV_REGIME_TRANSITION_RING_V1   128
#define GOV_REGIME_POS_HASH_V1          256
#define GOV_REGIME_TELEM_RING_V1        512

inline double GovRegimeMathV1_Clamp01(const double x)
{
   if(x < 0.0)
      return 0.0;
   if(x > 1.0)
      return 1.0;
   return x;
}

enum EAurumMarketRegime
{
   AURUM_REGIME_UNKNOWN = 0,
   AURUM_REGIME_TRENDING,
   AURUM_REGIME_RANGING,
   AURUM_REGIME_HIGH_VOL,
   AURUM_REGIME_LOW_VOL,
   AURUM_REGIME_BREAKOUT,
   AURUM_REGIME_MEAN_REVERSION,
   AURUM_REGIME_LIQUIDITY_SWEEP,
   AURUM_REGIME_ACCUMULATION,
   AURUM_REGIME_DISTRIBUTION,
   AURUM_REGIME_VOLATILITY_EXPANSION,
   AURUM_REGIME_VOLATILITY_COMPRESSION
};

struct SGovRegimeTelemetryV1
{
   datetime           ts;
   EAurumMarketRegime regime;
   double             atr;
   double             trend_strength;
   double             volatility_score;
   double             compression_score;
   double             expansion_score;
   double             momentum_score;
   bool               breakout_detected;
   bool               sweep_detected;
   int                session_id;
   double             confidence;
   ulong              replay_hash;
   int                secondary_regime;
   int                regime_confidence_permille;
};

struct SGovRegimeFeaturesV1
{
   double atr_ratio;
   double adx;
   double bb_width_rel;
   double ema21_slope_norm;
   double directional_persist;
   double range_expansion;
   double compression_density;
   double wick_dominance;
   double spread_anomaly;
   double session_vol_score;
   double momentum_persist;
   double swing_expansion;
   double mean_distance_dev;
   double hh_hl_score;
   double ll_lh_score;
   double breakout_pressure;
   double expansion_score;
   double prev_compression_hint;
};

struct SGovRegimeTransitionV1
{
   datetime           ts;
   int                from_reg;
   int                to_reg;
   ulong              post_bars;
   long               post_tox_proxy;
};

struct SGovRegimeStratCellV1
{
   int    trades;
   int    wins;
   long   profit_cents;
   int    max_dd_cents;
   int    stopouts;
};

struct SGovRegimeRuntimeStoreV1
{
   bool               valid;
   EAurumMarketRegime current_regime;
   EAurumMarketRegime prev_regime;
   datetime           last_bar_ts;
   ulong              total_bars;
   ulong              regime_hist[GOV_REGIME_AURUM_SLOT_COUNT_V1];
   ulong              transitions_total;
   int                bars_since_change;
   ulong              frozen_streak_max;

   SGovRegimeTelemetryV1 tel_ring[GOV_REGIME_TELEM_RING_V1];
   int                  tel_head;
   int                  tel_count;

   SGovRegimeTransitionV1 tr_ring[GOV_REGIME_TRANSITION_RING_V1];
   int                    tr_head;
   int                    tr_count;

   ulong month_regime_hits[12][GOV_REGIME_AURUM_SLOT_COUNT_V1];
   ulong month_signals[12];
   int   month_trades[12];
   long  month_net_cents[12];
   ulong month_bars[12];
   ulong month_conf_pm_sum[12];

   SGovRegimeStratCellV1 strat_regime[GOV_REGIME_STRAT_SLOTS_V1][GOV_REGIME_AURUM_SLOT_COUNT_V1];

   ulong pos_hash_keys[GOV_REGIME_POS_HASH_V1];
   int   pos_hash_reg[GOV_REGIME_POS_HASH_V1];

   bool  diversity_collapse;
   ulong diversity_collapse_hits;
   ulong post_transition_bars;
   long  post_transition_tox_accum;
};

inline SGovRegimeRuntimeStoreV1 g_gov_regime_store_v1;

inline int GovRegimeDsV1_RegimeSlot(const EAurumMarketRegime r)
{
   const int v = (int)r;
   if(v < 0 || v >= GOV_REGIME_AURUM_SLOT_COUNT_V1)
      return 0;
   return v;
}

inline void GovRegimeDsV1_Init(SGovRegimeRuntimeStoreV1 &s)
{
   s.valid = false;
   s.current_regime = AURUM_REGIME_UNKNOWN;
   s.prev_regime = AURUM_REGIME_UNKNOWN;
   s.last_bar_ts = 0;
   s.total_bars = 0;
   s.transitions_total = 0;
   s.bars_since_change = 0;
   s.frozen_streak_max = 0;
   s.tel_head = 0;
   s.tel_count = 0;
   s.tr_head = 0;
   s.tr_count = 0;
   s.diversity_collapse = false;
   s.diversity_collapse_hits = 0;
   s.post_transition_bars = 0;
   s.post_transition_tox_accum = 0;
   for(int i = 0; i < GOV_REGIME_AURUM_SLOT_COUNT_V1; i++)
      s.regime_hist[i] = 0;
   for(int m = 0; m < 12; m++) {
      s.month_signals[m] = 0;
      s.month_trades[m] = 0;
      s.month_net_cents[m] = 0;
      s.month_bars[m] = 0;
      s.month_conf_pm_sum[m] = 0;
      for(int r = 0; r < GOV_REGIME_AURUM_SLOT_COUNT_V1; r++)
         s.month_regime_hits[m][r] = 0;
   }
   for(int a = 0; a < GOV_REGIME_STRAT_SLOTS_V1; a++) {
      for(int b = 0; b < GOV_REGIME_AURUM_SLOT_COUNT_V1; b++) {
         s.strat_regime[a][b].trades = 0;
         s.strat_regime[a][b].wins = 0;
         s.strat_regime[a][b].profit_cents = 0;
         s.strat_regime[a][b].max_dd_cents = 0;
         s.strat_regime[a][b].stopouts = 0;
      }
   }
   for(int h = 0; h < GOV_REGIME_POS_HASH_V1; h++) {
      s.pos_hash_keys[h] = 0;
      s.pos_hash_reg[h] = 0;
   }
}

#endif // __AURUM_GOV_REGIME_DATASET_V1_MQH__
