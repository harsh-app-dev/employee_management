import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../network/network_monitor.dart';

@injectable
class NetworkController {
  final NetworkMonitor _monitor;
  final ValueNotifier<NetworkStatus> status = ValueNotifier(NetworkStatus.available);

  NetworkController(this._monitor) {
    _monitor.stream.listen(handleNetworkStatus);
  }

  void handleNetworkStatus(NetworkStatus newStatus) {
    status.value = newStatus;
  }

  // Expose a stream for UI widgets (e.g., dialogs)
  Stream<NetworkStatus> get statusStream => _monitor.stream;

  // Helper: is the network available?
  bool get isConnected => status.value == NetworkStatus.available;
}