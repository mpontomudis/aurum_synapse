//+------------------------------------------------------------------+
//| GovernanceSignalForensicsIntegrationV1.mqh                      |
//| PHASE 21 — append-only runtime hooks (no execution mutation)     |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_FORENSICS_INTEGRATION_V1_MQH__
#define __AURUM_GOV_SIG_FORENSICS_INTEGRATION_V1_MQH__

#include "GovernanceSignalForensicsTelemetryV1.mqh"
#include "GovernanceSignalRejectReasonV1.mqh"
#include "../../Core/Structures.mqh"

inline void GovSigForensicsV1_ModuleInit(void)
{
   GovSigFoV1_Init(g_gov_sig_forensics_tel_v1);
}

inline void GovSigForensicsV1_MakeStubState(const ENUM_REGIME r, MarketState &out)
{
   ZeroMemory(out);
   out.regime = r;
   out.session = SESSION_ASIAN;
   out.atrRatio = 1.0;
}

inline int GovSigForensicsV1_VolBucket(const double atrRatio)
{
   if(atrRatio < 0.9)
      return 0;
   if(atrRatio < 1.1)
      return 1;
   if(atrRatio < 1.45)
      return 2;
   return 3;
}

inline int GovSigForensicsV1_DominantStratSlot8(const SignalResult &s0,
                                               const SignalResult &s1,
                                               const SignalResult &s2,
                                               const SignalResult &s3,
                                               const SignalResult &s4,
                                               const SignalResult &s5,
                                               const SignalResult &s6,
                                               const SignalResult &s7,
                                               const ENUM_SIGNAL cons)
{
   int besti = 0;
   double best = -1.0;
   if(s0.signal == cons && s0.strength > best) {
      best = s0.strength;
      besti = 0;
   }
   if(s1.signal == cons && s1.strength > best) {
      best = s1.strength;
      besti = 1;
   }
   if(s2.signal == cons && s2.strength > best) {
      best = s2.strength;
      besti = 2;
   }
   if(s3.signal == cons && s3.strength > best) {
      best = s3.strength;
      besti = 3;
   }
   if(s4.signal == cons && s4.strength > best) {
      best = s4.strength;
      besti = 4;
   }
   if(s5.signal == cons && s5.strength > best) {
      best = s5.strength;
      besti = 5;
   }
   if(s6.signal == cons && s6.strength > best) {
      best = s6.strength;
      besti = 6;
   }
   if(s7.signal == cons && s7.strength > best) {
      best = s7.strength;
      besti = 7;
   }
   return besti;
}

inline void GovSigForensicsV1_PushRecord(const datetime ts,
                                         const MarketState &st,
                                         const int strat_slot,
                                         const ENUM_SIGNAL consensus,
                                         const int qscore,
                                         const int gov_reject_mapped,
                                         const int final_state,
                                         const bool tr,
                                         const bool kl,
                                         const bool mo,
                                         const bool sp,
                                         const bool se,
                                         const bool rk,
                                         const bool cons_ok)
{
   SGovSignalRecordV1 rec;
   rec.signal_id = 0;
   rec.ts = ts;
   rec.strategy_id = strat_slot;
   rec.regime_id = GovSigFoV1_RegimeIndex(st.regime);
   rec.session_id = (int)st.session;
   rec.volatility_id = GovSigForensicsV1_VolBucket(st.atrRatio);
   rec.direction = (int)consensus;
   rec.quality_score = qscore;
   rec.trend_align = tr;
   rec.key_level_ok = kl;
   rec.momentum_ok = mo;
   rec.spread_ok = sp;
   rec.session_ok = se;
   rec.risk_ok = rk;
   rec.consensus_ok = cons_ok;
   rec.reject_reason = gov_reject_mapped;
   rec.final_state = final_state;
   GovSigLifecycleV1_Push(g_gov_sig_forensics_tel_v1.life, rec);
}

inline void GovSigForensicsV1_FillBoolFromRejectCode(const int gr, bool &tr, bool &kl, bool &mo, bool &sp, bool &se, bool &rk)
{
   tr = (gr != GOV_SIG_REJECT_TREND);
   kl = (gr != GOV_SIG_REJECT_KEYLEVEL);
   mo = (gr != GOV_SIG_REJECT_MOMENTUM);
   sp = (gr != GOV_SIG_REJECT_SPREAD);
   se = (gr != GOV_SIG_REJECT_SESSION);
   rk = (gr != GOV_SIG_REJECT_RISK && gr != GOV_SIG_REJECT_DD);
}

inline void GovSigForensicsV1_NotifyPipelineOpen(const datetime ts)
{
   GovSigFoV1_OnCreatedOnly(g_gov_sig_forensics_tel_v1, ts);
}

inline void GovSigForensicsV1_NotifyEarlyReject(const datetime ts,
                                                const ENUM_REGIME reg_fallback,
                                                const ENUM_SIGNAL_REJECT_REASON nat,
                                                const bool filtered_stage)
{
   GovSigFoV1_OnCreatedOnly(g_gov_sig_forensics_tel_v1, ts);
   const int gr = GovSigRejectV1_FromNative(nat);
   GovSigFoV1_OnReject(g_gov_sig_forensics_tel_v1, ts, 0, reg_fallback, gr, filtered_stage);
   MarketState stub;
   GovSigForensicsV1_MakeStubState(reg_fallback, stub);
   bool tr, kl, mo, sp, se, rk;
   GovSigForensicsV1_FillBoolFromRejectCode(gr, tr, kl, mo, sp, se, rk);
   const int fs = filtered_stage ? GOV_SIG_FILTERED : GOV_SIG_REJECTED;
   GovSigForensicsV1_PushRecord(ts, stub, 0, SIGNAL_NONE, 0, gr, fs, tr, kl, mo, sp, se, rk, false);
}

inline void GovSigForensicsV1_OnConsensusResolvedNone(const datetime ts, const MarketState &st)
{
   GovSigFoV1_OnConsensusFail(g_gov_sig_forensics_tel_v1, ts, st.regime);
   const int gr = GOV_SIG_REJECT_CONSENSUS;
   bool tr, kl, mo, sp, se, rk;
   GovSigForensicsV1_FillBoolFromRejectCode(gr, tr, kl, mo, sp, se, rk);
   GovSigForensicsV1_PushRecord(ts, st, 0, SIGNAL_NONE, 0, gr, GOV_SIG_REJECTED, tr, kl, mo, sp, se, rk, false);
}

inline void GovSigForensicsV1_OnConsensusResolvedOk(const datetime ts, const MarketState &st, const ENUM_SIGNAL cons, const int buyVotes, const int sellVotes)
{
   const int ag = (cons == SIGNAL_BUY) ? buyVotes : sellVotes;
   GovSigFoV1_OnConsensusPass(g_gov_sig_forensics_tel_v1, ag);
}

inline void GovSigForensicsV1_RecordReject(const datetime ts,
                                           const MarketState &st,
                                           const int strat_slot,
                                           const ENUM_SIGNAL consensus,
                                           const int qscore,
                                           const ENUM_SIGNAL_REJECT_REASON nat,
                                           const bool filtered_stage)
{
   const int gr = GovSigRejectV1_FromNative(nat);
   GovSigFoV1_OnReject(g_gov_sig_forensics_tel_v1, ts, strat_slot, st.regime, gr, filtered_stage);
   bool tr, kl, mo, sp, se, rk;
   GovSigForensicsV1_FillBoolFromRejectCode(gr, tr, kl, mo, sp, se, rk);
   const bool cons_ok = (consensus != SIGNAL_NONE);
   const int fs = filtered_stage ? GOV_SIG_FILTERED : GOV_SIG_REJECTED;
   GovSigForensicsV1_PushRecord(ts, st, strat_slot, consensus, qscore, gr, fs, tr, kl, mo, sp, se, rk, cons_ok);
}

inline void GovSigForensicsV1_RecordAccepted(const datetime ts,
                                             const MarketState &st,
                                             const int strat_slot,
                                             const ENUM_SIGNAL consensus,
                                             const int qscore)
{
   GovSigFoV1_OnAcceptedPath(g_gov_sig_forensics_tel_v1, ts, strat_slot, st.regime);
   GovSigForensicsV1_PushRecord(ts, st, strat_slot, consensus, qscore, GOV_SIG_REJECT_NONE, GOV_SIG_ACCEPTED,
                                true, true, true, true, true, true, true);
}

inline void GovSigForensicsV1_RecordExecuted(const datetime ts,
                                             const MarketState &st,
                                             const int strat_slot,
                                             const ENUM_SIGNAL consensus,
                                             const int qscore)
{
   GovSigFoV1_OnExecuted(g_gov_sig_forensics_tel_v1);
   GovSigForensicsV1_PushRecord(ts, st, strat_slot, consensus, qscore, GOV_SIG_REJECT_NONE, GOV_SIG_EXECUTED,
                                true, true, true, true, true, true, true);
}

#endif // __AURUM_GOV_SIG_FORENSICS_INTEGRATION_V1_MQH__
