# 🎯 PANDUAN STEP-BY-STEP: FASE 1 - UJI FUNGSI DASAR EA
## Membuat EA Execute Trade Pertama Kali

**Tujuan Fase 1:** Memastikan EA bisa execute minimal 1 trade  
**Waktu Estimasi:** 2-3 jam  
**Level:** Pemula - Ikuti langkah demi langkah

---

## 📌 GAMBARAN BESAR FASE 1

Kita akan melakukan 5 langkah utama:

```
STEP 1: ✅ Compile EA (5 menit)
   ↓
STEP 2: ⬇️ Download Data Historis (15-30 menit)
   ↓
STEP 3: ⚙️ Setting Ultra-Permissive Test (10 menit)
   ↓
STEP 4: ▶️ Run Backtest (5-10 menit)
   ↓
STEP 5: 📊 Analisa Hasil (10 menit)
```

**Setelah selesai, Anda akan tahu:**
- ✅ EA bisa jalan atau tidak
- ✅ Masalahnya di mana (kalau ada)
- ✅ Langkah berikutnya apa

---

---

# STEP 1: COMPILE EA ✅

## 🎯 Tujuan
Memastikan EA tidak ada error kompilasi dan siap digunakan.

---

### 1.1 Buka MetaEditor

**Cara:**
1. Buka MT5
2. Tekan **F4** di keyboard
3. Atau klik menu **Tools → MetaQuotes Language Editor**

**Hasil yang benar:**
- Window baru muncul (MetaEditor)
- Di sebelah kiri ada folder tree

📸 **Screenshot:** Window MetaEditor terbuka

---

### 1.2 Navigasi ke File EA

**Cara:**
1. Di MetaEditor, lihat panel kiri (Navigator)
2. Klik folder **Experts**
3. Klik folder **AurumSynapse**
4. Cari file **AurumSynapse.mq5**
5. Double-click file tersebut

**Hasil yang benar:**
- File terbuka di editor
- Anda lihat kode MQL5
- Tab di atas menunjukkan "AurumSynapse.mq5"

📸 **Screenshot:** File AurumSynapse.mq5 terbuka

---

### 1.3 Compile EA

**Cara:**
1. Dengan file AurumSynapse.mq5 terbuka
2. Tekan **F7** di keyboard
3. Atau klik menu **File → Compile**

**Tunggu proses compile (2-5 detik)...**

---

### 1.4 Cek Hasil Compile

**Cara:**
1. Lihat panel bawah MetaEditor
2. Ada tab **Errors**
3. Lihat status bar paling bawah

**✅ HASIL YANG BENAR (PASS):**
```
Status bar menunjukkan:
"0 error(s), 0 warning(s), compiled successfully"

Tab Errors kosong atau tidak ada pesan merah
```

**❌ HASIL YANG SALAH (FAIL):**
```
Ada angka merah di "error(s)"
Tab Errors menunjukkan baris error merah
Status bar: "1 error(s)" atau lebih
```

---

### 1.5 Jika PASS - Lanjut ke Step 2 ✅

**Konfirmasi:**
- [ ] File AurumSynapse.mq5 compile tanpa error
- [ ] Status bar: "0 error(s)"
- [ ] File AurumSynapse.ex5 ter-generate (ada di folder MQL5/Experts/AurumSynapse/)

**Action:** ➡️ **LANJUT KE STEP 2**

---

### 1.6 Jika FAIL - Troubleshooting ❌

**Cek ini:**

#### Error Tipe 1: "Cannot open include file"
```
Error: 'Core/Constants.mqh' - cannot open include file
```

**Solusi:**
1. Cek folder structure
2. Pastikan semua file .mqh ada di folder yang benar
3. Path harus: `MQL5/Experts/AurumSynapse/Core/Constants.mqh`

---

#### Error Tipe 2: "Undeclared identifier"
```
Error: 'SIGNAL_BUY' - undeclared identifier
```

**Solusi:**
1. Ada file .mqh yang belum ter-include
2. Buka file Core/Constants.mqh
3. Pastikan semua enum sudah didefinisikan

---

#### Error Tipe 3: "Arrays are passed by reference only"
```
Error: arrays are passed by reference only
```

**Solusi:**
Ini sudah diperbaiki di versi terbaru. Jika masih muncul:
1. Cari function yang error (lihat line number)
2. Ganti `array[]` menjadi `&array[]`

---

**Jika masih error setelah troubleshooting:**
- Screenshot error lengkap
- Catat line number
- Tanya bantuan dengan menyertakan screenshot

---

---

# STEP 2: DOWNLOAD DATA HISTORIS ⬇️

## 🎯 Tujuan
Download tick data XAUUSD untuk periode yang akan di-backtest.

**⚠️ PENTING:** Tanpa data, backtest akan 0 trades!

---

### 2.1 Buka Symbol Window

**Cara:**
1. Di MT5 (bukan MetaEditor)
2. Tekan **Ctrl+U** di keyboard
3. Atau klik menu **View → Symbols**

**Hasil yang benar:**
- Window "Symbols" muncul
- Ada list simbol di sebelah kiri

📸 **Screenshot:** Window Symbols terbuka

---

### 2.2 Cari Symbol XAUUSD

**Cara:**
1. Di window Symbols
2. Scroll atau ketik "XAUUSD" di search box
3. Klik symbol **XAUUSD** (atau GOLD, tergantung broker)
4. Pastikan ada icon warna di sebelah kirinya (artinya aktif)

**Jika XAUUSD tidak ada:**
- Coba cari "GOLD"
- Atau "XAUUSD.xxx" (ada suffix)
- Right-click → Show All

**Hasil yang benar:**
- XAUUSD/GOLD terlihat dan ter-highlight

📸 **Screenshot:** XAUUSD selected

---

### 2.3 Download Ticks

**Cara:**
1. Dengan XAUUSD masih selected
2. Klik button **"Ticks"** (di bawah window)
3. Atau double-click XAUUSD, lalu tab "Ticks"

**Window baru muncul: "Tick History Request"**

---

### 2.4 Set Date Range

**Cara:**
1. Di window "Tick History Request"
2. Set:
   - **From:** `2024.01.01`
   - **To:** `2024.12.31`
3. Pastikan checkbox **"Request ticks"** ✅ dicentang

📸 **Screenshot:** Settings date range

---

### 2.5 Start Download

**Cara:**
1. Klik button **"Request"**
2. Tunggu proses download

**⏳ Proses ini bisa lama:**
- Data 1 tahun XAUUSD = ~5-10 GB
- Waktu: 10-30 menit (tergantung internet)

**Progress bar akan muncul:**
```
[████████░░░░░░░░░░] 45% - Downloading...
```

**JANGAN tutup window sampai selesai!**

---

### 2.6 Cek Download Selesai

**✅ HASIL YANG BENAR (PASS):**
```
Progress bar: [████████████████████] 100%
Status: "Download completed"
Atau window otomatis close
```

**Di tab "Ticks":**
- Ada data tick terlihat
- Column "Time" dan "Bid/Ask" terisi

📸 **Screenshot:** Download complete

---

### 2.7 Jika Download Gagal

**Kemungkinan masalah:**

#### Masalah 1: "No connection"
**Solusi:**
- Cek koneksi internet
- Pastikan MT5 connected (lihat pojok kanan bawah)
- Restart MT5 dan coba lagi

#### Masalah 2: "Data not available for this period"
**Solusi:**
- Broker tidak punya data 2024
- Coba periode lain: 2023 atau 2022
- Atau ganti broker (IC Markets recommended)

#### Masalah 3: Download stuck di 50%
**Solusi:**
- Tunggu 5 menit
- Jika masih stuck, cancel dan retry
- Coba download per 3 bulan (Jan-Mar, Apr-Jun, etc.)

---

### 2.8 Konfirmasi Data Ready

**Cara verifikasi cepat:**
1. Di MT5, buka chart XAUUSD M1
2. Zoom out (Ctrl + scroll down)
3. Lihat apakah ada candles di 2024

**✅ PASS jika:**
- Chart menunjukkan data penuh 2024
- Tidak ada gap besar
- Candles terlihat smooth

**Konfirmasi:**
- [ ] Data XAUUSD 2024 ter-download
- [ ] Chart menunjukkan data lengkap
- [ ] Tidak ada error message

**Action:** ➡️ **LANJUT KE STEP 3**

---

---

# STEP 3: SETTING ULTRA-PERMISSIVE TEST ⚙️

## 🎯 Tujuan
Configure Strategy Tester dengan setting paling permissive (longgar) untuk memastikan EA bisa trade.

**Filosofi:** Kita mau lihat EA bisa execute APAPUN dulu, kualitas belakangan!

---

### 3.1 Buka Strategy Tester

**Cara:**
1. Di MT5, tekan **Ctrl+R**
2. Atau klik menu **View → Strategy Tester**

**Hasil yang benar:**
- Panel "Strategy Tester" muncul (biasanya di bawah)
- Ada 3 tab: Settings, Inputs, Optimization

📸 **Screenshot:** Strategy Tester panel terbuka

---

### 3.2 Tab Settings - Basic Configuration

**Klik tab "Settings"**

**Set parameter berikut:**

| Parameter | Value | Catatan |
|-----------|-------|---------|
| **Expert Advisor** | AurumSynapse | Pilih dari dropdown |
| **Symbol** | XAUUSD | Atau GOLD |
| **Period** | M1 | 1 minute timeframe |
| **Dates** | ✅ Use date | Centang checkbox |
| **From** | 2024.01.01 | 1 Januari 2024 |
| **To** | 2024.01.31 | 31 Januari 2024 (1 bulan saja!) |

**⚠️ PENTING: 1 bulan dulu untuk test cepat!**

---

### 3.3 Tab Settings - Advanced Configuration

**Scroll ke bawah di tab Settings:**

| Parameter | Value | Catatan |
|-----------|-------|---------|
| **Model** | Every tick based on real ticks | Paling akurat |
| **Optimization** | ❌ Disabled | Tidak centang |
| **Visual mode** | ❌ Disabled | Tidak centang (lebih cepat) |
| **Deposit** | 10000 | $10,000 |
| **Currency** | USD | Default |
| **Leverage** | 1:500 | Atau sesuai broker |

📸 **Screenshot:** Settings tab configured

---

### 3.4 Tab Inputs - CRITICAL SETTINGS! ⚠️

**⚠️ INI BAGIAN PALING PENTING!**

**Klik tab "Inputs"**

Anda akan lihat BANYAK parameter. Ikuti PERSIS setting di bawah:

---

#### 🔴 SECTION 1: STRATEGY ACTIVATION

```
InpUseTrendFollowing    = true
InpUseBreakout          = true
InpUseMeanReversion     = true
InpUseSupplyDemand      = true
InpUseSmartMoney        = true
InpUsePriceAction       = true
InpUseGridRecovery      = false    ← PENTING: FALSE!
InpUseMomentumScalp     = true
```

**Catatan:** GridRecovery OFF karena risky untuk test awal.

---

#### 🔴 SECTION 2: QUALITY FILTER (LOOSEN!)

```
InpMinQualityScore      = 30       ← RENDAH! (default 70)
InpRequireTrendAlign    = false    ← OFF
InpRequireKeyLevel      = false    ← OFF
InpRequireMomentum      = false    ← OFF
```

**❗ INI KUNCI SUKSES:** Quality score 30 = sangat permissive!

---

#### 🔴 SECTION 3: CONSENSUS (LOOSEN!)

```
InpMinConsensus         = 1        ← Cukup 1 strategy!
```

**Normalnya:** 3-4 strategies harus agree  
**Sekarang:** 1 strategy cukup → banyak trades!

---

#### 🔴 SECTION 4: LOT SIZING

```
InpLotMethod            = 0        ← 0 = Fixed lot
InpFixedLot             = 0.01     ← Minimum
InpAutoLotRisk          = 1.0      ← Tidak dipakai (karena fixed)
InpFixedLotPerBalance   = 0.01     ← Tidak dipakai
```

---

#### 🔴 SECTION 5: TP/SL (KEEP DEFAULT)

```
InpTPCoefficient        = 2.0
InpSLCoefficient        = 1.0
InpStopLossPoints       = 100
InpTakeProfitPoints     = 200
```

**Jangan diubah dulu!**

---

#### 🔴 SECTION 6: TIME FILTER (DISABLE ALL!)

```
InpUseTimeFilter        = false    ← OFF = trade 24/7
InpHourFrom             = 0
InpHourTo               = 23
InpAllowSunday          = true
InpAllowMonday          = true
InpAllowTuesday         = true
InpAllowWednesday       = true
InpAllowThursday        = true
InpAllowFriday          = true
InpAllowSaturday        = true
```

**Catatan:** Semua hari = true, time filter = false

---

#### 🔴 SECTION 7: RISK LIMITS (KEEP SAFE)

```
InpMaxDailyLossPct      = 5.0      ← 5% max loss per hari
InpMaxEquityDD          = 12.0     ← 12% max drawdown
InpMaxConsecutiveLoss   = 5        ← 5 losses berturut-turut
InpMaxOpenPositions     = 5        ← Max 5 posisi
```

---

#### 🔴 SECTION 8: SPREAD FILTER (LOOSEN!)

```
InpMaxSpreadPoints      = 50       ← Default 30, kita naikkan!
```

---

#### 🔴 SECTION 9: TRAILING STOP (OPTIONAL)

```
InpUseTrailing          = false    ← OFF dulu untuk simplicity
InpTrailStartPips       = 20
InpTrailDistancePips    = 10
```

---

#### 🔴 SECTION 10: UI (CRITICAL!)

```
InpShowPanel            = false    ← MUST BE FALSE untuk backtest!
InpShowStrategySignals  = false
InpPanelUpdateSeconds   = 1
```

**❗ PENTING:** `InpShowPanel = false` kalau tidak backtest bisa crash!

---

#### 🔴 SECTION 11: MAGIC NUMBER

```
InpMagicNumber          = 20260505 ← Bisa apa saja
```

---

### 3.5 Double-Check Settings

**Sebelum run, cek lagi:**

✅ **3 Setting Terpenting:**
1. `InpMinQualityScore = 30` (bukan 70!)
2. `InpMinConsensus = 1` (bukan 3!)
3. `InpShowPanel = false` (bukan true!)

**Kalau salah satu salah, bisa 0 trades!**

📸 **Screenshot:** Inputs tab dengan highlight 3 setting di atas

---

### 3.6 Save Settings (Optional)

**Cara save agar tidak perlu setting ulang:**

1. Di tab Inputs, klik button **"Save"** (ikon disk)
2. Nama file: `UltraPermissive_Test.set`
3. Simpan di folder: `MQL5/Presets/`

**Next time:** Tinggal klik "Load" dan pilih file tersebut!

---

### 3.7 Konfirmasi Ready to Run

**Checklist final:**

- [ ] Expert: AurumSynapse ✅
- [ ] Symbol: XAUUSD ✅
- [ ] Period: M1 ✅
- [ ] Date: 2024.01.01 - 2024.01.31 ✅
- [ ] Model: Every tick based on real ticks ✅
- [ ] Visual mode: OFF ✅
- [ ] InpMinQualityScore: 30 ✅
- [ ] InpMinConsensus: 1 ✅
- [ ] InpShowPanel: false ✅

**Action:** ➡️ **LANJUT KE STEP 4**

---

---

# STEP 4: RUN BACKTEST ▶️

## 🎯 Tujuan
Jalankan backtest pertama dan tunggu hasilnya.

---

### 4.1 Start Backtest

**Cara:**
1. Pastikan semua setting sudah benar (Step 3)
2. Di Strategy Tester panel
3. Klik button **"Start"** (ikon ▶️ hijau)

**Alternatif:** Tekan **F5** di keyboard

---

### 4.2 Tunggu Proses

**Yang terjadi:**
```
Status bar menunjukkan:
[████████░░░░░░░░] 45% - 2024.01.15 12:34
```

**Timeline:**
- 0-30%: Initialization (1-2 menit)
- 30-70%: Processing trades (2-3 menit)
- 70-100%: Finishing (1 menit)

**Total waktu:** 5-10 menit untuk 1 bulan data

**⚠️ JANGAN:**
- Tutup MT5
- Minimize window (bisa slow down)
- Buka EA lain
- Ganggu proses

---

### 4.3 Monitor Progress

**Yang bisa Anda lakukan sambil tunggu:**

1. **Lihat Journal tab:**
   - Klik tab "Journal" di Strategy Tester
   - Lihat messages real-time
   - Cari error messages (berwarna merah)

2. **Lihat Graph tab:**
   - Klik tab "Graph"
   - Lihat apakah equity curve bergerak
   - Flat line = masalah!

📸 **Screenshot:** Backtest running (progress bar 50%)

---

### 4.4 Backtest Complete

**✅ HASIL:**
```
Status bar: "Backtest completed"
Progress: 100%
Tab "Backtest" aktif otomatis
```

**Suara:** MT5 mungkin beep 1x

---

### 4.5 Jika Stuck atau Error

**Masalah 1: Progress stuck di 0%**
```
Solusi:
1. Wait 2-3 minutes (initialization bisa lama)
2. Jika masih 0%, klik "Stop"
3. Cek Journal tab untuk error
4. Re-run dengan "Visual mode" ON untuk debug
```

**Masalah 2: Progress stuck di 30-50%**
```
Solusi:
1. Wait 5 minutes (processing bisa lama)
2. Cek RAM usage (Task Manager)
3. Jika stuck >10 menit, restart MT5
```

**Masalah 3: Crash atau freeze**
```
Solusi:
1. Kill MT5 dari Task Manager
2. Restart MT5
3. Re-run dengan:
   - Period lebih pendek (2 minggu)
   - Model: "1 minute OHLC" (lebih ringan)
```

---

### 4.6 Konfirmasi Completion

**Checklist:**
- [ ] Progress bar: 100%
- [ ] Status: "Backtest completed"
- [ ] Tab "Backtest" menunjukkan data
- [ ] Graph tab menunjukkan equity curve

**Action:** ➡️ **LANJUT KE STEP 5**

---

---

# STEP 5: ANALISA HASIL 📊

## 🎯 Tujuan
Tentukan: EA berhasil atau gagal execute trades.

---

### 5.1 Buka Tab "Backtest"

**Cara:**
1. Di Strategy Tester panel
2. Klik tab **"Backtest"** (atau "Results")
3. Lihat tabel hasil

📸 **Screenshot:** Tab Backtest showing results

---

### 5.2 Cek Total Trades (CRITICAL!)

**Lihat baris:**
```
Total net profit:    $XXX.XX
Gross profit:        $XXX.XX
Gross loss:          $XXX.XX
Total trades:        ______  ← INI YANG PENTING!
```

**3 KEMUNGKINAN HASIL:**

---

### 🟢 HASIL A: 100+ Trades (IDEAL!)

```
Total trades: 100-500
Win rate: 55-75%
Profit factor: 1.2-3.0
Max drawdown: <20%
```

**✅ ARTINYA:**
- EA FUNCTIONAL! 🎉
- Filter terlalu ketat di setting normal
- Perlu tuning di Phase 2

**📋 ACTION:**
```
1. Screenshot hasil lengkap
2. Catat:
   - Total trades: _______
   - Win rate: _______%
   - Profit factor: _______
   - Max DD: _______%
3. LANJUT KE PHASE 2 (Filter Calibration)
```

**SELAMAT! Phase 1 PASSED! ✅**

---

### 🟡 HASIL B: 1-20 Trades (PARTIAL)

```
Total trades: 1-20
Maybe 1-2 wins, rest losses
Graph mostly flat
```

**⚠️ ARTINYA:**
- EA bisa trade, tapi masih terlalu strict
- Perlu loosening lebih lanjut

**📋 ACTION:**

#### B.1 Cek Journal Tab
```
1. Klik tab "Journal"
2. Scroll dari atas
3. Cari messages seperti:
   - "Quality score: 45 (required: 30)"
   - "Spread 35 > max 30"
   - "No consensus: 0 BUY, 0 SELL"
4. Screenshot Journal lengkap
```

#### B.2 Loosenkan Lebih Lagi
```
Balik ke Step 3.4, ubah:

InpMinQualityScore = 20 (turunkan dari 30!)
InpMaxSpreadPoints = 100 (naikkan dari 50!)
InpMinConsensus = 1 (sudah, keep)
```

#### B.3 Run Ulang
```
Klik "Start" lagi dengan setting baru
Tunggu hasil
```

**Jika masih <10 trades setelah re-run:**
→ Lanjut ke HASIL C troubleshooting

---

### 🔴 HASIL C: 0 Trades (FAIL!)

```
Total trades: 0
Equity curve: Flat line di $10,000
Graph tidak bergerak sama sekali
```

**❌ ARTINYA:**
- Ada masalah fundamental
- EA tidak execute sama sekali

**📋 ACTION: TROUBLESHOOTING**

---

### 5.3 Troubleshooting: 0 Trades

#### Diagnosa 1: Cek Initialization

**Cara:**
1. Klik tab "Journal"
2. Scroll ke PALING ATAS
3. Cari messages seperti:

**✅ YANG BENAR:**
```
2024.01.01 00:00:00  AurumSynapse XAUUSD,M1: initialized
2024.01.01 00:00:00  [1/8] Initializing Strategy Manager...
2024.01.01 00:00:00  StrategyManager initialized with 8 strategies
2024.01.01 00:00:00  [2/8] Initializing Market Analyzer...
2024.01.01 00:00:00  MarketAnalyzer initialized
... (semua komponen initialized)
```

**❌ YANG SALAH:**
```
2024.01.01 00:00:00  FAILED TO INITIALIZE MarketAnalyzer
2024.01.01 00:00:00  Invalid handle for ATR
2024.01.01 00:00:00  EA initialization failed
```

**Jika ada "FAILED":**
- Ada bug di kode EA
- Screenshot error message
- Minta bantuan dengan screenshot

---

#### Diagnosa 2: Cek Data Availability

**Cara:**
1. Re-run backtest dengan **Visual mode ON**
2. Setting → Visual mode: ✅ Centang
3. Klik "Start"

**Window chart akan muncul:**

**✅ YANG BENAR:**
- Chart bergerak (candles baru muncul)
- Time advancing
- Price berubah

**❌ YANG SALAH:**
- Chart frozen
- Time stuck
- No candles

**Jika frozen:**
- Data tidak ter-load
- Balik ke Step 2, download ulang data

---

#### Diagnosa 3: Cek Indicator Errors

**Cara:**
1. Di tab Journal, cari:

```
❌ "Invalid handle for ATR"
❌ "Invalid handle for ADX"
❌ "CopyBuffer failed for RSI"
❌ "Indicator data not available"
```

**Jika ada error indicator:**

**Solusi A:** Change Model
```
Settings → Model: "1 minute OHLC"
(Lebih simple, mungkin work)
```

**Solusi B:** Change Period
```
Settings → From/To:
2023.01.01 - 2023.01.31
(Coba tahun lain)
```

---

#### Diagnosa 4: Emergency Debug Mode

**Jika semua di atas gagal:**

**Tambah Print Statements:**

1. Buka MetaEditor
2. Buka AurumSynapse.mq5
3. Di function `OnTick()`, paling atas, tambah:

```cpp
void OnTick() {
    static int tickCount = 0;
    tickCount++;
    if(tickCount % 100 == 0) {
        Print("OnTick #", tickCount, " - Time: ", TimeCurrent());
    }
    
    // ... rest of code
}
```

4. Save dan Compile (F7)
5. Run backtest ulang
6. Cek Journal:

**✅ Harus ada:**
```
OnTick #100 - Time: 2024.01.01 01:40:00
OnTick #200 - Time: 2024.01.01 03:20:00
...
```

**Jika tidak ada messages:**
- EA tidak dipanggil oleh MT5
- Possible MT5 issue
- Reinstall EA

---

#### Diagnosa 5: Setting Check

**Double-check lagi:**

```
❓ InpShowPanel = false ?
❓ InpMinQualityScore = 30 ?
❓ InpMinConsensus = 1 ?
❓ Semua strategies = true (kecuali Grid)?
❓ InpUseTimeFilter = false ?
❓ All days = true ?
```

**Jika ada yang salah:**
- Fix settings
- Run ulang

---

### 5.4 Simpan Hasil

**Untuk dokumentasi:**

1. **Screenshot tab "Backtest"** (hasil)
2. **Screenshot tab "Graph"** (equity curve)
3. **Screenshot tab "Journal"** (first 50 lines)
4. **Screenshot Inputs tab** (settings yang dipakai)

**Save ke folder:**
```
Documents/AurumSynapse/Phase1_Results/
Filename: Phase1_Test1_2024-01-31.png
```

---

---

# 📋 PHASE 1 COMPLETION SUMMARY

## Hasil Anda:

**Backtest Date:** _______________

**Settings Used:**
```
Period: 2024.01.01 - 2024.01.31
Quality Score: _______
Min Consensus: _______
Strategies Active: _______
```

**Results:**
```
Total Trades:     _______
Win Rate:         _______%
Profit Factor:    _______
Max Drawdown:     _______%
Net Profit:       $_______
```

**Kategori Hasil:**
- [ ] 🟢 HASIL A (100+ trades) - IDEAL
- [ ] 🟡 HASIL B (1-20 trades) - PARTIAL
- [ ] 🔴 HASIL C (0 trades) - FAIL

---

## Langkah Selanjutnya:

### Jika HASIL A (100+ trades):
```
✅ PHASE 1 PASSED!

Next:
1. Catat settings yang berhasil
2. Screenshot semua hasil
3. Siap lanjut ke PHASE 2: Filter Calibration
4. Baca: "Panduan_Phase2_FilterCalibration.md"
```

### Jika HASIL B (1-20 trades):
```
⚠️ PHASE 1 PARTIAL

Action:
1. Loosenkan settings lebih (quality=20, spread=100)
2. Run ulang
3. Jika masih <10 trades, follow Diagnosa C

Jika sudah >20 trades:
→ Bisa lanjut Phase 2 dengan catatan
```

### Jika HASIL C (0 trades):
```
❌ PHASE 1 FAIL

Action:
1. Follow semua Troubleshooting 5.3
2. Screenshot Journal lengkap
3. Tanya bantuan jika stuck:
   - Sertakan screenshots
   - Setting yang dipakai
   - Journal messages
4. JANGAN lanjut Phase 2 sampai ini solved!
```

---

## Support

**Jika butuh bantuan:**

1. **Kumpulkan info ini:**
   - Screenshot hasil backtest
   - Screenshot Journal (first 50 lines)
   - Screenshot Inputs settings
   - MT5 version & broker name

2. **Pertanyaan yang jelas:**
   - "Saya dapat 0 trades, Journal menunjukkan..."
   - "Backtest stuck di 50%, tidak jalan..."
   - "Ada error: [paste error message]..."

3. **Jangan lupa:**
   - Build number MT5
   - Windows version
   - RAM available

---

## 🎯 TARGET PHASE 1

**✅ PASS Criteria:**
- EA compile tanpa error
- Data historis ter-download
- Backtest run sampai selesai
- Minimal 20+ trades executed
- Tidak ada initialization errors

**Jika semua PASS:**
```
🎉 SELAMAT!
EA Anda FUNCTIONAL dan siap untuk tuning!
```

---

**END OF PHASE 1 GUIDE**

**Status Phase 1:** [ ] PASS [ ] PARTIAL [ ] FAIL

**Date Completed:** _______________

**Catatan:**
```
(Tulis observasi, masalah, atau pertanyaan di sini)










```

---

**Next:** Panduan_Phase2_FilterCalibration.md (akan dibuat setelah Phase 1 passed)
