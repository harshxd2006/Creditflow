import 'package:intl/intl.dart';
import '../models/financial_event.dart';

class SmsParserService {
  // ==================== AMOUNT EXTRACTION ====================

  /// Extract amount from SMS body
  static double? extractAmount(String body) {
    // Patterns: ₹45,000 | Rs. 45000 | Rs 45,000.00 | INR 45000
    final patterns = [
      RegExp(r'(?:₹|rs\.?|inr)\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'([\d,]+\.?\d*)\s*(?:₹|rs\.?|inr)', caseSensitive: false),
      // Amount patterns near financial keywords
      RegExp(
        r'(?:amount|amt|payment|emi|bill|salary|credited|debited)\s*(?:of|:)?\s*(?:₹|rs\.?|inr)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0) {
            return amount;
          }
        }
      }
    }
    return null;
  }

  // ==================== BALANCE EXTRACTION ====================

  /// Extract available balance
  static double? extractBalance(String body) {
    final patterns = [
      RegExp(
        r'(?:avl\.?\s*bal|available\s*balance|avail\s*bal|bal)\s*(?:is|:)?\s*(?:₹|rs\.?|inr)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final balStr = match.group(1)?.replaceAll(',', '');
        if (balStr != null) {
          return double.tryParse(balStr);
        }
      }
    }
    return null;
  }

  // ==================== ACCOUNT ID EXTRACTION ====================

  /// Extract last 4 digits of account
  static String? extractAccountId(String body) {
    final patterns = [
      RegExp(
        r'(?:a/c|acct|account|ac)\s*(?:no\.?)?\s*(?:xx+|\.\.+|\*+)(\d{4})',
        caseSensitive: false,
      ),
      RegExp(r'(?:xx+|\.\.+|\*+)(\d{4})', caseSensitive: false),
      RegExp(r'(?:card\s*ending)\s*(\d{4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  // ==================== DATE EXTRACTION ====================

  /// Extract date from SMS body
  static DateTime? extractDateFromBody(String body) {
    final patterns = [
      // dd-MM-yyyy or dd/MM/yyyy
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      // dd-Mon-yyyy (e.g., 31-Jan-2026)
      RegExp(r'(\d{1,2})[/-]([A-Za-z]{3})[/-](\d{2,4})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        try {
          final dateStr = match.group(0)!;
          // Try different date formats
          for (final format in [
            'dd-MM-yyyy',
            'dd/MM/yyyy',
            'dd-MM-yy',
            'dd-MMM-yyyy',
            'dd/MMM/yyyy',
          ]) {
            try {
              return DateFormat(format).parse(dateStr);
            } catch (_) {}
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Extract due date specifically
  static DateTime? extractDueDate(String body) {
    final dueDatePattern = RegExp(
      r'(?:due\s*(?:date|on)?|before|by)\s*[:\-]?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}[/-][A-Za-z]{3}[/-]\d{2,4})',
      caseSensitive: false,
    );

    final match = dueDatePattern.firstMatch(body);
    if (match != null) {
      final dateStr = match.group(1)!;
      for (final format in [
        'dd-MM-yyyy',
        'dd/MM/yyyy',
        'dd-MM-yy',
        'dd-MMM-yyyy',
      ]) {
        try {
          return DateFormat(format).parse(dateStr);
        } catch (_) {}
      }
    }
    return null;
  }

  // ==================== CHANNEL EXTRACTION ====================

  static String? extractChannel(String body) {
    final lowerBody = body.toLowerCase();
    if (lowerBody.contains('upi')) return 'UPI';
    if (lowerBody.contains('imps')) return 'IMPS';
    if (lowerBody.contains('neft')) return 'NEFT';
    if (lowerBody.contains('rtgs')) return 'RTGS';
    if (lowerBody.contains('atm')) return 'ATM';
    if (lowerBody.contains('pos') || lowerBody.contains('swipe')) return 'POS';
    if (lowerBody.contains('net banking') || lowerBody.contains('netbanking'))
      return 'NETBANKING';
    if (lowerBody.contains('auto debit') || lowerBody.contains('auto-debit'))
      return 'AUTO_DEBIT';
    return null;
  }

  // ==================== COUNTERPARTY EXTRACTION ====================

  static String? extractCounterparty(String body) {
    final patterns = [
      RegExp(
        r'(?:to|from|at|via\s*upi\s*to)\s+([A-Z][A-Za-z\s]{2,20})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:merchant|payee)\s*[:\-]\s*([A-Za-z\s]{2,30})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  // ==================== EVENT CLASSIFICATION ====================

  /// Main classification: determine the event type of a financial SMS
  static String classifyEvent(String body) {
    final lowerBody = body.toLowerCase();

    // ---- SALARY ----
    if (_matchesSalary(lowerBody)) return 'SALARY_CREDIT';

    // ---- EMI BOUNCED ----
    if (_matchesEmiBounced(lowerBody)) return 'EMI_BOUNCED';

    // ---- EMI PAID ----
    if (_matchesEmiPaid(lowerBody)) return 'EMI_PAID';

    // ---- EMI DUE ----
    if (_matchesEmiDue(lowerBody)) return 'EMI_DUE';

    // ---- LOAN SANCTIONED ----
    if (_matchesLoanSanctioned(lowerBody)) return 'LOAN_SANCTIONED';

    // ---- LOAN CLOSED ----
    if (_matchesLoanClosed(lowerBody)) return 'LOAN_CLOSED';

    // ---- CREDIT CARD: BILL DUE ----
    if (_matchesCardBillDue(lowerBody)) return 'CARD_BILL_DUE';

    // ---- CREDIT CARD: MIN DUE PAID ----
    if (_matchesCardMinDuePaid(lowerBody)) return 'CARD_MIN_DUE_PAID';

    // ---- CREDIT CARD: FULL BILL PAID ----
    if (_matchesCardBillPaidFull(lowerBody)) return 'CARD_BILL_PAID_FULL';

    // ---- CREDIT CARD: LATE FEE ----
    if (_matchesCardLateFee(lowerBody)) return 'CARD_OVERLIMIT_OR_LATE_FEE';

    // ---- UTILITY BILL DUE ----
    if (_matchesUtilityBillDue(lowerBody)) return 'UTILITY_BILL_DUE';

    // ---- UTILITY BILL PAID ----
    if (_matchesUtilityBillPaid(lowerBody)) return 'UTILITY_BILL_PAID';

    // ---- CHEQUE BOUNCE ----
    if (_matchesChequeBounce(lowerBody)) return 'CHEQUE_BOUNCE';

    // ---- LOW BALANCE ----
    if (_matchesLowBalance(lowerBody)) return 'LOW_BALANCE_ALERT';

    // ---- GENERIC CREDIT ----
    if (_matchesGenericCredit(lowerBody)) return 'OTHER_INCOME_CREDIT';

    // ---- DEBIT ATM ----
    if (lowerBody.contains('atm') && lowerBody.contains('withdrawn'))
      return 'DEBIT_ATM';

    // ---- DEBIT UPI ----
    if (lowerBody.contains('upi') && _isDebit(lowerBody)) return 'DEBIT_UPI';

    // ---- GENERIC DEBIT ----
    if (_isDebit(lowerBody)) return 'DEBIT_TXN';

    // ---- BANK CHARGES ----
    if (_matchesBankCharge(lowerBody)) return 'BANK_CHARGE_DEBIT';

    // ---- PROMO (to be ignored) ----
    if (_matchesPromo(lowerBody)) return 'PROMO_OFFER';

    // ---- OTP ----
    if (_matchesOtp(lowerBody)) return 'OTP_ONLY';

    return 'UNKNOWN_FINANCIAL';
  }

  // ---- Classification helpers ----

  static bool _matchesSalary(String body) {
    return (body.contains('salary') && body.contains('credited')) ||
        (body.contains('salary') && body.contains('credit'));
  }

  static bool _matchesEmiBounced(String body) {
    return (body.contains('emi') &&
        (body.contains('bounced') ||
            body.contains('failed') ||
            body.contains('returned') ||
            body.contains('insufficient')));
  }

  static bool _matchesEmiPaid(String body) {
    return (body.contains('emi') &&
        (body.contains('paid') ||
            body.contains('received') ||
            body.contains('successful')));
  }

  static bool _matchesEmiDue(String body) {
    return (body.contains('emi') &&
        (body.contains('due') ||
            body.contains('reminder') ||
            body.contains('upcoming')));
  }

  static bool _matchesLoanSanctioned(String body) {
    return (body.contains('loan') &&
        (body.contains('sanction') ||
            body.contains('approved') ||
            body.contains('disbursed')));
  }

  static bool _matchesLoanClosed(String body) {
    return (body.contains('loan') &&
        (body.contains('closed') ||
            body.contains('no dues') ||
            body.contains('foreclosed')));
  }

  static bool _matchesCardBillDue(String body) {
    return (body.contains('card') &&
        (body.contains('statement') ||
            body.contains('total due') ||
            body.contains('amount due')) &&
        body.contains('due'));
  }

  static bool _matchesCardMinDuePaid(String body) {
    return (body.contains('card') &&
        body.contains('payment') &&
        (body.contains('minimum') || body.contains('min due')) &&
        body.contains('remaining'));
  }

  static bool _matchesCardBillPaidFull(String body) {
    return (body.contains('card') &&
        (body.contains('payment') || body.contains('received')) &&
        !body.contains('minimum') &&
        !body.contains('remaining'));
  }

  static bool _matchesCardLateFee(String body) {
    return (body.contains('card') &&
        (body.contains('late fee') ||
            body.contains('overlimit') ||
            body.contains('finance charge')));
  }

  static bool _matchesUtilityBillDue(String body) {
    final utilityKeywords = [
      'electricity',
      'water bill',
      'gas bill',
      'broadband',
      'phone bill',
      'mobile bill',
      'dth',
    ];
    bool isUtility = utilityKeywords.any((k) => body.contains(k));
    bool isDue =
        body.contains('due') ||
        body.contains('generated') ||
        body.contains('pay before');
    return isUtility &&
        isDue &&
        !body.contains('paid') &&
        !body.contains('received');
  }

  static bool _matchesUtilityBillPaid(String body) {
    final utilityKeywords = [
      'electricity',
      'water bill',
      'gas bill',
      'broadband',
      'phone bill',
      'mobile bill',
      'dth',
      'recharge',
    ];
    bool isUtility = utilityKeywords.any((k) => body.contains(k));
    bool isPaid =
        body.contains('paid') ||
        body.contains('payment received') ||
        body.contains('successful') ||
        body.contains('thank you');
    return isUtility && isPaid;
  }

  static bool _matchesChequeBounce(String body) {
    return (body.contains('cheque') || body.contains('check')) &&
        (body.contains('bounce') ||
            body.contains('returned') ||
            body.contains('dishonour'));
  }

  static bool _matchesLowBalance(String body) {
    return body.contains('balance') &&
        (body.contains('below') ||
            body.contains('low') ||
            body.contains('minimum balance'));
  }

  static bool _matchesGenericCredit(String body) {
    return body.contains('credited') && !body.contains('salary');
  }

  static bool _isDebit(String body) {
    return body.contains('debited') ||
        body.contains('deducted') ||
        body.contains('withdrawn') ||
        body.contains('spent') ||
        body.contains('paid');
  }

  static bool _matchesBankCharge(String body) {
    return body.contains('charge') ||
        body.contains('fee') ||
        body.contains('gst') ||
        body.contains('maintenance');
  }

  static bool _matchesPromo(String body) {
    return (body.contains('pre-approved') ||
            body.contains('congratulations') ||
            body.contains('offer') ||
            body.contains('click')) &&
        !body.contains('credited') &&
        !body.contains('debited');
  }

  static bool _matchesOtp(String body) {
    return body.contains('otp') ||
        body.contains('one time password') ||
        body.contains('verification code');
  }

  // ==================== BILLER NAME EXTRACTION ====================

  static String? extractBillerName(String body) {
    final lowerBody = body.toLowerCase();
    final billers = {
      'bescom': 'BESCOM',
      'bses': 'BSES',
      'tatapower': 'Tata Power',
      'airtel': 'Airtel',
      'jio': 'Jio',
      'vodafone': 'Vodafone',
      'idea': 'Idea',
      'act fibernet': 'ACT',
      'hathway': 'Hathway',
      'tata sky': 'Tata Sky',
      'dish tv': 'Dish TV',
    };

    for (final entry in billers.entries) {
      if (lowerBody.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  // ==================== MAIN PARSE FUNCTION ====================

  /// Parse a single SMS into a FinancialEvent
  static FinancialEvent parseSms({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    final eventType = classifyEvent(body);
    final amount = extractAmount(body);
    final balance = extractBalance(body);
    final accountId = extractAccountId(body);
    final channel = extractChannel(body);
    final counterparty = extractCounterparty(body);
    final dueDate = extractDueDate(body);
    final billerName = extractBillerName(body);

    // Check if minimum due
    bool? isMinDue;
    if (eventType == 'CARD_MIN_DUE_PAID') {
      isMinDue = true;
    } else if (eventType == 'CARD_BILL_PAID_FULL') {
      isMinDue = false;
    }

    return FinancialEvent(
      eventType: eventType,
      amount: amount,
      date: date,
      accountId: accountId,
      channel: channel,
      counterparty: counterparty,
      balanceAfter: balance,
      dueDate: dueDate,
      isMinimumDue: isMinDue,
      billerName: billerName,
      rawSms: body,
      sender: sender,
    );
  }
}
