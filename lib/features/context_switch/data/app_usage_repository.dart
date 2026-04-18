import 'package:flutter/services.dart';

class AppUsageRepository {
  static const MethodChannel _channel = MethodChannel('com.scoders.lumina/monitor');

  /// Check if the user has granted Usage Access permissions
  Future<bool> checkUsagePermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkUsagePermission');
      print("CheckUsagePermission result: \$hasPermission");
      return hasPermission;
    } on PlatformException catch (e) {
      print("Platform Exception in checkUsagePermission: \${e.message}");
      return false;
    } catch (e) {
      print("Unknown Error in checkUsagePermission: \$e");
      return false;
    }
  }

  /// Redirect user to the Android settings page to grant Usage Access
  Future<bool> requestUsagePermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
      return true;
    } on PlatformException catch (e) {
      print("Failed to request usage permission: \${e.message}");
      return false;
    } catch (e) {
      print("Unknown Error in requestUsagePermission (Did you rebuild native code?): \$e");
      return false;
    }
  }

  /// Get the package name & timestamp of the latest app opened in the foreground
  Future<Map<String, dynamic>?> getLatestForegroundApp() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getLatestForegroundApp');
      if (result != null) {
        return {
          'packageName': result['packageName'] as String,
          'timestamp': result['timestamp'] as int,
        };
      }
    } on PlatformException catch (_) {
      // Typically fires if permission isn't granted or no events found
      return null;
    }
    return null;
  }

  /// Get all apps opened in the foreground since a specific timestamp
  Future<List<String>> getForegroundAppsSince(int startTimeMillis) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getForegroundAppsSince', {'startTime': startTimeMillis});
      if (result != null) {
        return result.cast<String>();
      }
    } on PlatformException catch (_) {
      return [];
    }
    return [];
  }
}
