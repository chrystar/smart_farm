import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      // Handle error
      setState(() {
        _isOnline = false;
        _showBanner = true;
      });
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOffline = !_isOnline;
    final isOnline = result != ConnectivityResult.none;

    setState(() {
      _isOnline = isOnline;
      _showBanner = !isOnline;
    });

    // Show temporary "Back online" message when reconnecting
    if (wasOffline && isOnline) {
      _showReconnectedMessage();
    }
  }

  void _showReconnectedMessage() {
    setState(() => _showBanner = true);
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isOnline) {
        setState(() => _showBanner = false);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showBanner)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 40,
            width: double.infinity,
            color: _isOnline ? Colors.green : Colors.orange.shade700,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isOnline) {
                    setState(() => _showBanner = false);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOnline
                          ? 'Back online - Syncing data...'
                          : 'You are offline - Changes will sync when reconnected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isOnline) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
