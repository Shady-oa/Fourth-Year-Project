// ─── SharedPreferences Keys ────────────────────────────────────────────────────
const kAiKeyTransactions = 'transactions';
const kAiKeyBudgets = 'budgets';
const kAiKeySavings = 'savings';
const kAiKeyTotalIncome = 'total_income';
const kAiKeyStreakCount = 'streak_count';
const kAiKeyStreakLevel = 'streak_level';

/// Sentinel prefix used to identify enriched messages saved by the backend.
/// Any Firestore document whose content contains this string is a
/// duplicated context bubble and must be hidden from the UI.
const kAiContextPrefix = '[USER FINANCIAL DATA CONTEXT]';
