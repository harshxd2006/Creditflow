ODO.md</path>
<content for this case.>
# TODO: Check if SMS is going to API

## Task
Help user verify/debug if SMS messages are being sent to the API successfully.

## Current Flow
SMS → SmsReaderService → SmsFilterService → SmsParserService → ApiService → API (JSONPlaceholder)

## Plan

### 1. Use Existing DemoScreen (Already Implemented)
- [x] Navigate to DemoScreen from home screen (API icon in app bar)
- [ ] Test API connection using "Test Connection" button
- [ ] Send sample SMS using "Send Sample SMS" button  
- [ ] Scan SMS using "Scan & Prepare SMS Data" button
- [ ] Send scanned events using "Send Scanned Events to API" button

### 2. Add Debug Logging to Track SMS Flow
- [ ] Add print statements in SmsReaderService to log when SMS is read
- [ ] Add print statements in SmsFilterService to log filtered results
- [ ] Add print statements in SmsParserService to log parsed events
- [ ] Add print statements in ApiService to log API requests and responses

### 3. Enhance DemoScreen to Show More Details
- [ ] Show the actual SMS data that was scanned
- [ ] Show the parsed FinancialEvent details
- [ ] Show full API response data (not just success/failure)

## How to Check SMS Flow

### Method 1: Using the DemoScreen
1. Open the app and navigate to the DemoScreen (tap API icon in home screen app bar)
2. Tap "Test Connection" - should show ✅ API Connection Successful!
3. Tap "Send Sample SMS" - should send a sample HDFC bank SMS to API
4. Tap "Scan & Prepare SMS Data" - will scan your device for financial SMS
5. Tap "Send Scanned Events to API" - will send the scanned events to API

### Method 2: Using Debug Logs
Add print statements in the code to track each step:
- In SmsReaderService: print("SMS Read: $sender - $body")
- After SmsFilterService: print("Filtered: $isFinancial")
- After SmsParserService: print("Parsed Event: $event")
- In ApiService: print("API Response: $response")

### Method 3: Check API Response Data
The ApiService returns ApiResponse with:
- success: boolean (true/false)
- message: string (details of what happened)
- data: dynamic (the actual API response data)

You can display this data in the UI to see what's being sent and received.
