//+------------------------------------------------------------------+
//| AdaptiveThawStabilizationEngineV1.mqh                          |
//| PHASE 23.7 — observe-only thaw / decay / recovery scoring       |
//+------------------------------------------------------------------+
#ifndef __AURUM_ATS_ENGINE_V1_MQH__
#define __AURUM_ATS_ENGINE_V1_MQH__

#include "../RiskLockIntelligenceV1/RiskLockIntelligenceEngineV1.mqh"
#include "../GovernanceRestrictionForensicsV1/GovernanceRestrictionForensicsDatasetV1.mqh"
#include "../GovernanceEcologyEngineV1/GovernanceEcologyDatasetV1.mqh"
#include "AdaptiveThawStabilizationDatasetV1.mqh"

inline double GovAtsEngV1_Clamp01(const double x)
{
   return MathMax(0.0, MathMin(1.0, x));
}

inline double GovAtsEngV1_Clamp1000(const double x)
{
   return MathMax(0.0, MathMin(1000.0, x));
}

inline int GovAtsEngV1_ClassifyThawState(const double thaw_conf_pm,
                                        const double relapse_pm,
                                        const bool can_trade,
                                        const bool lock_active,
                                        const double eq_dd,
                                        const double eq_dd_prev)
{
   if(lock_active && !can_trade)
      return (int)GOV_ATS_THAW_NONE_V1;
   const double rel01 = GovAtsEngV1_Clamp01(relapse_pm / 1000.0);
   if(can_trade && rel01 > 0.55 && thaw_conf_pm < 420.0)
      return (int)GOV_ATS_THAW_RELAPSE_RISK_V1;
   if(can_trade && eq_dd_prev > 1e-6 && eq_dd > eq_dd_prev * 1.18 && eq_dd > 4.5)
      return (int)GOV_ATS_THAW_FALSE_RECOVERY_V1;
   if(thaw_conf_pm >= 720.0)
      return (int)GOV_ATS_THAW_HEALTHY_V1;
   if(thaw_conf_pm >= 480.0)
      return (int)GOV_ATS_THAW_STABILIZING_V1;
   if(thaw_conf_pm >= 220.0)
      return (int)GOV_ATS_THAW_WEAK_V1;
   return (int)GOV_ATS_THAW_NONE_V1;
}

inline int GovAtsEngV1_ClassifyLockDecay(const bool lock_active, const ulong lock_age_bars)
{
   if(!lock_active)
      return (int)GOV_ATS_DECAY_HEALTHY_V1;
   if(lock_age_bars > 320UL)
      return (int)GOV_ATS_DECAY_PARALYSIS_LOOP_V1;
   if(lock_age_bars > 140UL)
      return (int)GOV_ATS_DECAY_STUCK_V1;
   if(lock_age_bars > 36UL)
      return (int)GOV_ATS_DECAY_SLOW_V1;
   return (int)GOV_ATS_DECAY_HEALTHY_V1;
}

inline int GovAtsEngV1_ClassifyFloatV2(const double fp_pct,
                                      const double avg_fp,
                                      const double eq_dd)
{
   if(eq_dd >= 14.0 && fp_pct >= 2.5)
      return (int)GOV_ATS_FLOAT2_COLLAPSE_V1;
   if(fp_pct >= 5.5 || (avg_fp > 1e-6 && fp_pct > avg_fp * 2.8 && fp_pct >= 3.2))
      return (int)GOV_ATS_FLOAT2_STRUCTURAL_V1;
   if(avg_fp > 1e-6 && fp_pct > avg_fp * 1.85 && eq_dd < 3.8)
      return (int)GOV_ATS_FLOAT2_TEMP_SPIKE_V1;
   if(fp_pct >= 1.35)
      return (int)GOV_ATS_FLOAT2_ELEVATED_V1;
   return (int)GOV_ATS_FLOAT2_NORMAL_V1;
}

inline int GovAtsEngV1_ClassifyRecoveryState(const double eq_dd, const double recovery_ema)
{
   if(eq_dd >= 11.0)
      return (int)GOV_ATS_REC_COLLAPSING_V1;
   if(recovery_ema < -0.035)
      return (int)GOV_ATS_REC_STALLED_V1;
   if(recovery_ema > 0.045)
      return (int)GOV_ATS_REC_RECOVERING_V1;
   if(recovery_ema > 0.012)
      return (int)GOV_ATS_REC_STABILIZING_V1;
   if(eq_dd < 2.2 && recovery_ema >= -0.01)
      return (int)GOV_ATS_REC_HEALTHY_V1;
   return (int)GOV_ATS_REC_STALLED_V1;
}

inline int GovAtsEngV1_ClassifyParalysis(const double paralysis_index_pm,
                                        const double overreaction_pm)
{
   if(paralysis_index_pm >= 780.0 || overreaction_pm >= 700.0)
      return (int)GOV_ATS_PAR_PARALYZED_V1;
   if(paralysis_index_pm >= 520.0 || overreaction_pm >= 480.0)
      return (int)GOV_ATS_PAR_OVERDEFENSIVE_V1;
   if(paralysis_index_pm >= 260.0)
      return (int)GOV_ATS_PAR_ELEVATED_V1;
   return (int)GOV_ATS_PAR_HEALTHY_V1;
}

inline int GovAtsEngV1_RfMaxStarveBars(const SGovRfStoreV1 &rf)
{
   int mx = 0;
   for(int i = 0; i < GOV_RF_STRAT_CT_V1; i++) {
      if(rf.strat_starve_bars[i] > mx)
         mx = rf.strat_starve_bars[i];
   }
   return mx;
}

inline ulong GovAtsEngV1_EcologyParticipationSum(const SGovEcologyStoreV1 &eco)
{
   ulong s = 0;
   for(int i = 0; i < GOV_ECO_STRAT_COUNT_V1; i++)
      s += eco.s[i].bars_participation;
   return s;
}

inline void GovAtsEngV1_OnBar(SGovAtsStoreV1 &a,
                             const SGovRliStoreV1 &rli,
                             const SGovRfStoreV1 &rf,
                             const SGovEcologyStoreV1 &eco,
                             const ulong bar_seq,
                             const double eq_dd,
                             const double balance,
                             const double equity,
                             const double spread_pts,
                             const double atr_ratio,
                             const bool can_trade)
{
   if(!a.enabled)
      return;
   a.bars_observed++;

   const double fp_pct = GovRliEngV1_FloatingPressurePct(balance, equity);
   const double avg_fp = (rli.bars_observed > 0UL) ? (rli.sum_floating_pressure / (double)rli.bars_observed) : fp_pct;
   const double fp_norm = (avg_fp > 1e-6) ? (fp_pct / avg_fp) : 1.0;
   const double float_vel = (rli.float_stress_bars + rli.float_recovery_bars > 0UL)
                            ? ((double)rli.float_recovery_bars - (double)rli.float_stress_bars) /
                              (double)(rli.float_stress_bars + rli.float_recovery_bars + 1UL)
                            : 0.0;

   const double thaw_rate = (rli.thaw_attempts > 0UL) ? ((double)rli.thaw_successes / (double)rli.thaw_attempts) : 0.0;
   const double relapse_ratio = (rli.thaw_successes > 0UL)
                                 ? ((double)rli.thaw_interruptions / (double)rli.thaw_successes)
                                 : ((rli.thaw_interruptions > 0UL) ? 2.0 : 0.0);
   a.last_thaw_relapse_pm = GovAtsEngV1_Clamp1000(relapse_ratio * 420.0);
   a.last_thaw_stability_pm = GovAtsEngV1_Clamp1000(1000.0 - a.last_thaw_relapse_pm * 0.85);
   const double thaw_momentum = GovAtsEngV1_Clamp01((double)rli.float_recovery_bars / (double)(rli.float_stress_bars + 12UL));
   const double surv_boost = GovAtsEngV1_Clamp01(1.0 - (double)rli.bars_starvation_overlap / (double)(rli.bars_observed + 1UL));
   a.last_thaw_confidence_pm = GovAtsEngV1_Clamp1000(
                                  320.0 * thaw_rate + 240.0 * thaw_momentum + 220.0 * surv_boost + 220.0 * GovAtsEngV1_Clamp01(1.0 - relapse_ratio * 0.5));

   const ulong lock_age = (rli.lock_active && bar_seq >= rli.active_lock_bar0) ? (bar_seq - rli.active_lock_bar0 + 1UL) : 0UL;
   a.lock_age_bars_last = lock_age;
   a.last_decay_class = GovAtsEngV1_ClassifyLockDecay(rli.lock_active, lock_age);
   a.last_lock_decay_rate_pm = (lock_age > 0UL) ? GovAtsEngV1_Clamp1000(900.0 / MathSqrt((double)lock_age)) : 0.0;

   a.last_float_norm_pm = GovAtsEngV1_Clamp1000(fp_norm * 280.0);
   a.last_float_recovery_vel_pm = GovAtsEngV1_Clamp1000(500.0 + 500.0 * float_vel);
   a.last_float_v2_class = GovAtsEngV1_ClassifyFloatV2(fp_pct, avg_fp, eq_dd);

   const double vol_adj = eq_dd * MathMax(0.65, atr_ratio);
   a.last_vol_adj_dd = vol_adj;
   a.last_spread_adj_dd = vol_adj * (1.0 + spread_pts / 95.0);
   a.last_dd_context_pm = GovAtsEngV1_Clamp1000(a.last_spread_adj_dd * 55.0 + (rli.lock_active ? (double)lock_age * 0.35 : 0.0));

   const double dd_delta = a.prev_eq_dd - eq_dd;
   a.recovery_ema = 0.14 * dd_delta + 0.86 * a.recovery_ema;
   a.last_recovery_momentum_pm = GovAtsEngV1_Clamp1000(500.0 + 4800.0 * a.recovery_ema + (dd_delta > 0.0 ? 120.0 : -40.0));
   a.last_recovery_state = GovAtsEngV1_ClassifyRecoveryState(eq_dd, a.recovery_ema);

   const double deny_ratio = (rf.bars_observed > 0UL) ? ((double)rf.bars_under_risk_denial / (double)rf.bars_observed) : 0.0;
   const int mx_starve = GovAtsEngV1_RfMaxStarveBars(rf);
   const double stress_per_bar = (rli.bars_observed > 0UL) ? ((double)rli.governance_stress_accum / (double)rli.bars_observed) : 0.0;
   a.last_defensive_overreaction_pm = GovAtsEngV1_Clamp1000(
                                         (rli.thaw_attempts > 0UL ? (double)rli.thaw_interruptions / (double)rli.thaw_attempts : 0.0) * 620.0
                                         + (rf.bars_observed > 0UL ? (double)rf.risk_cantrade_denies / (double)rf.bars_observed : 0.0) * 180.0);
   a.last_paralysis_index_pm = GovAtsEngV1_Clamp1000(
                                  1000.0 * GovAtsEngV1_Clamp01(deny_ratio * 0.42 + GovAtsEngV1_Clamp01((double)mx_starve / 420.0) * 0.33 + GovAtsEngV1_Clamp01(stress_per_bar / 6.0) * 0.35));
   a.last_paralysis_state = GovAtsEngV1_ClassifyParalysis(a.last_paralysis_index_pm, a.last_defensive_overreaction_pm);

   ulong bars_since_exec = 0;
   if(rli.last_exec_bar_idx > 0UL && bar_seq > rli.last_exec_bar_idx)
      bars_since_exec = bar_seq - rli.last_exec_bar_idx;
   else if(rli.bars_observed > 0UL)
      bars_since_exec = rli.bars_observed;
   a.last_bars_since_exec_hint = bars_since_exec;
   const double open_rate = (rf.bars_observed > 0UL) ? ((double)rf.trade_open_success / (double)rf.bars_observed) : 0.0;
   a.last_exec_continuity_pm = GovAtsEngV1_Clamp1000(open_rate * 820.0 + 180.0 * GovAtsEngV1_Clamp01(1.0 - (double)bars_since_exec / 600.0));

   const ulong eco_sum = GovAtsEngV1_EcologyParticipationSum(eco);
   const long eco_delta = (long)eco_sum - (long)a.prev_ecology_part_sum;
   a.prev_ecology_part_sum = eco_sum;
   a.last_ecology_recovery_pm = GovAtsEngV1_Clamp1000((double)eco_delta * 90.0 + (double)eco.ecology_diversity_score_pm * 0.45 + (double)eco.last_bar_suppress_clears * 18.0);
   a.last_suppression_decay_pm = GovAtsEngV1_Clamp1000((double)eco.last_bar_suppress_clears * 55.0 + (double)eco.last_bar_throttle_events * 22.0);

   a.last_stress_accum_pm = GovAtsEngV1_Clamp1000(stress_per_bar * 95.0);
   a.last_stress_decay_pm = can_trade ? 220.0 : 70.0;
   a.last_nervous_resilience_pm = GovAtsEngV1_Clamp1000(620.0 + 0.45 * a.last_stress_decay_pm - 0.38 * a.last_paralysis_index_pm);

   a.last_thaw_state = GovAtsEngV1_ClassifyThawState(a.last_thaw_confidence_pm, a.last_thaw_relapse_pm, can_trade, rli.lock_active, eq_dd, a.prev_eq_dd);

   const int ts = (a.last_thaw_state >= 0 && a.last_thaw_state < GOV_ATS_THAW_STATE_CT_V1) ? a.last_thaw_state : 0;
   a.thaw_state_hist[ts]++;
   const int dc = (a.last_decay_class >= 0 && a.last_decay_class < GOV_ATS_DECAY_CT_V1) ? a.last_decay_class : 0;
   a.decay_hist[dc]++;
   const int fc = (a.last_float_v2_class >= 0 && a.last_float_v2_class < GOV_ATS_FLOAT_V2_CT_V1) ? a.last_float_v2_class : 0;
   a.float_v2_hist[fc]++;
   const int rc = (a.last_recovery_state >= 0 && a.last_recovery_state < GOV_ATS_RECOVERY_CT_V1) ? a.last_recovery_state : 0;
   a.recovery_hist[rc]++;
   const int pc = (a.last_paralysis_state >= 0 && a.last_paralysis_state < GOV_ATS_PARALYSIS_CT_V1) ? a.last_paralysis_state : 0;
   a.paralysis_hist[pc]++;

   a.prev_eq_dd = eq_dd;
}

#endif // __AURUM_ATS_ENGINE_V1_MQH__
