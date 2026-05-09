# PerformanceAnalyzer.mq5 Location & Compilation Fix

## Issue 1: Wrong Directory
`PerformanceAnalyzer.mq5` was generating compilation errors because **scripts must be in the Scripts folder**, not in the Experts folder.

## Issue 2: ArrayInitialize on Structs
MQL5's `ArrayInitialize()` only works with simple types (int, double, etc.), not with struct arrays. Fixed by manually initializing each struct element.

## Solution
The script has been moved to:
```
MQL5/Scripts/AurumSynapse/PerformanceAnalyzer.mq5
```

## How to Use

### From MetaEditor:
1. Open MetaEditor
2. Navigate to **Scripts → AurumSynapse → PerformanceAnalyzer.mq5**
3. Compile (should now compile without errors)
4. Right-click → Compile

### From MT5 Terminal:
1. After running a backtest in Strategy Tester
2. Go to **Navigator → Scripts → AurumSynapse**
3. Drag `PerformanceAnalyzer` onto the chart
4. Adjust input parameters if needed:
   - Report Name
   - Magic Number (0 = all)
   - Symbol Filter (empty = current)
5. Click **OK** to run analysis

## Output
The script will:
- Print comprehensive analysis to the **Journal** tab
- Export detailed CSV report to `MQL5/Files/AurumSynapse/`

## Note
The original file remains in `Tests/BacktestScripts/` as documentation/reference, but the **working copy** is in `Scripts/AurumSynapse/`.
