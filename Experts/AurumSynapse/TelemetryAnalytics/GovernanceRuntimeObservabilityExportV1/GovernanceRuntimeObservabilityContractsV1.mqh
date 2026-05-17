//+------------------------------------------------------------------+
//| GovernanceRuntimeObservabilityContractsV1.mqh                  |
//| ABI / magic / flags — cold-path governance observability         |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_OBS_CONTRACTS_V1_MQH__
#define __AURUM_GOV_RUNTIME_OBS_CONTRACTS_V1_MQH__

#define GOV_RUNTIME_OBS_MAGIC_V1           ((uint)0x524F5347) // 'ROSG'
#define GOV_RUNTIME_OBS_ABI_VER_V1         ((uint)1)

#define GOV_RUNTIME_OBS_FLAG_NONE          0
#define GOV_RUNTIME_OBS_FLAG_JOURNAL       1
#define GOV_RUNTIME_OBS_FLAG_FILE          2
#define GOV_RUNTIME_OBS_FLAG_INCLUDE_RAW   4
#define GOV_RUNTIME_OBS_FLAG_ALL_BLOCKS    8

#define GOV_RUNTIME_OBS_JOURNAL_CHUNK_V1   900

enum ENUM_GOV_RUNTIME_CAPITAL_RESULT_V1
{
   GOV_CAP_RES_NONE = 0,
   GOV_CAP_RES_OK = 1,
   GOV_CAP_RES_LOT_INVALID = 2,
   GOV_CAP_RES_LOT_COLLAPSE_MIN_VOLUME = 3,
   GOV_CAP_RES_INSUFFICIENT_MARGIN = 4,
   GOV_CAP_RES_FREE_MARGIN_LOW = 5,
   GOV_CAP_RES_ORDER_SEND_FAILED = 6,
   GOV_CAP_RES_INVALID_STOPS = 7,
   GOV_CAP_RES_RISK_HALT = 8,
   GOV_CAP_RES_MAX_POSITIONS = 9,
   GOV_CAP_RES_OTHER = 99
};

#endif // __AURUM_GOV_RUNTIME_OBS_CONTRACTS_V1_MQH__
