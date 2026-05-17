//+------------------------------------------------------------------+
//| GovernanceCryptoV1.mqh                                         |
//| SHA-256 over raw bytes — platform CryptEncode (CRYPT_HASH_SHA256)|
//| Output: lowercase hex (replay-stable, locale-independent).        |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_CRYPTO_V1_MQH__
#define __AURUM_GOV_CRYPTO_V1_MQH__

//+------------------------------------------------------------------+
//| Nibble → hex (lowercase ASCII only).                             |
//+------------------------------------------------------------------+
string GovCryptoV1_ByteToHex2(const uchar b) {
    const string H = "0123456789abcdef";
    return StringSubstr(H, (b >> 4), 1) + StringSubstr(H, (b & 15), 1);
}

//+------------------------------------------------------------------+
//| SHA-256(raw[0..len-1]) → out32[32].                             |
//| Returns false if CryptEncode fails or len < 0.                  |
//+------------------------------------------------------------------+
bool GovCryptoV1_Sha256Raw(const uchar &raw[], const int len, uchar &out32[]) {
    if(len < 0)
        return false;
    uchar key0[];
    ArrayResize(key0, 0);
    uchar slice[];
    ArrayResize(slice, len);
    if(len > 0)
        ArrayCopy(slice, raw, 0, 0, len);
    ArrayResize(out32, 0);
    const int rb = CryptEncode(CRYPT_HASH_SHA256, slice, key0, out32);
    if(rb <= 0 || ArraySize(out32) < 32)
        return false;
    return true;
}

//+------------------------------------------------------------------+
//| SHA-256(UTF-8 bytes of `s`) → lowercase hex string (64 chars).   |
//+------------------------------------------------------------------+
bool GovCryptoV1_Sha256Utf8StringToHexLower(const string s, string &out_hex_lower) {
    out_hex_lower = "";
    if(StringLen(s) == 0) {
        // SHA-256("") — deterministic anchor for empty transcript concatenation.
        out_hex_lower = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
        return true;
    }
    uchar body[];
    const int slen = StringLen(s);
    const int n = (slen <= 0) ? 0 : StringToCharArray(s, body, 0, slen, CP_UTF8);
    if(n <= 0)
        return false;
    uchar h32[];
    if(!GovCryptoV1_Sha256Raw(body, n, h32))
        return false;
    string acc = "";
    for(int i = 0; i < 32; i++)
        acc += GovCryptoV1_ByteToHex2(h32[i]);
    out_hex_lower = acc;
    return (StringLen(out_hex_lower) == 64);
}

#endif // __AURUM_GOV_CRYPTO_V1_MQH__
