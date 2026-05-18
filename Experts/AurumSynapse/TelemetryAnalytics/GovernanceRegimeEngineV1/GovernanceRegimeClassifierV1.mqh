//+------------------------------------------------------------------+
//| GovernanceRegimeClassifierV1.mqh                                |
//| PHASE 22 / 22A — deterministic multi-factor regime scoring        |
//+------------------------------------------------------------------+
// Unique guard: EvidenceIntegrationV1 also ships GovernanceRegimeClassifierV1.mqh
// with __AURUM_GOV_REGIME_CLASSIFIER_V1_MQH__ — that file must not suppress this one.
#ifndef __AURUM_GOV_MARKET_REGIME_CLASSIFIER_P22_V1_MQH__
#define __AURUM_GOV_MARKET_REGIME_CLASSIFIER_P22_V1_MQH__

#include "GovernanceRegimeDatasetV1.mqh"

inline void GovRegimeClassV1_ClassifyFull(const SGovRegimeFeaturesV1 &f,
                                          EAurumMarketRegime &out_reg,
                                          double &out_conf,
                                          EAurumMarketRegime &out_sec,
                                          int &out_conf_pm)
{
   const double atr_elev = GovRegimeMathV1_Clamp01((f.atr_ratio - 1.0) * 0.70);
   const double adx_n = GovRegimeMathV1_Clamp01(f.adx / 52.0);
   const double trend_core = GovRegimeMathV1_Clamp01(0.52 * adx_n + 0.48 * f.directional_persist);
   const double comp = GovRegimeMathV1_Clamp01(f.compression_density);
   const double expn = GovRegimeMathV1_Clamp01(0.52 * f.range_expansion + 0.48 * GovRegimeMathV1_Clamp01(f.atr_ratio - 1.0));
   const double wick = GovRegimeMathV1_Clamp01(f.wick_dominance);
   const double spr = GovRegimeMathV1_Clamp01(f.spread_anomaly);
   const double meanex = GovRegimeMathV1_Clamp01(f.mean_distance_dev);
   const double brk = GovRegimeMathV1_Clamp01(f.breakout_pressure);
   const double struct_max = GovRegimeMathV1_Clamp01(MathMax(f.hh_hl_score, f.ll_lh_score));
   const double ema_sl = GovRegimeMathV1_Clamp01(MathAbs(f.ema21_slope_norm));

   double sc[12];
   for(int i = 0; i < 12; i++)
      sc[i] = -10.0;

   sc[(int)AURUM_REGIME_TRENDING] = 0.30 * trend_core + 0.22 * struct_max + 0.16 * ema_sl + 0.14 * f.momentum_persist +
                                    0.12 * (1.0 - comp) + 0.06 * adx_n;
   if(trend_core < 0.34)
      sc[(int)AURUM_REGIME_TRENDING] -= 0.20;

   sc[(int)AURUM_REGIME_RANGING] = 0.28 * (1.0 - trend_core) + 0.24 * (1.0 - adx_n) + 0.22 * (1.0 - meanex) +
                                   0.16 * (1.0 - expn) + 0.10 * (1.0 - wick);

   sc[(int)AURUM_REGIME_HIGH_VOL] = 0.36 * atr_elev + 0.28 * expn + 0.18 * spr + 0.12 * wick + 0.06 * meanex;

   sc[(int)AURUM_REGIME_LOW_VOL] = 0.38 * (1.0 - atr_elev) + 0.30 * comp + 0.18 * (1.0 - expn) + 0.14 * (1.0 - spr);
   if(trend_core > 0.46)
      sc[(int)AURUM_REGIME_LOW_VOL] -= 0.14;
   if(struct_max > 0.22)
      sc[(int)AURUM_REGIME_LOW_VOL] -= 0.08;

   sc[(int)AURUM_REGIME_BREAKOUT] = 0.32 * brk + 0.26 * expn + 0.20 * GovRegimeMathV1_Clamp01(f.prev_compression_hint) +
                                   0.14 * atr_elev + 0.08 * (1.0 - wick * 0.5);

   sc[(int)AURUM_REGIME_MEAN_REVERSION] = 0.34 * meanex + 0.26 * wick + 0.20 * (1.0 - trend_core) +
                                         0.12 * f.swing_expansion + 0.08 * (1.0 - adx_n);

   sc[(int)AURUM_REGIME_LIQUIDITY_SWEEP] = 0.36 * wick + 0.24 * f.range_expansion + 0.22 * (1.0 - f.directional_persist) +
                                         0.12 * meanex + 0.06 * spr;

   sc[(int)AURUM_REGIME_ACCUMULATION] = 0.30 * comp + 0.24 * (1.0 - atr_elev) + 0.18 * struct_max +
                                       0.16 * (1.0 - expn) + 0.12 * GovRegimeMathV1_Clamp01(f.hh_hl_score + f.ll_lh_score);

   sc[(int)AURUM_REGIME_DISTRIBUTION] = 0.30 * atr_elev + 0.24 * wick + 0.20 * (1.0 - meanex * 0.5) +
                                      0.16 * expn + 0.10 * spr;

   sc[(int)AURUM_REGIME_VOLATILITY_EXPANSION] = 0.34 * expn + 0.28 * atr_elev + 0.20 * f.swing_expansion +
                                                0.12 * brk + 0.06 * (1.0 - comp);

   sc[(int)AURUM_REGIME_VOLATILITY_COMPRESSION] = 0.36 * comp + 0.28 * (1.0 - expn) + 0.20 * (1.0 - atr_elev) +
                                                  0.10 * (1.0 - brk) + 0.06 * f.session_vol_score;

   int best = (int)AURUM_REGIME_RANGING;
   for(int r = 1; r < 12; r++) {
      if(sc[r] > sc[best])
         best = r;
   }
   int second = 1;
   for(int r = 1; r < 12; r++) {
      if(r != best) {
         second = r;
         break;
      }
   }
   for(int r = 1; r < 12; r++) {
      if(r != best && sc[r] > sc[second])
         second = r;
   }
   const double mx = sc[best];
   const double mx2 = sc[second];

   if(mx < 0.12) {
      out_reg = AURUM_REGIME_RANGING;
      out_sec = AURUM_REGIME_LOW_VOL;
      out_conf = 0.22;
      out_conf_pm = 220;
      return;
   }

   out_reg = (EAurumMarketRegime)best;
   out_sec = (EAurumMarketRegime)second;
   const double sep = GovRegimeMathV1_Clamp01(mx - mx2);
   out_conf = GovRegimeMathV1_Clamp01(0.28 + 0.62 * sep + 0.10 * mx);
   out_conf_pm = (int)(1000.0 * out_conf);
   if(out_conf_pm < 120)
      out_conf_pm = 120;
   if(out_conf_pm > 990)
      out_conf_pm = 990;
}

inline void GovRegimeClassV1_Classify(const SGovRegimeFeaturesV1 &f,
                                     EAurumMarketRegime &out_reg,
                                     double &out_conf)
{
   EAurumMarketRegime sec = AURUM_REGIME_UNKNOWN;
   int pm = 0;
   GovRegimeClassV1_ClassifyFull(f, out_reg, out_conf, sec, pm);
}

#endif // __AURUM_GOV_MARKET_REGIME_CLASSIFIER_P22_V1_MQH__
