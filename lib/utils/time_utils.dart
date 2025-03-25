String formatWaitTime(int seconds) {
  // If the wait time is less than 60 seconds, return "1 min".
  // Otherwise, divide by 60 and round to the nearest minute.
  int minutes = seconds < 60 ? 1 : (seconds / 60).round();
  return '$minutes min';
}

String formatTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period'; // e.g. "10:05 AM"
}