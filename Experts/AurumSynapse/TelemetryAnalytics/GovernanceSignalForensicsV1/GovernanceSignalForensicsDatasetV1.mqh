//+------------------------------------------------------------------+
//| GovernanceSignalForensicsDatasetV1.mqh                          |
//| PHASE 21 — POD + lifecycle enum (fixed buffers only)             |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_SIG_FORENSICS_DATASET_V1_MQH__
#define __AURUM_GOV_SIG_FORENSICS_DATASET_V1_MQH__

#define GOV_SIG_FORENSICS_RING_CAP_V1 512
#define GOV_SIG_FORENSICS_STRATEGY_SLOTS_V1 8
#define GOV_SIG_FORENSICS_REGIME_SLOTS_V1 4
#define GOV_SIG_FORENSICS_MONTH_BUCKETS_V1 12

enum ENUM_GOV_SIGNAL_STATE_V1
{
   GOV_SIG_CREATED = 0,
   GOV_SIG_FILTERED = 1,
   GOV_SIG_REJECTED = 2,
   GOV_SIG_ACCEPTED = 3,
   GOV_SIG_EXECUTED = 4,
   GOV_SIG_CLOSED = 5
};

struct SGovSignalRecordV1
{
   ulong signal_id;
   datetime ts;
   int strategy_id;
   int regime_id;
   int session_id;
   int volatility_id;
   int direction;
   int quality_score;
   bool trend_align;
   bool key_level_ok;
   bool momentum_ok;
   bool spread_ok;
   bool session_ok;
   bool risk_ok;
   bool consensus_ok;
   int reject_reason;
   int final_state;
};

#endif // __AURUM_GOV_SIG_FORENSICS_DATASET_V1_MQH__
