//+------------------------------------------------------------------+
//| GovernanceRestrictionForensicsEngineV1.mqh                      |
//| PHASE 23.5 — observe-only aggregation + waterfall ring           |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RF_ENGINE_V1_MQH__
#define __AURUM_GOV_RF_ENGINE_V1_MQH__

#include "../../Core/Structures.mqh"
#include "GovernanceRestrictionForensicsDatasetV1.mqh"

inline int GovRfEngV1_ClampStageIdx(const int stage)
{
   if(stage < 1)
      return 1;
   if(stage > GOV_RF_STAGE_CT_V1 - 1)
      return GOV_RF_STAGE_CT_V1 - 1;
   return stage;
}

inline int GovRfEngV1_ClampVetoIdx(const int v)
{
   if(v < 0)
      return 0;
   if(v >= GOV_RF_VETO_CLASS_CT_V1)
      return GOV_RF_VETO_CLASS_CT_V1 - 1;
   return v;
}

inline int GovRfEngV1_MapSigReasonToVeto(const int sig_reason, const int deny_ct)
{
   switch(sig_reason) {
   case SIGNAL_REJECT_NO_CONSENSUS:
      return (int)GOV_RF_VETO_CONSENSUS_TOO_LOW_V1;
   case SIGNAL_REJECT_QUALITY_LOW:
      return (int)GOV_RF_VETO_VOLATILITY_FILTER_V1;
   case SIGNAL_REJECT_REQUIRE_TREND:
   case SIGNAL_REJECT_REQUIRE_KEYLEVEL:
   case SIGNAL_REJECT_REQUIRE_MOMENTUM:
      return (int)GOV_RF_VETO_VOLATILITY_FILTER_V1;
   case SIGNAL_REJECT_MAX_POSITIONS:
   case SIGNAL_REJECT_MAX_CONSEC_LOSSES:
      return (int)GOV_RF_VETO_RISK_BLOCK_V1;
   case SIGNAL_REJECT_RISK_HALT:
      if(deny_ct == (int)AS_CT_DENY_DD_LOCK)
         return (int)GOV_RF_VETO_DD_LOCK_V1;
      return (int)GOV_RF_VETO_RISK_BLOCK_V1;
   case SIGNAL_REJECT_TIME_FILTER:
      return (int)GOV_RF_VETO_SESSION_FILTER_V1;
   case SIGNAL_REJECT_SPREAD:
      return (int)GOV_RF_VETO_SPREAD_FILTER_V1;
   case SIGNAL_REJECT_MARKET_UPDATE_FAIL:
      return (int)GOV_RF_VETO_OTHER_V1;
   default:
      return (int)GOV_RF_VETO_UNKNOWN_V1;
   }
}

inline void GovRfEngV1_PushWaterfall(SGovRfStoreV1 &st,
                                    const datetime ts,
                                    const int stage,
                                    const int sig_reason,
                                    const int deny_ct,
                                    const int veto_class,
                                    const int strat_slot)
{
   const int wi = st.ring_wi;
   st.ring[wi].ts = ts;
   st.ring[wi].stage = stage;
   st.ring[wi].sig_reason = sig_reason;
   st.ring[wi].deny_ct = deny_ct;
   st.ring[wi].veto_class = GovRfEngV1_ClampVetoIdx(veto_class);
   st.ring[wi].strat_slot = strat_slot;
   st.ring_wi = (wi + 1) % GOV_RF_RING_CAP_V1;
   if(st.ring_count < GOV_RF_RING_CAP_V1)
      st.ring_count++;
}

inline void GovRfEngV1_OnReject(SGovRfStoreV1 &st,
                               const datetime ts,
                               const int stage,
                               const int sig_reason,
                               const int deny_ct,
                               const int strat_slot)
{
   const int sr = (sig_reason < 0 || sig_reason > 23) ? 0 : sig_reason;
   st.reject_by_sig_reason[sr]++;
   const int si = GovRfEngV1_ClampStageIdx(stage);
   st.reject_stage_counts[si]++;
   int veto = GovRfEngV1_MapSigReasonToVeto(sr, deny_ct);
   if(sr == SIGNAL_REJECT_NO_CONSENSUS && deny_ct == (int)GOV_RF_VETO_ECOLOGY_SUPPRESSION_V1)
      veto = (int)GOV_RF_VETO_ECOLOGY_SUPPRESSION_V1;
   if(sr == SIGNAL_REJECT_NO_CONSENSUS && deny_ct == (int)GOV_RF_VETO_REGIME_CONFLICT_V1)
      veto = (int)GOV_RF_VETO_REGIME_CONFLICT_V1;
   st.veto_class_counts[GovRfEngV1_ClampVetoIdx(veto)]++;
   GovRfEngV1_PushWaterfall(st, ts, stage, sr, deny_ct, veto, strat_slot);
}

inline void GovRfEngV1_OnBarOpen(SGovRfStoreV1 &st)
{
   if(!st.enabled)
      return;
   st.bars_observed++;
}

inline void GovRfEngV1_OnPipelineOpen(SGovRfStoreV1 &st)
{
   if(!st.enabled)
      return;
   st.bars_pipeline_entered++;
}

inline void GovRfEngV1_OnRegimeTick(SGovRfStoreV1 &st, const int regime_slot_prev, const int regime_slot_now)
{
   if(!st.enabled)
      return;
   if(regime_slot_prev >= 0 && regime_slot_now >= 0 && regime_slot_prev != regime_slot_now)
      st.regime_transition_bars++;
}

inline void GovRfEngV1_OnDdProbe(SGovRfStoreV1 &st,
                                 const double equity_dd_pct,
                                 const double balance,
                                 const double equity)
{
   if(!st.enabled)
      return;
   st.dd_probe_bars++;
   if(balance > st.peak_balance_obs)
      st.peak_balance_obs = balance;
   double bal_dd = 0.0;
   if(st.peak_balance_obs > 1e-8)
      bal_dd = (st.peak_balance_obs - balance) / st.peak_balance_obs * 100.0;
   if(bal_dd < 0.0)
      bal_dd = 0.0;
   const double div = MathAbs(equity_dd_pct - bal_dd);
   st.sum_dd_divergence_pct += div;
   if(div > st.max_dd_divergence_pct)
      st.max_dd_divergence_pct = div;
   double denom = (MathAbs(equity) > 1e-8 ? MathAbs(equity) : 1.0);
   const double fp = MathAbs(equity - balance) / denom * 1000.0;
   st.sum_floating_pressure_pm += fp;
   if(div >= 5.0 && equity_dd_pct >= 3.0 && bal_dd <= 1.0)
      st.dd_anomaly_bars++;
}

inline void GovRfEngV1_OnRiskSample(SGovRfStoreV1 &st, const bool can_trade, const int deny_ct)
{
   if(!st.enabled)
      return;
   st.risk_cantrade_samples++;
   if(can_trade) {
      if(st.risk_deny_streak_bars > 0)
         st.risk_thaw_bars_accum += st.risk_deny_streak_bars;
      st.risk_deny_streak_bars = 0;
      return;
   }
   st.risk_cantrade_denies++;
   st.bars_under_risk_denial++;
   st.risk_deny_streak_bars++;
   if(deny_ct == (int)AS_CT_DENY_DD_LOCK)
      st.risk_deny_dd_lock++;
   else if(deny_ct == (int)AS_CT_DENY_DAILY_LOSS)
      st.risk_deny_daily++;
   else if(deny_ct == (int)AS_CT_DENY_CONSEC)
      st.risk_deny_consec++;
   else
      st.risk_deny_other++;
}

inline void GovRfEngV1_OnEcologyFootprint(SGovRfStoreV1 &st,
                                         const int pre_buy,
                                         const int pre_sell,
                                         const int post_buy,
                                         const int post_sell,
                                         const int suppress_clears,
                                         const int throttle_ev,
                                         SignalResult &signals[])
{
   if(!st.enabled)
      return;
   st.ecology_suppress_clears_total += (ulong)MathMax(0, suppress_clears);
   st.ecology_throttle_events_total += (ulong)MathMax(0, throttle_ev);
   if(pre_buy > post_buy)
      st.ecology_buy_removed_bars++;
   if(pre_sell > post_sell)
      st.ecology_sell_removed_bars++;
   for(int i = 0; i < GOV_RF_STRAT_CT_V1; i++) {
      if(signals[i].signal == SIGNAL_NONE) {
         st.strat_starve_bars[i]++;
         if((ulong)st.strat_starve_bars[i] > st.strat_starve_peak[i])
            st.strat_starve_peak[i] = (ulong)st.strat_starve_bars[i];
      } else {
         st.strat_starve_bars[i] = 0;
      }
   }
}

inline void GovRfEngV1_OnConsensusEval(SGovRfStoreV1 &st,
                                      const datetime ts,
                                      const int base_min,
                                      const int eff_min,
                                      const int buy_v,
                                      const int sell_v,
                                      const ENUM_SIGNAL consensus,
                                      const int ecology_suppress_clears)
{
   if(!st.enabled)
      return;
   st.consensus_attempts++;
   st.last_base_min_consensus = base_min;
   st.last_eff_min_consensus = eff_min;
   const int hi = eff_min;
   const int idx = (hi < 1) ? 0 : ((hi > 8) ? 8 : (hi - 1));
   st.hist_eff_min_consensus[idx]++;

   st.sum_buy_votes += (ulong)buy_v;
   st.sum_sell_votes += (ulong)sell_v;
   st.sum_none_votes += (ulong)MathMax(0, GOV_RF_STRAT_CT_V1 - buy_v - sell_v);

   if(consensus != SIGNAL_NONE) {
      st.consensus_passes++;
      st.bars_with_executable_consensus++;
      return;
   }
   st.consensus_failures++;
   int veto = (int)GOV_RF_VETO_CONSENSUS_TOO_LOW_V1;
   int deny_tag = 0;
   const int mx = MathMax(buy_v, sell_v);
   if(buy_v >= eff_min && sell_v >= eff_min) {
      veto = (int)GOV_RF_VETO_REGIME_CONFLICT_V1;
      deny_tag = (int)GOV_RF_VETO_REGIME_CONFLICT_V1;
      st.consensus_split_brain_bars++;
   } else if(mx < eff_min) {
      veto = (int)GOV_RF_VETO_CONSENSUS_TOO_LOW_V1;
   } else if(mx == 0 && ecology_suppress_clears > 0) {
      veto = (int)GOV_RF_VETO_ECOLOGY_SUPPRESSION_V1;
      deny_tag = (int)GOV_RF_VETO_ECOLOGY_SUPPRESSION_V1;
   }
   st.veto_class_counts[GovRfEngV1_ClampVetoIdx(veto)]++;
   GovRfEngV1_PushWaterfall(st, ts, (int)GOV_RF_STAGE_CONSENSUS_V1, SIGNAL_REJECT_NO_CONSENSUS, deny_tag, veto, -1);
   st.reject_by_sig_reason[SIGNAL_REJECT_NO_CONSENSUS]++;
   st.reject_stage_counts[GovRfEngV1_ClampStageIdx((int)GOV_RF_STAGE_CONSENSUS_V1)]++;
}

inline void GovRfEngV1_OnLostToRiskHalt(SGovRfStoreV1 &st)
{
   if(!st.enabled)
      return;
   st.lost_opportunities_risk_halt++;
}

inline void GovRfEngV1_OnTradeOpened(SGovRfStoreV1 &st)
{
   if(!st.enabled)
      return;
   st.trade_open_success++;
}

inline void GovRfEngV1_RecomputeRootCauseVector(SGovRfStoreV1 &st)
{
   const double bars = (double)MathMax(1UL, st.bars_observed);
   const double cfail = (double)st.consensus_failures;
   const double catt = (double)MathMax(1UL, st.consensus_attempts);
   const double rden = (double)st.risk_cantrade_denies / (double)MathMax(1UL, st.risk_cantrade_samples);
   const double eco = (double)st.ecology_suppress_clears_total / bars;
   const double ddA = (double)st.dd_anomaly_bars / bars;
   const double riskLost = (double)st.lost_opportunities_risk_halt / (double)MathMax(1UL, st.bars_with_executable_consensus + st.lost_opportunities_risk_halt);

   double s_cons = 1000.0 * (cfail / catt);
   double s_risk = 1000.0 * rden;
   double s_eco = 1000.0 * eco;
   double s_dd = 1000.0 * ddA;
   double s_reg = (st.regime_transition_bars > 1000) ? 200.0 : (double)st.regime_transition_bars / bars * 500.0;
   double s_split = 1000.0 * (double)st.consensus_split_brain_bars / catt;

   struct SRnk {
      int   id;
      double sc;
   };
   SRnk a[6];
   a[0].id = 1;
   a[0].sc = s_risk + riskLost * 400.0;
   a[1].id = 2;
   a[1].sc = s_cons;
   a[2].id = 3;
   a[2].sc = s_eco;
   a[3].id = 4;
   a[3].sc = s_dd;
   a[4].id = 5;
   a[4].sc = s_reg + s_split;
   a[5].id = 6;
   a[5].sc = (double)st.reject_by_sig_reason[SIGNAL_REJECT_QUALITY_LOW] / bars * 800.0;

   for(int i = 0; i < 6; i++) {
      for(int j = i + 1; j < 6; j++) {
         if(a[j].sc > a[i].sc) {
            SRnk t = a[i];
            a[i] = a[j];
            a[j] = t;
         }
      }
   }
   st.last_rc_rank1 = a[0].id;
   st.last_rc_rank2 = a[1].id;
   st.last_rc_rank3 = a[2].id;
   st.last_rc_score1_pm = a[0].sc;
   st.last_rc_score2_pm = a[1].sc;
   st.last_rc_score3_pm = a[2].sc;
}

#endif // __AURUM_GOV_RF_ENGINE_V1_MQH__
