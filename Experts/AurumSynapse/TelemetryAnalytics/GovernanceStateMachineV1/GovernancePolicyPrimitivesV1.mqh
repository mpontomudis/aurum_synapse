//+------------------------------------------------------------------+
//| GovernancePolicyPrimitivesV1.mqh                                |
//| Deterministic integer kernels — policy-agnostic utilities.       |
//| Contracts: overflow-saturating; no floats; replay-stable.       |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POLICY_PRIMITIVES_V1_MQH__
#define __AURUM_GOV_POLICY_PRIMITIVES_V1_MQH__

//+------------------------------------------------------------------+
//| Clamp to inclusive [lo, hi]. Preconditions: lo <= hi.            |
//+------------------------------------------------------------------+
int GovClampInt32(const int v, const int lo, const int hi) {
    if(v < lo)
        return lo;
    if(v > hi)
        return hi;
    return v;
}

//+------------------------------------------------------------------+
//| Floor division n/d toward −∞ (policy §4.1 CONF_RAW aggregation). |
//| Precondition: d != 0 (caller MUST guard).                        |
//+------------------------------------------------------------------+
long GovFloorDivSigned64(const long n, const long d) {
    if(d == 0)
        return 0;
    const long q = n / d;
    const long r = n % d;
    if(r != 0 && ((r > 0) != (d > 0)))
        return q - 1;
    return q;
}

//+------------------------------------------------------------------+
//| max(a,b,c,d,e) — fixed arity (no variadics in MQL5).              |
//+------------------------------------------------------------------+
int GovMaxInt32_x5(const int a, const int b, const int c, const int d, const int e) {
    int m = a;
    if(b > m)
        m = b;
    if(c > m)
        m = c;
    if(d > m)
        m = d;
    if(e > m)
        m = e;
    return m;
}

int GovMaxInt32_x2(const int a, const int b) {
    return (a >= b) ? a : b;
}

int GovMaxInt32_x3(const int a, const int b, const int c) {
    return GovMaxInt32_x2(GovMaxInt32_x2(a, b), c);
}

//+------------------------------------------------------------------+
//| Saturating add — result in 32-bit signed saturated range.        |
//+------------------------------------------------------------------+
int GovSaturatingAdd32(const int a, const int b) {
    long s = (long)a + (long)b;
    if(s > (long)2147483647)
        return 2147483647;
    if(s < (long)(-2147483647 - 1))
        return -2147483647 - 1;
    return (int)s;
}

//+------------------------------------------------------------------+
//| Saturating multiply — 32×32 → 32 saturated.                      |
//+------------------------------------------------------------------+
int GovSaturatingMul32(const int a, const int b) {
    long p = (long)a * (long)b;
    if(p > (long)2147483647)
        return 2147483647;
    if(p < (long)(-2147483647 - 1))
        return -2147483647 - 1;
    return (int)p;
}

//+------------------------------------------------------------------+
//| Fail-closed long→int (no silent truncation).                    |
//+------------------------------------------------------------------+
bool GovCastLongToIntSafe(const long v, int &out) {
    if(v > (long)2147483647 || v < (long)(-2147483647 - 1))
        return false;
    out = (int)v;
    return true;
}

//+------------------------------------------------------------------+
//| Saturating long→int32 (deterministic bounds for safe arithmetic).|
//+------------------------------------------------------------------+
int GovSaturateLongToInt32(const long v) {
    if(v > (long)2147483647)
        return 2147483647;
    if(v < (long)(-2147483647 - 1))
        return -2147483647 - 1;
    return (int)v;
}

#endif // __AURUM_GOV_POLICY_PRIMITIVES_V1_MQH__
