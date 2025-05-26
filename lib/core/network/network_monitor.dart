import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

enum NetworkStatus { available, losing, lost, unavailable }

@lazySingleton
class NetworkMonitor {
  final ValueNotifier<NetworkStatus> status = ValueNotifier(
    NetworkStatus.available,
  );
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkStatus get currentStatus => status.value;

  // Fixed: Provide a stream of status changes
  Stream<NetworkStatus> get stream async* {
    yield status.value;
    final controller = StreamController<NetworkStatus>();
    void listener() => controller.add(status.value);
    status.addListener(listener);
    controller.onCancel = () => status.removeListener(listener);
    yield* controller.stream;
  }

  Future<void> init() async {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      _onStatusChange(result);
    });
    await _checkInitialConnection();
  }

  void _onStatusChange(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
        status.value = NetworkStatus.available;
        break;
      case ConnectivityResult.none:
        status.value = NetworkStatus.lost;
        break;
      default:
        status.value = NetworkStatus.unavailable;
    }
  }

  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _onStatusChange(result);
  }

  void dispose() {
    _subscription?.cancel();
    status.dispose();
  }
}
