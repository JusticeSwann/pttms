String formatWaitTime(int seconds) {
  // If the wait time is less than 60 seconds, return "1 min".
  // Otherwise, divide by 60 and round to the nearest minute.
  int minutes = seconds < 60 ? 1 : (seconds / 60).round();
  return '$minutes min';
}
