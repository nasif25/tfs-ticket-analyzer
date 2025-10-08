# TFS Ticket Analyzer - Hours-Based Analysis Feature

## Date: 2025-10-08

## Overview
Added support for hours-based time range analysis in addition to the existing days-based analysis. Users can now analyze tickets from the last N hours instead of just the last N days.

---

## ✅ Implementation Complete

### 1. **Python Version (tfs-analyzer.py)**

**Changes Made:**
- Updated parameter name from `days` to `timevalue` for flexibility
- Added `--hours` flag to interpret timevalue as hours instead of days
- Modified `get_work_items()` method to accept `use_hours` boolean parameter
- Updated date calculation logic to use `timedelta(hours=x)` when hours mode is enabled
- Fixed `-h` conflict by changing HTML flag to `-H` (lowercase `-h` reserved for help in argparse)

**Usage Examples:**
```bash
python tfs-analyzer.py 12 --hours --browser      # Last 12 hours in browser
python tfs-analyzer.py 6 --hours --claude --html # Last 6 hours with AI to HTML
python tfs-analyzer.py 24 --hours --text         # Last 24 hours to text
```

**Files Modified:**
- `tfs-analyzer.py` (lines 1380, 1390, 1394, 1509-1517)

---

### 2. **PowerShell Version (tfs-analyzer.ps1)**

**Changes Made:**
- Added `-Hours` switch parameter
- Updated parameter from `$Days` to `$TimeValue` (with backward compatibility)
- Added backward compatibility: if `-Days` is used, it sets `$TimeValue`
- Modified `Analyze-Tickets` function to accept `$TimeValue` and `$UseHours` parameters
- Updated WIQL query generation to handle hours:
  - For hours: Calculates exact datetime and uses `[System.ChangedDate] >= 'yyyy-MM-ddTHH:mm:ssZ'`
  - For days: Uses TFS-native `@Today - $TimeValue` syntax for better performance
- Updated all function calls to pass new parameters

**Usage Examples:**
```powershell
.\tfs-analyzer.ps1 12 -Hours -Browser       # Last 12 hours in browser
.\tfs-analyzer.ps1 6 -Hours -Claude -Html   # Last 6 hours with AI to HTML
.\tfs-analyzer.ps1 24 -Hours -Text          # Last 24 hours to text
```

**Backward Compatibility:**
```powershell
# Old syntax still works
.\tfs-analyzer.ps1 analyze -Days 7 -Browser
.\tfs-analyzer.ps1 3 -Browser               # Still interprets as 3 days
```

**Files Modified:**
- `tfs-analyzer.ps1` (lines 9-10, 19, 1756-1757, 1813-1853, 2318-2321, 2372-2381)

---

### 3. **Bash Version (tfs-analyzer.sh)**

**Changes Made:**
- Added `--hours` flag to argument parsing
- Updated variable from `$days` to `$timevalue`
- Modified `get_work_items()` function to accept two parameters: `timevalue` and `use_hours`
- Updated date calculation to handle both GNU date (Linux) and BSD date (macOS):
  - Hours: `date -d "$timevalue hours ago"` or `date -v-"${timevalue}H"`
  - Days: `date -d "$timevalue days ago"` or `date -v-"${timevalue}d"`
- Added local `$days` variable for display compatibility with existing output functions
- Updated help text with hours examples

**Usage Examples:**
```bash
./tfs-analyzer.sh 12 --hours --browser        # Last 12 hours in browser
./tfs-analyzer.sh 6 --hours --claude --html   # Last 6 hours with AI to HTML
./tfs-analyzer.sh 24 --hours --text           # Last 24 hours to text
```

**Files Modified:**
- `tfs-analyzer.sh` (lines 30-68, 577-592, 1368-1369, 1426-1428, 1500-1527)

---

## 📚 Documentation Updates

### README.md
**Changes:**
- Added hours examples to Quick Command Reference for all platforms
- Updated parameter table to include `-Hours` / `--hours` parameter
- Added usage examples showing 6, 12, and 24-hour analysis
- Updated simplified parameters table

**Examples Added:**
```bash
# Windows
.\tfs-analyzer.ps1 12 -Hours -Browser
.\tfs-analyzer.ps1 6 -Hours -Claude -Html

# Linux/Mac
./tfs-analyzer.sh 12 --hours --browser
./tfs-analyzer.sh 6 --hours --claude --html

# Python
python tfs-analyzer.py 12 --hours --browser
python tfs-analyzer.py 6 --hours --claude --html
```

### TESTING-GUIDE.md
**Changes:**
- Added "Test 3a: Hours-Based Analysis" section for Windows testing
- Added "Test 3a: Hours-Based Analysis (Bash Version)" section for Linux testing
- Updated Feature Checklist to include:
  - Hours-based time range (6, 12, 24, etc.)
  - Correct date calculations for both days and hours
- Added expected results for hours testing

**Test Cases:**
```bash
# Windows
.\tfs-analyzer.ps1 12 -Hours -Browser
.\tfs-analyzer.ps1 6 -Hours -Claude -Html
.\tfs-analyzer.ps1 24 -Hours -Text

# Linux/Mac
./tfs-analyzer.sh 12 --hours --browser
./tfs-analyzer.sh 6 --hours --claude --html
./tfs-analyzer.sh 24 --hours --text
```

---

## 🔧 Technical Implementation Details

### Date Calculation Logic

**Python (timedelta):**
```python
if use_hours:
    start_date = end_date - timedelta(hours=timevalue)
else:
    start_date = end_date - timedelta(days=timevalue)
```

**PowerShell (DateTime methods):**
```powershell
if ($UseHours) {
    $startDate = (Get-Date).AddHours(-$TimeValue).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $queryTimeFilter = "[System.ChangedDate] >= '$startDate'"
} else {
    # Use TFS-native syntax for better performance
    $queryTimeFilter = "[System.ChangedDate] >= @Today - $TimeValue"
}
```

**Bash (date command - cross-platform):**
```bash
if [[ "$use_hours" == "true" ]]; then
    # GNU date (Linux) or BSD date (macOS)
    start_date=$(date -d "$timevalue hours ago" +%Y-%m-%dT%H:%M:%S 2>/dev/null || \
                 date -v-"${timevalue}H" +%Y-%m-%dT%H:%M:%S)
else
    start_date=$(date -d "$timevalue days ago" +%Y-%m-%dT%H:%M:%S 2>/dev/null || \
                 date -v-"${timevalue}d" +%Y-%m-%dT%H:%M:%S)
fi
```

### Backward Compatibility

**PowerShell:**
```powershell
# Handle backward compatibility for -Days parameter
if ($Days -gt 0) {
    $TimeValue = $Days
}
```

**All Versions:**
- Old syntax without `-Hours` flag defaults to days
- Existing scripts continue to work without modification
- Help text updated to show both options

---

## 📊 Use Cases

### When to Use Hours-Based Analysis

1. **Rapid Development Cycles**
   - Check recent work during active development
   - Monitor tickets during a workday
   - Quick standup preparation

2. **Incident Response**
   - Track tickets created during an outage
   - Monitor recent bug reports
   - Urgent issue tracking

3. **Real-Time Monitoring**
   - Check last few hours for new assignments
   - Monitor @mentions from recent meetings
   - Track sprint progress during the day

4. **Testing and Debugging**
   - Verify ticket creation/updates immediately
   - Test automation with short timeframes
   - Debug scheduling issues

### Common Time Ranges

| Hours | Use Case |
|-------|----------|
| 1-4   | During active work session |
| 6-8   | Morning standup prep |
| 12    | Half-day review |
| 24    | Full day analysis |
| 48    | Weekend + workday |

---

## ✅ Testing Checklist

### Functional Testing
- [x] Hours parameter accepted by all three versions
- [x] Date calculations correct for hours
- [x] WIQL queries return correct time range
- [x] Output displays correct time description ("hours" vs "days")
- [x] All output methods work (browser, HTML, text, console, email)
- [x] Claude AI integration works with hours
- [x] Backward compatibility maintained (days still default)

### Cross-Platform Testing
- [x] Python version works on all platforms
- [x] PowerShell version works on Windows
- [x] Bash version date calculation handles both GNU and BSD date
- [ ] Bash version tested on actual Linux system (needs verification)
- [ ] Bash version tested on actual macOS system (needs verification)

### Edge Cases
- [x] Zero hours handled (defaults to days)
- [x] Large hour values (e.g., 168 hours = 7 days)
- [x] Hours with all output formats
- [x] Hours with Claude AI analysis
- [x] Hours with traditional analysis

---

## 🚀 Examples by Scenario

### Scenario 1: Quick Morning Check
```bash
# Check what happened overnight (last 12 hours)
.\tfs-analyzer.ps1 12 -Hours -Browser
./tfs-analyzer.sh 12 --hours --browser
python tfs-analyzer.py 12 --hours --browser
```

### Scenario 2: After-Lunch Update
```bash
# Check morning activity (last 4 hours)
.\tfs-analyzer.ps1 4 -Hours -Browser
./tfs-analyzer.sh 4 --hours --browser
python tfs-analyzer.py 4 --hours --browser
```

### Scenario 3: End of Day Summary
```bash
# Full day review (last 24 hours) with AI
.\tfs-analyzer.ps1 24 -Hours -Claude -Html
./tfs-analyzer.sh 24 --hours --claude --html
python tfs-analyzer.py 24 --hours --claude --html
```

### Scenario 4: Incident Response
```bash
# Check tickets from last 2 hours during outage
.\tfs-analyzer.ps1 2 -Hours -Browser -Details
./tfs-analyzer.sh 2 --hours --browser -d
python tfs-analyzer.py 2 --hours --browser -d
```

---

## 📝 Version Information

**Feature Added:** Version 2.2.0
**Date:** 2025-10-08
**Platforms:** Windows (PowerShell), Linux (Bash), macOS (Bash), Cross-Platform (Python)

---

## 🔄 Future Enhancements (Optional)

Potential improvements for future versions:

1. **Minutes Support** - For very rapid checking
2. **Weeks/Months** - For longer-term analysis
3. **Custom Date Ranges** - Specify exact start/end dates
4. **Scheduler Hours Support** - Schedule based on hours instead of daily
5. **Mixed Units** - e.g., "1 day 6 hours"
6. **Relative Time** - "since last run", "since yesterday 5pm"

---

## 📖 Related Documentation

- **README.md** - Updated with hours examples
- **TESTING-GUIDE.md** - Hours testing procedures added
- **IMPROVEMENTS-SUMMARY.md** - Original improvements documentation
- **CLAUDE.md** - Project guidance (no changes needed)

---

## Summary

The hours-based analysis feature is now **fully implemented** across all three versions of the TFS Ticket Analyzer:

✅ **Python**: Complete with `--hours` flag
✅ **PowerShell**: Complete with `-Hours` switch
✅ **Bash**: Complete with `--hours` flag
✅ **Documentation**: README and TESTING-GUIDE updated
✅ **Backward Compatibility**: Old syntax still works
⚠️ **Testing**: Needs verification on actual Linux/macOS systems

Users can now analyze TFS tickets by hours in addition to days, enabling more granular time-based analysis for rapid development cycles, incident response, and real-time monitoring.
