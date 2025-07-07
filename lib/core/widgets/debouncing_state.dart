import 'dart:async';

class Debouncer {
  final Duration delay;
  bool _isCoolingDown = false;

  Debouncer({this.delay = const Duration(seconds: 2)});

  bool get isCoolingDown => _isCoolingDown;

  Future<void> run(FutureOr<void> Function() action) async {
    if (_isCoolingDown) return;

    _isCoolingDown = true;
    await action();
    Future.delayed(delay, () {
      _isCoolingDown = false;
    });
  }
}
