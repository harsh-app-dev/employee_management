import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../network/network_monitor.dart';
import '../controllers/network_controller.dart';
import '../../core/di/injectable_module.dart';

class NetworkDialogHandler extends StatefulWidget {
  const NetworkDialogHandler({super.key});

  @override
  State<NetworkDialogHandler> createState() => _NetworkDialogHandlerState();
}

class _NetworkDialogHandlerState extends State<NetworkDialogHandler> {
  final controller = getIt<NetworkController>();
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NetworkStatus>(
      valueListenable: controller.status,
      builder: (context, status, _) {
        if (status == NetworkStatus.available) {
          if (_dialogShown) {
            Navigator.of(context, rootNavigator: true).pop();
            _dialogShown = false;
          }
        } else {
          if (!_dialogShown) {
            _dialogShown = true;
            Future.microtask(() {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => PopScope(
                  canPop: false,
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/svgs/no_internet.svg',
                            height: 250,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _statusMessage(status),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  String _statusMessage(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.lost:
        return "No Internet Connection";
      case NetworkStatus.unavailable:
        return "Network Unavailable";
      case NetworkStatus.losing:
        return "Connection Unstable";
      default:
        return "";
    }
  }
}