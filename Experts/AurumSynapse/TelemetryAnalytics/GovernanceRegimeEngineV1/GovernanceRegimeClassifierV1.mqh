//+------------------------------------------------------------------+
//| GovernanceRegimeClassifierV1.mqh                                |
//| PHASE 22 — deterministic regime classification (no ML / RNG)    |
//+------------------------------------------------------------------+
// Unique guard: EvidenceIntegrationV1 also ships GovernanceRegimeClassifierV1.mqh
// with __AURUM_GOV_REGIME_CLASSIFIER_V1_MQH__ — that file must not suppress this one.
#ifndef __AURUM_GOV_MARKET_REGIME_CLASSIFIER_P22_V1_MQH__
#define __AURUM_GOV_MARKET_REGIME_CLASSIFIER_P22_V1_MQH__

#include "GovernanceRegimeDatasetV1.mqh"

inline void GovRegimeClassV1_Classify(const SGovRegimeFeaturesV1 &f,
                                      EAurumMarketRegime &out_reg,
                                      double &out_conf)
{
   const double atr_elev = GovRegimeMathV1_Clamp01((f.atr_ratio - 1.0) * 0.75);
   const double adx_n = GovRegimeMathV1_Clamp01(f.adx / 55.0);
   const double trend_core = GovRegimeMathV1_Clamp01(0.55 * adx_n + 0.45 * f.directional_persist);
   const double comp = GovRegimeMathV1_Clamp01(f.compression_density);
   const double expn = GovRegimeMathV1_Clamp01(0.55 * f.range_expansion + 0.45 * GovRegimeMathV1_Clamp01(f.atr_ratio - 1.0));
   const double wick = GovRegimeMathV1_Clamp01(f.wick_dominance);
   const double spr = GovRegimeMathV1_Clamp01(f.spread_anomaly);
   const double meanex = GovRegimeMathV1_Clamp01(f.mean_distance_dev);
   const double brk = GovRegimeMathV1_Clamp01(f.breakout_pressure);

   out_reg = AURUM_REGIME_UNKNOWN;
   out_conf = 0.0;

   if(wick > 0.68 && f.range_expansion > 0.4 && f.directional_persist < 0.45) {
      out_reg = AURUM_REGIME_LIQUIDITY_SWEEP;
      out_conf = GovRegimeMathV1_Clamp01(0.55 + 0.25 * wick + 0.15 * f.range_expansion);
      return;
   }

   if(comp > 0.72 && atr_elev < 0.28 && adx_n < 0.38) {
      if(f.hh_hl_score > 0.08 && f.ll_lh_score < 0.12) {
         out_reg = AURUM_REGIME_ACCUMULATION;
         out_conf = GovRegimeMathV1_Clamp01(0.5 + 0.35 * comp);
         return;
      }
      if(f.ll_lh_score > 0.08 && f.hh_hl_score < 0.12) {
         out_reg = AURUM_REGIME_ACCUMULATION;
         out_conf = GovRegimeMathV1_Clamp01(0.48 + 0.32 * comp);
         return;
      }
   }

   if(brk > 0.58 && f.prev_compression_hint > 0.45 && expn > 0.45) {
      out_reg = AURUM_REGIME_BREAKOUT;
      out_conf = GovRegimeMathV1_Clamp01(0.52 + 0.22 * brk + 0.18 * expn);
      return;
   }

   if(atr_elev > 0.62 && (expn > 0.55 || spr > 0.55)) {
      out_reg = AURUM_REGIME_HIGH_VOL;
      out_conf = GovRegimeMathV1_Clamp01(0.5 + 0.25 * atr_elev + 0.15 * spr);
      return;
   }

   if(atr_elev < 0.22 && comp > 0.5 && expn < 0.35) {
      out_reg = AURUM_REGIME_LOW_VOL;
      out_conf = GovRegimeMathV1_Clamp01(0.48 + 0.3 * comp + 0.12 * (1.0 - atr_elev));
      return;
   }

   if(meanex > 0.62 && wick > 0.48) {
      out_reg = AURUM_REGIME_MEAN_REVERSION;
      out_conf = GovRegimeMathV1_Clamp01(0.5 + 0.22 * meanex + 0.18 * wick);
      return;
   }

   if(trend_core > 0.58 && (f.hh_hl_score > 0.18 || f.ll_lh_score > 0.18)) {
      out_reg = AURUM_REGIME_TRENDING;
      out_conf = GovRegimeMathV1_Clamp01(0.52 + 0.28 * trend_core);
      return;
   }

   if(expn > 0.62 && atr_elev > 0.35) {
      out_reg = AURUM_REGIME_VOLATILITY_EXPANSION;
      out_conf = GovRegimeMathV1_Clamp01(0.48 + 0.3 * expn);
      return;
   }

   if(comp > 0.58 && expn < 0.38) {
      out_reg = AURUM_REGIME_VOLATILITY_COMPRESSION;
      out_conf = GovRegimeMathV1_Clamp01(0.46 + 0.32 * comp);
      return;
   }

   if(atr_elev > 0.45 && wick > 0.42 && meanex < 0.45) {
      out_reg = AURUM_REGIME_DISTRIBUTION;
      out_conf = GovRegimeMathV1_Clamp01(0.45 + 0.22 * atr_elev + 0.18 * wick);
      return;
   }

   if(adx_n < 0.42 && f.directional_persist < 0.42 && comp < 0.55) {
      out_reg = AURUM_REGIME_RANGING;
      out_conf = GovRegimeMathV1_Clamp01(0.44 + 0.26 * (1.0 - trend_core));
      return;
   }

   if(adx_n < 0.35 && comp > 0.42) {
      out_reg = AURUM_REGIME_RANGING;
      out_conf = GovRegimeMathV1_Clamp01(0.42 + 0.22 * comp);
      return;
   }

   out_reg = AURUM_REGIME_RANGING;
   out_conf = 0.35;
}

#endif // __AURUM_GOV_MARKET_REGIME_CLASSIFIER_P22_V1_MQH__
