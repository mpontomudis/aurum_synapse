//+------------------------------------------------------------------+
//| GovernanceRegimeEngineV1.mqh                                     |
//| PHASE 22 — feature extraction (replay-safe, bar series only)     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_REGIME_ENGINE_V1_MQH__
#define __AURUM_GOV_REGIME_ENGINE_V1_MQH__

#include "../../Core/Structures.mqh"
#include "GovernanceRegimeDatasetV1.mqh"

inline double GovRegimeEngV1_SafeDiv(const double a, const double b)
{
   if(MathAbs(b) < 1e-12)
      return 0.0;
   return a / b;
}

inline void GovRegimeEngV1_BuildFeatures(const MarketState &st,
                                         const MqlRates &rates[],
                                         const int n_rates,
                                         const double spread_points,
                                         const double prev_comp_hint,
                                         SGovRegimeFeaturesV1 &f)
{
   f.atr_ratio = st.atrRatio;
   f.adx = st.adx;
   f.bb_width_rel = GovRegimeEngV1_SafeDiv(st.bbUpper - st.bbLower, st.bbMiddle);
   f.ema21_slope_norm = 0.0;
   f.directional_persist = 0.0;
   f.range_expansion = 0.0;
   f.compression_density = 0.0;
   f.wick_dominance = 0.0;
   f.spread_anomaly = 0.0;
   f.session_vol_score = 0.35;
   f.momentum_persist = 0.0;
   f.swing_expansion = 0.0;
   f.mean_distance_dev = 0.0;
   f.hh_hl_score = 0.0;
   f.ll_lh_score = 0.0;
   f.breakout_pressure = 0.0;
   f.expansion_score = 0.0;
   f.prev_compression_hint = prev_comp_hint;

   if(st.session == SESSION_OVERLAP)
      f.session_vol_score = 0.85;
   else if(st.session == SESSION_LONDON || st.session == SESSION_NEWYORK)
      f.session_vol_score = 0.65;
   else
      f.session_vol_score = 0.4;

   if(n_rates >= 24) {
      double ema_prev = 0.0;
      int got = 0;
      for(int k = 3; k <= 8; k++) {
         double c = (double)rates[k].close;
         ema_prev += c;
         got++;
      }
      ema_prev = (got > 0) ? ema_prev / (double)got : st.ema21;
      const double slope = st.ema21 - ema_prev;
      f.ema21_slope_norm = GovRegimeEngV1_SafeDiv(MathAbs(slope), MathMax(st.atr14, _Point * 10.0));
      f.ema21_slope_norm = GovRegimeMathV1_Clamp01(f.ema21_slope_norm * 2.0);
   }

   if(n_rates >= 20) {
      double ranges[20];
      double sumr = 0.0;
      for(int i = 0; i < 20; i++) {
         const double hi = (double)rates[i].high;
         const double lo = (double)rates[i].low;
         ranges[i] = hi - lo;
         sumr += ranges[i];
      }
      const double avgr = sumr / 20.0;
      const double lastr = (double)rates[0].high - (double)rates[0].low;
      f.range_expansion = GovRegimeMathV1_Clamp01(GovRegimeEngV1_SafeDiv(lastr, MathMax(avgr, _Point * 5.0)) - 1.0);
      f.compression_density = GovRegimeMathV1_Clamp01(1.15 - GovRegimeEngV1_SafeDiv(lastr, MathMax(avgr, _Point * 5.0)));

      int same = 0;
      for(int j = 0; j < 12; j++) {
         const double o = (double)rates[j].open;
         const double c = (double)rates[j].close;
         const int sgn = (c > o) ? 1 : ((c < o) ? -1 : 0);
         const int sgn0 = ((double)rates[0].close > (double)rates[0].open) ? 1 : (((double)rates[0].close < (double)rates[0].open) ? -1 : 0);
         if(sgn != 0 && sgn == sgn0)
            same++;
      }
      f.directional_persist = GovRegimeMathV1_Clamp01((double)same / 12.0);

      double wsum = 0.0;
      double bsum = 0.0;
      for(int w = 0; w < 6; w++) {
         const double o = (double)rates[w].open;
         const double c = (double)rates[w].close;
         const double hi = (double)rates[w].high;
         const double lo = (double)rates[w].low;
         const double body = MathAbs(c - o);
         const double wick = (hi - lo) - body;
         wsum += MathMax(0.0, wick);
         bsum += MathMax(_Point, body);
      }
      f.wick_dominance = GovRegimeMathV1_Clamp01(GovRegimeEngV1_SafeDiv(wsum, bsum * 3.0));

      double hh = 0.0;
      double ll = 0.0;
      for(int si = 1; si < 10; si++) {
         if(rates[si].high < rates[si + 1].high && rates[si - 1].high < rates[si].high)
            hh += 1.0;
         if(rates[si].low > rates[si + 1].low && rates[si - 1].low > rates[si].low)
            ll += 1.0;
      }
      f.hh_hl_score = GovRegimeMathV1_Clamp01(hh / 6.0);
      f.ll_lh_score = GovRegimeMathV1_Clamp01(ll / 6.0);

      double swing = 0.0;
      for(int e = 0; e < 8; e++) {
         swing += MathAbs((double)rates[e].high - (double)rates[e + 4].low);
      }
      f.swing_expansion = GovRegimeMathV1_Clamp01(GovRegimeEngV1_SafeDiv(swing, MathMax(avgr * 8.0, _Point * 40.0)));

      double mean20 = 0.0;
      for(int m = 0; m < 20; m++)
         mean20 += (double)rates[m].close;
      mean20 /= 20.0;
      f.mean_distance_dev = GovRegimeMathV1_Clamp01(GovRegimeEngV1_SafeDiv(MathAbs((double)rates[0].close - mean20), MathMax(st.atr14, _Point * 10.0)));

      double macd_persist = 0.0;
      for(int p = 0; p < 8; p++) {
         const double c = (double)rates[p].close;
         const double o = (double)rates[p].open;
         if((st.macdMain > st.macdSignal && c > o) || (st.macdMain < st.macdSignal && c < o))
            macd_persist += 1.0;
      }
      f.momentum_persist = GovRegimeMathV1_Clamp01(macd_persist / 8.0);
   }

   f.expansion_score = GovRegimeMathV1_Clamp01(0.55 * f.range_expansion + 0.45 * GovRegimeMathV1_Clamp01(f.atr_ratio - 1.0));
   f.breakout_pressure = GovRegimeMathV1_Clamp01(f.expansion_score * (0.45 + 0.55 * f.directional_persist));

   const double pt_spread = spread_points;
   const double norm_sp = GovRegimeEngV1_SafeDiv(pt_spread * _Point, MathMax(st.atr14, _Point * 10.0));
   f.spread_anomaly = GovRegimeMathV1_Clamp01(norm_sp * 3.0);
}

#include "GovernanceRegimeClassifierV1.mqh"

inline void GovRegimeEngV1_Step(const MarketState &st,
                                 const MqlRates &rates[],
                                 const int n_rates,
                                 const double spread_points,
                                 const double prev_comp_hint,
                                 EAurumMarketRegime &reg,
                                 double &conf,
                                 EAurumMarketRegime &sec_reg,
                                 int &conf_pm,
                                 SGovRegimeFeaturesV1 &feat)
{
   GovRegimeEngV1_BuildFeatures(st, rates, n_rates, spread_points, prev_comp_hint, feat);
   GovRegimeClassV1_ClassifyFull(feat, reg, conf, sec_reg, conf_pm);
}

#endif // __AURUM_GOV_REGIME_ENGINE_V1_MQH__
