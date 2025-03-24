import 'package:pttms/utils/time_utils.dart';

class RouteCardData {
  final String name;
  final String vehicleType;
  final int waitTimeInSeconds;
  final String waitTimeDisplay;
  
  // You can add more fields later if needed.

  RouteCardData({
    required this.name,
    required this.vehicleType,
    required this.waitTimeInSeconds,
  }) : waitTimeDisplay = formatWaitTime(waitTimeInSeconds);
}
