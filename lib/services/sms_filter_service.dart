class SmsFilterService {
  // Financial sender patterns - these are typical Indian bank/financial sender IDs
  // They usually start with XX- or XD- or XM- followed by bank code
  static final List<RegExp> _financialSenderPatterns = [
    // Bank sender IDs (e.g., AD-SBIINB, BZ-HDFCBK, etc.)
    RegExp(r'^[A-Z]{2}-[A-Z]{4,}', caseSensitive: false),
    // Sender IDs with bank names
    RegExp(
      r'(SBI|HDFC|ICICI|AXIS|PNB|BOB|BOI|KOTAK|IDBI|CANARA|UNION|INDIAN|YES)',
      caseSensitive: false,
    ),
    // UPI related
    RegExp(r'(PAYTM|PHONEPE|GPAY|BHIM|UPI|RAZORPAY)', caseSensitive: false),
    // Credit card / NBFC
    RegExp(r'(AMEX|VISA|MASTER|BAJAJ|TATA|CRED|SLICE)', caseSensitive: false),
    // Utility companies
    RegExp(
      r'(BESCOM|BSES|TATAPOWER|AIRTEL|JIO|VODAFONE|IDEA)',
      caseSensitive: false,
    ),
    // Wallet / fintech
    RegExp(
      r'(AMAZON|FLIPKART|LAZYPAY|SIMPL|FREECHARGE|MOBIKWIK)',
      caseSensitive: false,
    ),
  ];

  // Keywords that indicate financial SMS
  static final List<String> _financialKeywords = [
    'credited',
    'debited',
    'transferred',
    'withdrawn',
    'balance',
    'avl bal',
    'available balance',
    'a/c',
    'acct',
    'account',
    'emi',
    'loan',
    'installment',
    'credit card',
    'card ending',
    'bill',
    'due date',
    'payment',
    'salary',
    'neft',
    'imps',
    'rtgs',
    'upi',
    'txn',
    'transaction',
    'insufficient',
    'bounced',
    'failed',
    'statement',
    'minimum due',
    'min due',
    'fd',
    'fixed deposit',
    'electricity',
    'water bill',
    'gas bill',
    'recharge',
  ];

  // Keywords that indicate noise (to be filtered out)
  static final List<String> _noiseKeywords = [
    'otp',
    'one time password',
    'verification code',
    'offer',
    'cashback offer',
    'pre-approved',
    'congratulations',
    'you are selected',
    'click here',
    'apply now',
    'download',
    'promo',
    'discount',
    'sale',
    'subscribe',
    'unsubscribe',
  ];

  /// Check if a sender looks like a financial institution
  static bool isFinancialSender(String sender) {
    for (final pattern in _financialSenderPatterns) {
      if (pattern.hasMatch(sender)) {
        return true;
      }
    }
    return false;
  }

  /// Check if the SMS body contains financial content
  static bool hasFinancialContent(String body) {
    final lowerBody = body.toLowerCase();

    // First check if it's noise
    for (final keyword in _noiseKeywords) {
      if (lowerBody.contains(keyword)) {
        // Check if it's ONLY an OTP/promo (no financial content)
        bool hasFinancial = false;
        for (final fKeyword in _financialKeywords) {
          if (lowerBody.contains(fKeyword)) {
            hasFinancial = true;
            break;
          }
        }
        if (!hasFinancial) return false;
      }
    }

    // Check for financial keywords
    for (final keyword in _financialKeywords) {
      if (lowerBody.contains(keyword)) {
        return true;
      }
    }

    // Check for amount patterns (₹ or Rs or INR followed by numbers)
    final amountPattern = RegExp(
      r'(₹|rs\.?|inr)\s*[\d,]+\.?\d*',
      caseSensitive: false,
    );
    if (amountPattern.hasMatch(body)) {
      return true;
    }

    return false;
  }

  /// Main filter: returns true if this SMS should be kept for analysis
  static bool isFinancialSms(String sender, String body) {
    // Must pass either sender check or content check (preferably both)
    bool senderMatch = isFinancialSender(sender);
    bool contentMatch = hasFinancialContent(body);

    // If sender is financial, we keep it (even if content check is uncertain)
    if (senderMatch && contentMatch) return true;

    // If only content matches strongly, keep it
    if (contentMatch) return true;

    return false;
  }

  /// Check if SMS is pure OTP (should be ignored)
  static bool isOtpOnly(String body) {
    final lowerBody = body.toLowerCase();
    final hasOtp =
        lowerBody.contains('otp') ||
        lowerBody.contains('one time password') ||
        lowerBody.contains('verification code');

    // Check if it ALSO has financial info (some OTP messages include balance)
    final hasAmount = RegExp(
      r'(₹|rs\.?|inr)\s*[\d,]+\.?\d*',
      caseSensitive: false,
    ).hasMatch(body);
    final hasBalance =
        lowerBody.contains('balance') || lowerBody.contains('avl bal');

    // Pure OTP = has OTP keyword but no financial data
    return hasOtp && !hasAmount && !hasBalance;
  }
}
