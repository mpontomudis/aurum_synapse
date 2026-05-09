# ✅ PHASE 1 QUICK CHECKLIST
## Print halaman ini dan centang sambil ikuti Panduan_Phase1_UjiFungsiDasar.md

**Tanggal Mulai:** _______________  
**Target:** EA execute minimal 1 trade

---

## STEP 1: COMPILE EA (5 menit)

- [ ] Buka MetaEditor (F4)
- [ ] Navigate: Experts → AurumSynapse → AurumSynapse.mq5
- [ ] Compile (F7)
- [ ] Cek hasil: **0 error(s), 0 warning(s)**
- [ ] File .ex5 ter-generate

**Catatan:**
```



```

---

## STEP 2: DOWNLOAD DATA (15-30 menit)

- [ ] Buka Symbols (Ctrl+U)
- [ ] Cari XAUUSD atau GOLD
- [ ] Klik button "Ticks"
- [ ] Set date: 2024.01.01 - 2024.12.31
- [ ] Klik "Request"
- [ ] Tunggu download selesai (100%)
- [ ] Verifikasi: Chart XAUUSD M1 menunjukkan data

**Catatan:**
```



```

---

## STEP 3: SETTING STRATEGY TESTER (10 menit)

### Tab SETTINGS:
- [ ] Expert: **AurumSynapse**
- [ ] Symbol: **XAUUSD**
- [ ] Period: **M1**
- [ ] Dates: **2024.01.01 - 2024.01.31** (1 bulan!)
- [ ] Model: **Every tick based on real ticks**
- [ ] Visual mode: **OFF**
- [ ] Deposit: **10000**
- [ ] Leverage: **1:500**

### Tab INPUTS - 3 SETTING TERPENTING:

✅ **CRITICAL #1:**
- [ ] **InpMinQualityScore = 30** (bukan 70!)

✅ **CRITICAL #2:**
- [ ] **InpMinConsensus = 1** (bukan 3!)

✅ **CRITICAL #3:**
- [ ] **InpShowPanel = false** (bukan true!)

### Strategy Activation:
- [ ] InpUseTrendFollowing = **true**
- [ ] InpUseBreakout = **true**
- [ ] InpUseMeanReversion = **true**
- [ ] InpUseSupplyDemand = **true**
- [ ] InpUseSmartMoney = **true**
- [ ] InpUsePriceAction = **true**
- [ ] InpUseGridRecovery = **false** ← OFF!
- [ ] InpUseMomentumScalp = **true**

### Quality Filters (LOOSEN!):
- [ ] InpRequireTrendAlignment = **false**
- [ ] InpRequireKeyLevel = **false**
- [ ] InpRequireMomentum = **false**

### Time Filter (DISABLE!):
- [ ] InpUseTimeFilter = **false**
- [ ] All days (Sun-Sat) = **true**

### Other Settings:
- [ ] InpMaxSpreadPoints = **50**
- [ ] InpLotMethod = **0** (fixed)
- [ ] InpFixedLot = **0.01**

**Catatan:**
```



```

---

## STEP 4: RUN BACKTEST (5-10 menit)

- [ ] Klik "Start" (▶️)
- [ ] Tunggu progress bar 0% → 100%
- [ ] Monitor Journal tab (cari error merah)
- [ ] Tunggu status: "Backtest completed"

**Waktu tunggu:** _______ menit

**Catatan:**
```



```

---

## STEP 5: ANALISA HASIL (10 menit)

### Hasil Backtest:

**Total Trades:** _______

**Pilih satu:**

### 🟢 HASIL A: 100+ Trades (IDEAL!)
- [ ] Total trades: 100-500
- [ ] Win rate: 55-75%
- [ ] Graph bergerak naik/turun

**Action:** ✅ PHASE 1 PASSED! Lanjut Phase 2

---

### 🟡 HASIL B: 1-20 Trades (PARTIAL)
- [ ] Total trades: 1-20
- [ ] Graph mostly flat

**Action:**
- [ ] Cek Journal untuk rejection messages
- [ ] Screenshot Journal
- [ ] Loosenkan: Quality=20, Spread=100
- [ ] Run ulang
- [ ] Jika masih <10, follow Diagnosa C

---

### 🔴 HASIL C: 0 Trades (FAIL!)
- [ ] Total trades: 0
- [ ] Equity curve flat $10,000

**Troubleshooting Checklist:**
- [ ] Cek Journal: ada "initialized" messages?
- [ ] Cek Journal: ada "FAILED" atau error merah?
- [ ] Run dengan Visual mode ON: chart bergerak?
- [ ] Cek Journal: ada indicator errors?
- [ ] Double-check 3 CRITICAL settings di atas
- [ ] Screenshot Journal lengkap

---

## DOKUMENTASI

**Screenshots yang diambil:**
- [ ] Tab "Backtest" - Results
- [ ] Tab "Graph" - Equity curve
- [ ] Tab "Journal" - First 50 lines
- [ ] Tab "Inputs" - Settings used

**File saved to:**
```
Documents/AurumSynapse/Phase1_Results/
```

---

## HASIL AKHIR PHASE 1

**Date Completed:** _______________

**Final Result:**
```
Total Trades:     _______
Win Rate:         _______%
Profit Factor:    _______
Max Drawdown:     _______%
Net Profit:       $_______
```

**Status:**
- [ ] 🟢 **PASS** (100+ trades) → Lanjut Phase 2
- [ ] 🟡 **PARTIAL** (1-20 trades) → Loosenkan & re-test
- [ ] 🔴 **FAIL** (0 trades) → Follow troubleshooting

---

## NEXT STEP

**Jika PASS:**
```
→ Baca Panduan_Phase2_FilterCalibration.md
→ Mulai testing quality thresholds
→ Cari optimal settings
```

**Jika PARTIAL/FAIL:**
```
→ Screenshot semua hasil
→ Follow troubleshooting di panduan lengkap
→ Minta bantuan jika stuck >1 jam
```

---

## QUICK TIPS

✅ **DO:**
- Ikuti panduan step-by-step
- Screenshot setiap hasil
- Catat semua settings
- Sabar tunggu download data
- Check Journal tab untuk clues

❌ **DON'T:**
- Skip download data
- Lupa set Quality=30
- Leave ShowPanel=true
- Run tanpa cek settings
- Panic jika 0 trades pertama kali

---

## SUPPORT INFO

**Jika butuh bantuan, siapkan:**
1. Screenshot hasil backtest
2. Screenshot Journal (50 baris pertama)
3. Screenshot Inputs settings
4. MT5 version & broker name
5. Deskripsi masalah yang jelas

---

**🎯 TARGET: EA EXECUTE MINIMAL 20+ TRADES**

**Good luck! Ikuti panduan lengkap untuk detail setiap step!**
