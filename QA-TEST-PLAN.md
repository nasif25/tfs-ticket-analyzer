# TFS Ticket Analyzer - QA Test Plan

**Test Date:** 2025-10-08
**Tester Role:** Senior Quality Engineer
**Test Scope:** Full functional testing of all components
**Test Environment:** Windows (MSYS_NT-10.0-22631)

---

## Test Strategy

### Testing Approach
- **Black Box Testing**: Test user-facing functionality
- **Boundary Testing**: Test edge cases and limits
- **Negative Testing**: Test error handling
- **Integration Testing**: Test component interactions
- **Cross-Platform Testing**: Verify consistency across platforms

### Test Categories
1. Setup & Configuration
2. Parameter Parsing & Validation
3. Authentication Methods
4. Work Item Retrieval
5. Priority Calculation
6. Output Generation
7. Error Handling
8. Automation/Scheduling
9. Cross-Platform Consistency

---

## Test Execution Log

### Category 1: Setup & Configuration

#### Test 1.1: Easy Setup Wizard - Happy Path
**Status:** PENDING
**Steps:**
1. Run `.\easy-setup.ps1`
2. Enter valid TFS URL
3. Enter valid project name
4. Choose authentication method
5. Enter display name
6. Choose output method
7. Skip automation

**Expected:** Setup completes successfully, config file created

---

#### Test 1.2: Easy Setup - Invalid URL Validation
**Status:** PENDING
**Test Data:**
- Empty URL
- URL without protocol (dev.azure.com)
- Invalid characters in URL

**Expected:** Validation errors shown, user prompted to re-enter

---

#### Test 1.3: Easy Setup - Invalid Project Name
**Status:** PENDING
**Test Data:**
- Empty project name
- Whitespace only

**Expected:** Validation errors shown, user prompted to re-enter

---

#### Test 1.4: Easy Setup - Invalid Time Format
**Status:** PENDING
**Test Data:**
- 25:00 (invalid hour)
- 12:70 (invalid minute)
- 8:5 (should accept and normalize)
- abc:def (non-numeric)

**Expected:** Validation errors for invalid, acceptance and normalization for valid

---

#### Test 1.5: Manual Setup via tfs-analyzer.ps1 setup
**Status:** PENDING
**Steps:**
1. Run `.\tfs-analyzer.ps1 setup`
2. Complete interactive setup

**Expected:** Setup wizard runs, config created

---

### Category 2: Parameter Parsing

#### Test 2.1: PowerShell Parameters - Valid Combinations
**Status:** PENDING
**Test Cases:**
```powershell
.\tfs-analyzer.ps1 1 -Browser
.\tfs-analyzer.ps1 3 -Html
.\tfs-analyzer.ps1 7 -Text
.\tfs-analyzer.ps1 1 -Email
.\tfs-analyzer.ps1 1 -Claude -Browser
.\tfs-analyzer.ps1 3 -NoAI -Html
.\tfs-analyzer.ps1 1 -Details
.\tfs-analyzer.ps1 12 -Hours -Browser
```

**Expected:** All commands parse correctly

---

#### Test 2.2: Bash Parameters - Valid Combinations
**Status:** PENDING
**Test Cases:**
```bash
./tfs-analyzer.sh 1 --browser
./tfs-analyzer.sh 3 --html
./tfs-analyzer.sh 7 --text
./tfs-analyzer.sh 1 --email
./tfs-analyzer.sh 1 --claude --browser
./tfs-analyzer.sh 3 --no-ai --html
./tfs-analyzer.sh 1 -d
./tfs-analyzer.sh 12 --hours --browser
```

**Expected:** All commands parse correctly

---

#### Test 2.3: Python Parameters - Valid Combinations
**Status:** PENDING
**Test Cases:**
```bash
python tfs-analyzer.py 1 --browser
python tfs-analyzer.py 3 --html
python tfs-analyzer.py 7 --text
python tfs-analyzer.py 1 --email
python tfs-analyzer.py 1 --claude --browser
python tfs-analyzer.py 3 --no-ai --html
python tfs-analyzer.py 1 -d
python tfs-analyzer.py 12 --hours --browser
```

**Expected:** All commands parse correctly

---

#### Test 2.4: Invalid Parameters - Error Handling
**Status:** PENDING
**Test Cases:**
```powershell
.\tfs-analyzer.ps1 1 -InvalidFlag
.\tfs-analyzer.ps1 -Browser  # Missing timevalue
.\tfs-analyzer.ps1 abc -Browser  # Non-numeric timevalue
```

**Expected:** Clear error messages, help displayed

---

### Category 3: Authentication

#### Test 3.1: Test-Auth Command - No Configuration
**Status:** PENDING
**Steps:**
1. Delete `.config` directory
2. Run test-auth command

**Expected:** Clear error about missing configuration

---

#### Test 3.2: Test-Auth Command - With Valid Config
**Status:** PENDING
**Prerequisites:** Valid config file exists
**Steps:**
1. Run `.\tfs-analyzer.ps1 test-auth`
2. Run `./tfs-analyzer.sh test-auth`
3. Run `python tfs-analyzer.py --test-auth`

**Expected:** Authentication succeeds or fails with clear message

---

#### Test 3.3: Azure CLI Authentication
**Status:** PENDING
**Prerequisites:** Azure CLI installed and logged in
**Steps:**
1. Ensure `az login --allow-no-subscriptions` completed
2. Run analyzer without PAT in config

**Expected:** Uses Azure CLI for authentication

---

#### Test 3.4: PAT Authentication
**Status:** PENDING
**Prerequisites:** Valid PAT in config
**Steps:**
1. Configure PAT
2. Run analyzer

**Expected:** Uses PAT for authentication

---

### Category 4: Work Item Retrieval

#### Test 4.1: Retrieve Work Items - Days
**Status:** PENDING
**Test Cases:**
- 1 day
- 7 days
- 30 days
- 365 days

**Expected:** Correct date range queried

---

#### Test 4.2: Retrieve Work Items - Hours
**Status:** PENDING
**Test Cases:**
```powershell
.\tfs-analyzer.ps1 1 --hours -Browser
.\tfs-analyzer.ps1 12 --hours -Browser
.\tfs-analyzer.ps1 24 --hours -Browser
```

**Expected:** Correct hour range queried

---

#### Test 4.3: Empty Results Handling
**Status:** PENDING
**Test:** Query for time period with no work items
**Expected:** Graceful message, no errors

---

### Category 5: Priority Calculation

#### Test 5.1: Priority Factors - State
**Status:** PENDING
**Test Data:**
- State: "In Progress" → High priority
- State: "New" → Medium priority
- State: "Done" → Low priority

**Expected:** Correct priority scoring

---

#### Test 5.2: Priority Factors - Type
**Status:** PENDING
**Test Data:**
- Type: "Bug" → High priority boost
- Type: "Task" → Medium priority
- Type: "Epic" → Lower priority

**Expected:** Correct type weighting

---

#### Test 5.3: Priority Factors - Keywords
**Status:** PENDING
**Test Data:**
- Title contains "SHOWSTOPPER" → High priority
- Title contains "ERROR" → Medium boost
- Title contains normal text → No boost

**Expected:** Keyword detection works

---

#### Test 5.4: Priority Field Values
**Status:** PENDING
**Test Data:**
- Priority: 1 → High score
- Priority: 2 → Medium score
- Priority: 4 → Low score

**Expected:** Priority field properly weighted

---

### Category 6: Output Generation

#### Test 6.1: Console Output - Traditional Analysis
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 1 --no-ai`
**Expected:**
- Summary displayed in console
- Work items listed
- Priority levels shown
- No errors

---

#### Test 6.2: HTML Output - Traditional Analysis
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 1 -Html --no-ai`
**Expected:**
- HTML file created in Documents or Downloads
- File contains valid HTML
- Work items displayed correctly
- Formatting is readable

---

#### Test 6.3: Browser Output - Traditional Analysis
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 1 -Browser --no-ai`
**Expected:**
- HTML file created
- Browser opens automatically
- Report displays correctly

---

#### Test 6.4: Text Output - Traditional Analysis
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 1 -Text --no-ai`
**Expected:**
- Text file created
- Readable plain text format
- All key information included

---

#### Test 6.5: Debug Output
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 1 -Details -Browser`
**Expected:**
- Debug file created: `TFS-Debug-Data.txt`
- Contains detailed work item data
- Shows all available fields
- Includes comments

---

### Category 7: Claude AI Integration

#### Test 7.1: Claude Setup
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 setup-claude`
**Expected:**
- Guided setup process
- Tests Claude availability
- Tests authentication
- Creates config file

---

#### Test 7.2: Claude Analysis - Success Path
**Status:** PENDING
**Prerequisites:** Claude configured
**Command:** `.\tfs-analyzer.ps1 1 -Claude -Browser`
**Expected:**
- Claude analysis executes
- Enhanced insights included
- Report shows AI enhancement badge

---

#### Test 7.3: Claude Analysis - Fallback
**Status:** PENDING
**Test:** Run with Claude enabled but Claude unavailable
**Expected:**
- Falls back to traditional analysis
- Clear message about fallback
- Analysis still completes successfully

---

#### Test 7.4: Test-Claude Command
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 test-claude`
**Expected:**
- Tests Claude Code CLI availability
- Tests authentication
- Tests MCP server connection
- Provides clear diagnostic results

---

### Category 8: Error Handling

#### Test 8.1: Network Timeout
**Status:** PENDING
**Test:** Disconnect network during execution
**Expected:** Timeout error with helpful message

---

#### Test 8.2: Invalid TFS URL
**Status:** PENDING
**Test:** Configure with non-existent TFS server
**Expected:** Connection error with troubleshooting steps

---

#### Test 8.3: Invalid Project Name
**Status:** PENDING
**Test:** Configure with non-existent project
**Expected:** Project not found error

---

#### Test 8.4: Expired/Invalid PAT
**Status:** PENDING
**Test:** Configure with invalid PAT
**Expected:** Authentication error with re-auth instructions

---

#### Test 8.5: Missing Configuration File
**Status:** PENDING
**Test:** Delete config, run analyzer
**Expected:** Clear message to run setup

---

#### Test 8.6: Malformed Configuration File
**Status:** PENDING
**Test:** Corrupt config file
**Expected:** Error detected, suggestion to re-run setup

---

### Category 9: Scheduler/Automation

#### Test 9.1: Daily Scheduler Setup - PowerShell
**Status:** PENDING
**Command:** `.\tfs-scheduler-daily.ps1 -Time "09:00" -OutputMethod browser`
**Expected:**
- Task created in Windows Task Scheduler
- Task shows correct time
- Task points to correct script

---

#### Test 9.2: Daily Scheduler - Remove
**Status:** PENDING
**Command:** `.\tfs-scheduler-daily.ps1 -Remove`
**Expected:** Task removed from scheduler

---

#### Test 9.3: Smart Scheduler
**Status:** PENDING
**Command:** `.\tfs-scheduler-smart.ps1 -OutputMethod browser`
**Expected:**
- Logon trigger created
- Script executes once per day

---

#### Test 9.4: Bash Scheduler Setup
**Status:** PENDING
**Command:** `./tfs-scheduler.sh --time 09:00 --output browser`
**Expected:**
- Cron job created
- Correct time configured
- Correct output method

---

### Category 10: Cross-Platform Consistency

#### Test 10.1: Same Config, Different Platforms
**Status:** PENDING
**Test:**
1. Create config on Windows
2. Copy to Linux
3. Run analyzer on both

**Expected:** Both produce equivalent results

---

#### Test 10.2: Parameter Equivalence
**Status:** PENDING
**Test:** Run equivalent commands:
```powershell
.\tfs-analyzer.ps1 3 -Browser
```
```bash
./tfs-analyzer.sh 3 --browser
```
```python
python tfs-analyzer.py 3 --browser
```

**Expected:** All produce same analysis results

---

### Category 11: Edge Cases & Boundaries

#### Test 11.1: Zero Days
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 0 -Browser`
**Expected:** Error or treats as today

---

#### Test 11.2: Negative Days
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 -1 -Browser`
**Expected:** Error with clear message

---

#### Test 11.3: Large Number of Days
**Status:** PENDING
**Command:** `.\tfs-analyzer.ps1 1000 -Browser`
**Expected:** Works or gives reasonable limit message

---

#### Test 11.4: Very Long Work Item Titles
**Status:** PENDING
**Test:** Work item with 500+ character title
**Expected:** Handles gracefully, no truncation errors

---

#### Test 11.5: Special Characters in Work Items
**Status:** PENDING
**Test Data:**
- Titles with quotes, apostrophes
- Unicode characters
- HTML entities

**Expected:** Displays correctly in all output formats

---

#### Test 11.6: Empty Work Item Fields
**Status:** PENDING
**Test:** Work item with minimal fields
**Expected:** No null reference errors

---

## Test Environment Setup

### Prerequisites Checklist
- [ ] Windows 10/11 with PowerShell 5.1+
- [ ] Python 3.7+ installed
- [ ] Git Bash or WSL for Bash testing
- [ ] Azure CLI installed (optional)
- [ ] Valid TFS/Azure DevOps environment
- [ ] Test project with sample work items
- [ ] Valid PAT token
- [ ] Claude Code CLI (optional)

---

## Test Execution Priority

### P0 - Critical (Must Pass)
- Setup and configuration
- Parameter parsing
- Authentication (at least one method)
- Work item retrieval
- Basic output generation (console/HTML)
- Error handling for common issues

### P1 - High (Should Pass)
- Claude AI integration
- All output formats
- Hours feature
- Scheduler setup
- Debug mode
- Cross-platform consistency

### P2 - Medium (Nice to Have)
- Edge cases
- Boundary conditions
- Performance testing
- Stress testing

---

## Test Results Summary

**Total Tests Planned:** 60+
**Tests Executed:** 0
**Tests Passed:** 0
**Tests Failed:** 0
**Tests Blocked:** 0
**Coverage:** TBD

---

## Issues Log

*Issues will be logged here as testing progresses*

---

**Test Plan Created By:** Senior QA Engineer (Claude)
**Status:** DRAFT - Ready for Execution
**Next Step:** Begin test execution starting with P0 tests
