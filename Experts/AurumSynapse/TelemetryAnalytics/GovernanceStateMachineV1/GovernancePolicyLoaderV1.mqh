//+------------------------------------------------------------------+
//| GovernancePolicyLoaderV1.mqh                                   |
//| Canonical policy.tab loader — fail-closed, immutable snapshot.   |
//| Normative: PHASE_8_GOVERNANCE_POLICY_TABLES_V1.md §1.4–§1.6, §9 |
//|            PHASE_8A_GOVERNANCE_STATE_MACHINE_IMPLEMENTATION_SPEC |
//| policy.tab contract (UTF-8, key=value, LF, sorted checksum body):|
//|  - One logical line = optional leading ASCII HT/SP trim, then    |
//|    either empty / comment / key=value.                          |
//|  - Comments: first non-ws char '#' → line ignored.               |
//|  - Keys: [a-z0-9_]+ lowercase ASCII only (reject otherwise).     |
//|  - Values: non-control UTF-8 (no CR/LF); outer ASCII trim only.  |
//|  - Duplicate keys: hard error (fail-closed).                     |
//|  - Whitelist: policy_id, policy_semver, policy_checksum_sha256, |
//|    gov_defaults_phase8_embedded, and any key with prefix `gov_`.|
//|  - Canonical checksum input: UTF-8 bytes of                    |
//|      concat_i ( key_i + '=' + val_i + '\n' )                     |
//|    for all stored pairs where key_i != policy_checksum_sha256,  |
//|    sorted by ascending Unicode codepoint order of key_i         |
//|    (identical to ASCII for allowed keys).                        |
//|  - policy_checksum_sha256 value excluded from that input.       |
//|  - Stored checksum MUST be 64 lowercase hex [0-9a-f] (reject else).|
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_POLICY_LOADER_V1_MQH__
#define __AURUM_GOV_POLICY_LOADER_V1_MQH__

#include "GovernanceTypesV1.mqh"
#include "GovernancePolicyBundleV1.mqh"
#include "GovernanceCryptoV1.mqh"
#include "GovernancePolicyMaterializeV1.mqh"

#define GOV_V1_K_POLICY_ID "policy_id"
#define GOV_V1_K_POLICY_SEMVER "policy_semver"
#define GOV_V1_K_POLICY_CHECKSUM "policy_checksum_sha256"

//+------------------------------------------------------------------+
void GovPolicyLoaderV1_ResetSnapshot(SCGovPolicySnapshotV1 &out) {
    GovPolicyBundleV1_InitEmpty(out);
}

//+------------------------------------------------------------------+
string GovPolicyLoaderV1_TrimAsciiWs(const string s) {
    const int L = StringLen(s);
    int a = 0;
    int b = L - 1;
    while(a <= b) {
        const int ch = StringGetCharacter(s, a);
        if(ch != ' ' && ch != 9)
            break;
        a++;
    }
    while(b >= a) {
        const int ch = StringGetCharacter(s, b);
        if(ch != ' ' && ch != 9)
            break;
        b--;
    }
    if(a > b)
        return "";
    return StringSubstr(s, a, b - a + 1);
}

//+------------------------------------------------------------------+
void GovPolicyLoaderV1_NormalizeNewlines(string &t) {
    StringReplace(t, "\r\n", "\n");
    StringReplace(t, "\r", "\n");
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_KeySyntaxOk(const string key) {
    const int L = StringLen(key);
    if(L <= 0 || L > GOV_V1_POLICY_MAX_KEY_LEN)
        return false;
    for(int i = 0; i < L; i++) {
        const int c = StringGetCharacter(key, i);
        if(!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_'))
            return false;
    }
    return true;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_IsDigitsOnlyNonEmpty(const string s) {
    const int L = StringLen(s);
    if(L <= 0)
        return false;
    for(int i = 0; i < L; i++) {
        const int c = StringGetCharacter(s, i);
        if(c < '0' || c > '9')
            return false;
    }
    return true;
}

//+------------------------------------------------------------------+
//| Semver scalar: trim SP/HT, strip CR/LF fragments, then ASCII ws.|
//+------------------------------------------------------------------+
string GovPolicyLoaderV1_NormalizeSemverInput(const string semver_raw) {
    string t = semver_raw;
    StringReplace(t, "\r", "");
    StringReplace(t, "\n", "");
    return GovPolicyLoaderV1_TrimAsciiWs(t);
}

//+------------------------------------------------------------------+
//| Forensic append-only line (UTF-8, LF). OFF unless bool enabled. |
//| Schema: SEMVER_FORENSIC|raw|trimmed|t1|t2|t3|ok|err_code         |
//+------------------------------------------------------------------+
const bool GOV_V1_SEMVER_FORENSIC_ENABLED = false;

void GovPolicyLoaderV1_ForensicSanitizeField_(string &x) {
    StringReplace(x, "|", "`");
    StringReplace(x, "\r", " ");
    StringReplace(x, "\n", " ");
}

void GovPolicyLoaderV1_AppendSemverForensic_(const string raw,
                                            const string trimmed,
                                            const string t1,
                                            const string t2,
                                            const string t3,
                                            const int ok,
                                            const int err_code) {
    if(!GOV_V1_SEMVER_FORENSIC_ENABLED)
        return;
    string r = raw;
    string tr = trimmed;
    string a = t1;
    string b = t2;
    string c = t3;
    GovPolicyLoaderV1_ForensicSanitizeField_(r);
    GovPolicyLoaderV1_ForensicSanitizeField_(tr);
    GovPolicyLoaderV1_ForensicSanitizeField_(a);
    GovPolicyLoaderV1_ForensicSanitizeField_(b);
    GovPolicyLoaderV1_ForensicSanitizeField_(c);
    string line = "SEMVER_FORENSIC|";
    line += r;
    line += "|";
    line += tr;
    line += "|";
    line += a;
    line += "|";
    line += b;
    line += "|";
    line += c;
    line += "|";
    line += IntegerToString(ok);
    line += "|";
    line += IntegerToString(err_code);
    line += "\n";
    uchar buf[];
    const int sl = StringLen(line);
    const int n = (sl <= 0) ? 0 : StringToCharArray(line, buf, 0, sl, CP_UTF8);
    const int h = FileOpen("__gov_semver_forensic.log",
                           FILE_READ | FILE_WRITE | FILE_BIN | FILE_SHARE_READ | FILE_SHARE_WRITE);
    if(h == INVALID_HANDLE)
        return;
    FileSeek(h, 0, SEEK_END);
    if(n > 0)
        FileWriteArray(h, buf, 0, n);
    FileClose(h);
}

//+------------------------------------------------------------------+
//| Strict [0-9]+ segment, no leading zeros (except single "0").    |
//| Deterministic overflow vs INT_MAX; sets err on failure.         |
//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_ParseSemverUint31_(const string seg,
                                         int &out_v,
                                         ENUM_GOV_POLICY_LOAD_ERR_V1 &out_err) {
    out_v = 0;
    const int L = StringLen(seg);
    if(L <= 0) {
        out_err = GOV_LOAD_ERR_V1_SEMVER_INVALID;
        return false;
    }
    if(L > 1 && StringGetCharacter(seg, 0) == '0') {
        out_err = GOV_LOAD_ERR_V1_SEMVER_INVALID;
        return false;
    }
    long acc = 0;
    for(int i = 0; i < L; i++) {
        const int c = StringGetCharacter(seg, i);
        if(c < '0' || c > '9') {
            out_err = GOV_LOAD_ERR_V1_SEMVER_INVALID;
            return false;
        }
        acc = acc * 10L + (long)(c - '0');
        if(acc > 2147483647L) {
            out_err = GOV_LOAD_ERR_V1_INTEGER_OVERFLOW;
            return false;
        }
    }
    out_v = (int)acc;
    return true;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_Hex64Lowercase(const string h) {
    if(StringLen(h) != 64)
        return false;
    for(int i = 0; i < 64; i++) {
        const int c = StringGetCharacter(h, i);
        if(!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')))
            return false;
    }
    return true;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_IsAllowedPolicyKey(const string k) {
    if(k == GOV_V1_K_POLICY_ID || k == GOV_V1_K_POLICY_SEMVER || k == GOV_V1_K_POLICY_CHECKSUM)
        return true;
    if(k == "gov_defaults_phase8_embedded")
        return true;
    if(StringFind(k, "gov_", 0) == 0)
        return true;
    return false;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_ReadFileUtf8NoBom(const string file_path_rel,
                                        string &out_text,
                                        ENUM_GOV_POLICY_LOAD_ERR_V1 &out_err) {
    out_text = "";
    out_err = GOV_LOAD_ERR_V1_OK;
    const int h = FileOpen(file_path_rel, FILE_READ | FILE_BIN);
    if(h == INVALID_HANDLE) {
        out_err = GOV_LOAD_ERR_V1_FILE_MISSING;
        return false;
    }
    const ulong fsz64 = FileSize(h);
    if(fsz64 > (ulong)GOV_V1_POLICY_MAX_FILE_BYTES) {
        FileClose(h);
        out_err = GOV_LOAD_ERR_V1_FILE_IO;
        return false;
    }
    const int sz = (int)fsz64;
    uchar raw[];
    ArrayResize(raw, sz);
    if(sz > 0) {
        if(FileReadArray(h, raw, 0, sz) != sz) {
            FileClose(h);
            out_err = GOV_LOAD_ERR_V1_FILE_IO;
            return false;
        }
    }
    FileClose(h);
    int off = 0;
    if(sz >= 3 && raw[0] == 0xEF && raw[1] == 0xBB && raw[2] == 0xBF)
        off = 3;
    if(sz <= off) {
        out_text = "";
        return true;
    }
    out_text = CharArrayToString(raw, off, sz - off, CP_UTF8);
    if((sz - off) > 0 && StringLen(out_text) == 0) {
        out_err = GOV_LOAD_ERR_V1_INVALID_ENCODING;
        return false;
    }
    return true;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_KvIndexOf(SCGovPolicySnapshotV1 &p, const string key, int &out_idx) {
    for(int i = 0; i < p.kv_count; i++) {
        if(p.kv_key[i] == key) {
            out_idx = i;
            return true;
        }
    }
    out_idx = -1;
    return false;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_KvBubbleSort(SCGovPolicySnapshotV1 &p, ENUM_GOV_POLICY_LOAD_ERR_V1 &out_err) {
    out_err = GOV_LOAD_ERR_V1_OK;
    if(p.kv_count <= 1)
        return true;
    for(int a = 0; a < p.kv_count - 1; a++) {
        for(int b = a + 1; b < p.kv_count; b++) {
            if(StringCompare(p.kv_key[a], p.kv_key[b]) > 0) {
                const string tk = p.kv_key[a];
                const string tv = p.kv_val[a];
                p.kv_key[a] = p.kv_key[b];
                p.kv_val[a] = p.kv_val[b];
                p.kv_key[b] = tk;
                p.kv_val[b] = tv;
            }
        }
    }
    return true;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_BuildCanonicalBodyForChecksum(SCGovPolicySnapshotV1 &p,
                                                    string &out_body,
                                                    ENUM_GOV_POLICY_LOAD_ERR_V1 &out_err) {
    out_body = "";
    out_err = GOV_LOAD_ERR_V1_OK;
    for(int i = 0; i < p.kv_count; i++) {
        if(p.kv_key[i] == GOV_V1_K_POLICY_CHECKSUM)
            continue;
        out_body += p.kv_key[i] + "=" + p.kv_val[i] + "\n";
    }
    return true;
}

//+------------------------------------------------------------------+
//| Semver: strict MAJOR.MINOR.PATCH grammar:                         |
//|  - ASCII digits and '.' only (no 'v', no prerelease/build).      |
//|  - Each segment: [0-9]+, no leading zeros unless segment is "0". |
//|  - Exactly two '.' separators, no trailing junk.                 |
//|  - 0 <= each segment <= INT_MAX (INTEGER_OVERFLOW if exceeded).  |
//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_ValidateSemverString(const string semver,
                                            int &out_major,
                                            int &out_minor,
                                            int &out_patch,
                                            ENUM_GOV_POLICY_LOAD_ERR_V1 &out_err) {
    out_major = 0;
    out_minor = 0;
    out_patch = 0;
    out_err = GOV_LOAD_ERR_V1_SEMVER_INVALID;

    const string sem = GovPolicyLoaderV1_NormalizeSemverInput(semver);
    const int sem_len = StringLen(sem);
    if(sem_len <= 0) {
        GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, "", "", "", 0, (int)out_err);
        return false;
    }
    for(int ci = 0; ci < sem_len; ci++) {
        const int ch = StringGetCharacter(sem, ci);
        if(ch > 127) {
            GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, "", "", "", 0, (int)out_err);
            return false;
        }
        if(!((ch >= '0' && ch <= '9') || ch == '.')) {
            GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, "", "", "", 0, (int)out_err);
            return false;
        }
    }

    const int p1 = StringFind(sem, ".");
    if(p1 <= 0) {
        GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, "", "", "", 0, (int)out_err);
        return false;
    }
    const int p2 = StringFind(sem, ".", p1 + 1);
    if(p2 <= p1 + 1) {
        GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, "", "", "", 0, (int)out_err);
        return false;
    }
    if(StringFind(sem, ".", p2 + 1) >= 0) {
        GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, "", "", "", 0, (int)out_err);
        return false;
    }

    const string s1 = StringSubstr(sem, 0, p1);
    const string s2 = StringSubstr(sem, p1 + 1, p2 - p1 - 1);
    const string s3 = StringSubstr(sem, p2 + 1);
    const int expect_len = StringLen(s1) + 1 + StringLen(s2) + 1 + StringLen(s3);
    if(expect_len != sem_len) {
        GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, s1, s2, s3, 0, (int)out_err);
        return false;
    }

    if(!GovPolicyLoaderV1_ParseSemverUint31_(s1, out_major, out_err)) {
        GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, s1, s2, s3, 0, (int)out_err);
        return false;
    }
    if(!GovPolicyLoaderV1_ParseSemverUint31_(s2, out_minor, out_err)) {
        GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, s1, s2, s3, 0, (int)out_err);
        return false;
    }
    if(!GovPolicyLoaderV1_ParseSemverUint31_(s3, out_patch, out_err)) {
        GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, s1, s2, s3, 0, (int)out_err);
        return false;
    }

    out_err = GOV_LOAD_ERR_V1_OK;
    GovPolicyLoaderV1_AppendSemverForensic_(semver, sem, s1, s2, s3, 1, (int)out_err);
    return true;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_ValidateChecksumHex(SCGovPolicySnapshotV1 &snap,
                                           const string expected_hex_lower,
                                           ENUM_GOV_POLICY_LOAD_ERR_V1 &out_err) {
    out_err = GOV_LOAD_ERR_V1_OK;
    string a = snap.policy_checksum_sha256_hex;
    string b = expected_hex_lower;
    StringToLower(a);
    StringToLower(b);
    if(!GovPolicyLoaderV1_Hex64Lowercase(a) || !GovPolicyLoaderV1_Hex64Lowercase(b)) {
        out_err = GOV_LOAD_ERR_V1_CHECKSUM_FORMAT;
        return false;
    }
    if(a != b) {
        out_err = GOV_LOAD_ERR_V1_CHECKSUM_MISMATCH;
        return false;
    }
    return true;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_LoadFromUtf8Text(const string policy_text_utf8,
                                        SCGovPolicySnapshotV1 &out,
                                        ENUM_GOV_POLICY_LOAD_ERR_V1 &out_err) {
    GovPolicyLoaderV1_ResetSnapshot(out);
    out_err = GOV_LOAD_ERR_V1_PARTIAL;

    string t = policy_text_utf8;
    GovPolicyLoaderV1_NormalizeNewlines(t);

    string lines[];
    const ushort sep_nl = StringGetCharacter("\n", 0);
    const int nlines = StringSplit(t, sep_nl, lines);
    for(int li = 0; li < nlines; li++) {
        string line = GovPolicyLoaderV1_TrimAsciiWs(lines[li]);
        if(StringLen(line) == 0)
            continue;
        if(StringGetCharacter(line, 0) == '#')
            continue;
        const int eq = StringFind(line, "=");
        if(eq <= 0) {
            out_err = GOV_LOAD_ERR_V1_MALFORMED_LINE;
            GovPolicyLoaderV1_ResetSnapshot(out);
            return false;
        }
        string k = GovPolicyLoaderV1_TrimAsciiWs(StringSubstr(line, 0, eq));
        // MQL5: StringSubstr(..., len==0) yields empty; omit length to take suffix.
        string v = GovPolicyLoaderV1_TrimAsciiWs(StringSubstr(line, eq + 1));
        if(!GovPolicyLoaderV1_KeySyntaxOk(k)) {
            out_err = GOV_LOAD_ERR_V1_MALFORMED_LINE;
            GovPolicyLoaderV1_ResetSnapshot(out);
            return false;
        }
        if(StringFind(v, "\n") >= 0 || StringFind(v, "\r") >= 0 || StringFind(v, "|") >= 0) {
            out_err = GOV_LOAD_ERR_V1_MALFORMED_LINE;
            GovPolicyLoaderV1_ResetSnapshot(out);
            return false;
        }
        if(!GovPolicyLoaderV1_IsAllowedPolicyKey(k)) {
            out_err = GOV_LOAD_ERR_V1_UNSUPPORTED_KEY;
            GovPolicyLoaderV1_ResetSnapshot(out);
            return false;
        }
        int existing = -1;
        if(GovPolicyLoaderV1_KvIndexOf(out, k, existing)) {
            out_err = GOV_LOAD_ERR_V1_DUPLICATE_KEY;
            GovPolicyLoaderV1_ResetSnapshot(out);
            return false;
        }
        if(out.kv_count >= GOV_V1_POLICY_MAX_KV) {
            out_err = GOV_LOAD_ERR_V1_FILE_IO;
            GovPolicyLoaderV1_ResetSnapshot(out);
            return false;
        }
        out.kv_key[out.kv_count] = k;
        out.kv_val[out.kv_count] = v;
        out.kv_count++;
    }

    int ix_id = -1, ix_sv = -1, ix_cs = -1;
    if(!GovPolicyLoaderV1_KvIndexOf(out, GOV_V1_K_POLICY_ID, ix_id) ||
       !GovPolicyLoaderV1_KvIndexOf(out, GOV_V1_K_POLICY_SEMVER, ix_sv) ||
       !GovPolicyLoaderV1_KvIndexOf(out, GOV_V1_K_POLICY_CHECKSUM, ix_cs)) {
        out_err = GOV_LOAD_ERR_V1_MISSING_REQUIRED_KEY;
        GovPolicyLoaderV1_ResetSnapshot(out);
        return false;
    }

    out.policy_id = out.kv_val[ix_id];
    out.policy_semver = out.kv_val[ix_sv];
    out.policy_checksum_sha256_hex = out.kv_val[ix_cs];
    StringToLower(out.policy_checksum_sha256_hex);

    if(!GovPolicyLoaderV1_KvBubbleSort(out, out_err)) {
        GovPolicyLoaderV1_ResetSnapshot(out);
        return false;
    }

    if(!GovPolicyLoaderV1_ValidateSemverString(out.policy_semver, out.semver_major, out.semver_minor, out.semver_patch, out_err)) {
        GovPolicyLoaderV1_ResetSnapshot(out);
        return false;
    }
    out.semver_verified = true;

    if(!GovPolicyLoaderV1_Hex64Lowercase(out.policy_checksum_sha256_hex)) {
        out_err = GOV_LOAD_ERR_V1_CHECKSUM_FORMAT;
        GovPolicyLoaderV1_ResetSnapshot(out);
        return false;
    }

    string canon = "";
    if(!GovPolicyLoaderV1_BuildCanonicalBodyForChecksum(out, canon, out_err)) {
        GovPolicyLoaderV1_ResetSnapshot(out);
        return false;
    }
    string hex_calc = "";
    if(!GovCryptoV1_Sha256Utf8StringToHexLower(canon, hex_calc)) {
        out_err = GOV_LOAD_ERR_V1_FILE_IO;
        GovPolicyLoaderV1_ResetSnapshot(out);
        return false;
    }
    if(!GovPolicyLoaderV1_ValidateChecksumHex(out, hex_calc, out_err)) {
        GovPolicyLoaderV1_ResetSnapshot(out);
        return false;
    }
    out.checksum_verified = true;

    if(!GovPolicySnapshotV1_MaterializeGovernance(out, out_err)) {
        GovPolicyLoaderV1_ResetSnapshot(out);
        return false;
    }

    out.load_ok = true;
    out_err = GOV_LOAD_ERR_V1_OK;
    return true;
}

//+------------------------------------------------------------------+
bool GovPolicyLoaderV1_LoadFromFile(const string file_path_rel,
                                    SCGovPolicySnapshotV1 &out,
                                    ENUM_GOV_POLICY_LOAD_ERR_V1 &out_err) {
    GovPolicyLoaderV1_ResetSnapshot(out);
    string txt = "";
    if(!GovPolicyLoaderV1_ReadFileUtf8NoBom(file_path_rel, txt, out_err))
        return false;
    return GovPolicyLoaderV1_LoadFromUtf8Text(txt, out, out_err);
}

#endif // __AURUM_GOV_POLICY_LOADER_V1_MQH__
