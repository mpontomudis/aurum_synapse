//+------------------------------------------------------------------+
//| RiskLockIntelligenceEngineV1.mqh                               |
//| PHASE 23.6 — observe-only lock/thaw / DD / floating analytics    |
//+------------------------------------------------------------------+
#ifndef __AURUM_RLI_ENGINE_V1_MQH__
#define __AURUM_RLI_ENGINE_V1_MQH__

#include "../../Core/Constants.mqh"
#include "RiskLockIntelligenceDatasetV1.mqh"

inline double GovRliEngV1_FloatingPressurePct(const double balance, const double equity)
{
   const double d = (MathAbs(equity) > 1e-8 ? MathAbs(equity) : 1.0);
   return MathAbs(equity - balance) / d * 100.0;
}

inline int GovRliEngV1_ClassifyLockOrigin(const int deny_detail,
                                         const int halt_reason,
                                         const double eq_dd,
                                         const double eq_dd_prev,
                                         const double fp_pct,
                                         const double spread_pts,
                                         const double atr_ratio,
                                         const int eco_suppress_prev,
                                         const int regime_slot,
                                         const int prev_regime_slot,
                                         const int consec_losses,
                                         const int max_spread_pts)
{
   if(deny_detail == (int)AS_CT_DENY_DD_LOCK || halt_reason == (int)HALT_DRAWDOWN)
      return (int)GOV_RLI_ORIG_DD_SPIKE_V1;
   if(eq_dd > 3.0 && eq_dd > eq_dd_prev * 1.2 && eq_dd_prev > 0.5)
      return (int)GOV_RLI_ORIG_DD_SPIKE_V1;
   if(fp_pct >= 2.2 && eq_dd < 2.5)
      return (int)GOV_RLI_ORIG_FLOATING_PRESSURE_V1;
   const int spr_lim = (max_spread_pts > 0 ? max_spread_pts : 30);
   if(spread_pts > (double)spr_lim * 1.35)
      return (int)GOV_RLI_ORIG_SPREAD_EXPANSION_V1;
   if(consec_losses >= 2 && deny_detail == (int)AS_CT_DENY_CONSEC)
      return (int)GOV_RLI_ORIG_EXEC_TOXICITY_V1;
   if(atr_ratio > 0.0 && atr_ratio < 0.38)
      return (int)GOV_RLI_ORIG_VOL_COLLAPSE_V1;
   if(eco_suppress_prev >= 3)
      return (int)GOV_RLI_ORIG_ECOLOGY_CASCADE_V1;
   if(prev_regime_slot >= 0 && regime_slot >= 0 && prev_regime_slot != regime_slot)
      return (int)GOV_RLI_ORIG_REGIME_INSTABILITY_V1;
   if(deny_detail == (int)AS_CT_DENY_DAILY_LOSS || deny_detail == (int)AS_CT_DENY_CONSEC)
      return (int)GOV_RLI_ORIG_RECOVERY_FAILURE_V1;
   return (int)GOV_RLI_ORIG_UNKNOWN_V1;
}

inline int GovRliEngV1_ClassifyFloatStress(const double fp_pct, const ulong float_streak)
{
   if(fp_pct < 0.35)
      return (int)GOV_RLI_FLOAT_MICRO_V1;
   if(fp_pct < 1.1)
      return (int)GOV_RLI_FLOAT_NORMAL_V1;
   if(fp_pct < 2.5 || float_streak < 8)
      return (int)GOV_RLI_FLOAT_ELEVATED_V1;
   if(fp_pct < 5.0)
      return (int)GOV_RLI_FLOAT_STRUCTURAL_V1;
   return (int)GOV_RLI_FLOAT_COLLAPSE_V1;
}

inline int GovRliEngV1_ClassifyDd(const double eq_dd,
                                 const double fp_pct,
                                 const double dd_velocity,
                                 const bool grid_on,
                                 const bool in_tester)
{
   if(in_tester && fp_pct > 8.0 && eq_dd < 1.0)
      return (int)GOV_RLI_DD_TESTER_ARTIFACT_V1;
   if(grid_on && fp_pct > 3.5)
      return (int)GOV_RLI_DD_GRID_V1;
   if(eq_dd >= 14.0 && fp_pct >= 2.0)
      return (int)GOV_RLI_DD_STRUCTURAL_V1;
   if(fp_pct > 4.0 && eq_dd < 6.0)
      return (int)GOV_RLI_DD_LIQUIDITY_V1;
   if(dd_velocity > 0.35)
      return (int)GOV_RLI_DD_VOLATILITY_V1;
   if(eq_dd < 1.2)
      return (int)GOV_RLI_DD_TRANSIENT_V1;
   return (int)GOV_RLI_DD_EXECUTION_V1;
}

inline int GovRliEngV1_ClassifyPersistence(const ulong lock_duration_bars)
{
   if(lock_duration_bars < 3)
      return (int)GOV_RLI_LP_HEALTHY_V1;
   if(lock_duration_bars < 24)
      return (int)GOV_RLI_LP_DEFENSIVE_V1;
   if(lock_duration_bars < 120)
      return (int)GOV_RLI_LP_OVEREXTENDED_V1;
   return (int)GOV_RLI_LP_PARALYSIS_V1;
}

inline void GovRliEngV1_PushRing(SGovRliStoreV1 &st, const SGovRliLockRecordV1 &rec)
{
   const int wi = st.ring_wi;
   st.ring[wi] = rec;
   st.ring_wi = (wi + 1) % GOV_RLI_RING_V1;
   if(st.ring_count < GOV_RLI_RING_V1)
      st.ring_count++;
}

inline void GovRliEngV1_OnBarPostCanTrade(SGovRliStoreV1 &st,
                                       const datetime ts,
                                       const ulong bar_idx,
                                       const bool can_trade,
                                       const int deny_detail,
                                       const int halt_reason,
                                       const double eq_dd,
                                       const double balance,
                                       const double equity,
                                       const double spread_pts,
                                       const double atr_ratio,
                                       const int regime_slot,
                                       const int eco_suppress_prev,
                                       const int consec_losses,
                                       const int max_spread_pts,
                                       const bool grid_on,
                                       const bool in_tester)
{
   if(!st.enabled)
      return;
   st.bars_observed++;
   const double fp = GovRliEngV1_FloatingPressurePct(balance, equity);
   st.sum_floating_pressure += fp;
   const double dd_vel = eq_dd - st.prev_eq_dd;
   const int dd_cls = GovRliEngV1_ClassifyDd(eq_dd, fp, dd_vel, grid_on, in_tester);
   if(dd_cls >= 0 && dd_cls < 8)
      st.dd_class_hist[dd_cls]++;

   if(fp >= 1.0) {
      st.float_streak_bars++;
      st.float_stress_bars++;
   } else {
      if(st.float_streak_bars > 0)
         st.float_recovery_bars++;
      st.float_streak_bars = 0;
   }

   if(!can_trade) {
      st.total_lock_bars++;
      st.governance_stress_accum++;
      st.bars_starvation_overlap++;
      const ulong starve = (st.last_exec_bar_idx > 0 && bar_idx > st.last_exec_bar_idx) ? (bar_idx - st.last_exec_bar_idx) : 0;
      if(starve > st.max_starvation_bars)
         st.max_starvation_bars = starve;
   }

   if(st.in_post_thaw_window) {
      st.bars_since_prev_thaw++;
      if(!can_trade && st.bars_since_prev_thaw <= (ulong)GOV_RLI_THAW_RELOCK_V1) {
         st.thaw_interruptions++;
         st.defensive_escalation_events++;
         st.in_post_thaw_window = false;
      } else if(st.bars_since_prev_thaw > (ulong)GOV_RLI_THAW_RELOCK_V1) {
         st.in_post_thaw_window = false;
      }
   }

   if(!can_trade && st.prev_can_trade) {
      st.lock_events++;
      st.lock_seq++;
      st.lock_active = true;
      st.active_lock_id = st.lock_seq;
      st.active_lock_bar0 = bar_idx;
      st.active_lock_t0 = ts;
      st.active_origin = GovRliEngV1_ClassifyLockOrigin(deny_detail, halt_reason, eq_dd, st.prev_eq_dd, fp, spread_pts, atr_ratio,
                                                      eco_suppress_prev, regime_slot, st.prev_regime_slot, consec_losses, max_spread_pts);
      st.active_regime0 = regime_slot;
      st.active_eq_dd0 = eq_dd;
      st.active_bal0 = balance;
      st.active_eq0 = equity;
      st.active_fp0 = fp;
      st.active_spread0 = spread_pts;
      st.active_atr0 = atr_ratio;
      st.active_eco_prev = eco_suppress_prev;
      st.active_deny0 = deny_detail;
      st.active_halt0 = halt_reason;
      const int oi = st.active_origin;
      if(oi >= 0 && oi < 9)
         st.lock_origin_hist[oi]++;
   } else if(can_trade && !st.prev_can_trade && st.lock_active) {
      st.thaw_attempts++;
      st.thaw_successes++;
      const ulong dur = (bar_idx > st.active_lock_bar0 ? (bar_idx - st.active_lock_bar0) : 1UL);
      st.thaw_duration_bars_sum += dur;
      const int pc = GovRliEngV1_ClassifyPersistence(dur);
      if(pc >= 0 && pc < 4)
         st.persist_class_hist[pc]++;
      SGovRliLockRecordV1 rec;
      rec.id = st.active_lock_id;
      rec.t0 = st.active_lock_t0;
      rec.t1 = ts;
      rec.bar0 = st.active_lock_bar0;
      rec.bar1 = bar_idx;
      rec.origin = st.active_origin;
      rec.regime_slot0 = st.active_regime0;
      rec.eq_dd0 = st.active_eq_dd0;
      rec.balance0 = st.active_bal0;
      rec.equity0 = st.active_eq0;
      rec.floating_pressure0 = st.active_fp0;
      rec.spread_pts0 = st.active_spread0;
      rec.atr_ratio0 = st.active_atr0;
      rec.ecology_suppress_prev = st.active_eco_prev;
      rec.deny_detail0 = st.active_deny0;
      rec.halt_reason0 = st.active_halt0;
      rec.duration_bars = dur;
      GovRliEngV1_PushRing(st, rec);
      st.lock_active = false;
      st.bars_since_prev_thaw = 0;
      st.in_post_thaw_window = true;
   }

   st.prev_can_trade = can_trade;
   st.prev_regime_slot = regime_slot;
   st.prev_eq_dd = eq_dd;
}

inline void GovRliEngV1_OnExecutionOpened(SGovRliStoreV1 &st, const ulong bar_idx)
{
   if(!st.enabled)
      return;
   st.last_exec_bar_idx = bar_idx;
}

inline void GovRliEngV1_OnBarEndStoreEco(SGovRliStoreV1 &st, const int eco_suppress_this_bar)
{
   if(!st.enabled)
      return;
   st.ecology_suppress_prev_bar = eco_suppress_this_bar;
}

#endif // __AURUM_RLI_ENGINE_V1_MQH__
