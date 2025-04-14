// lib/services/network_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkService {
  // Singleton pattern
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  // Stream controller for connectivity status
  final _connectivityStreamController = StreamController<ConnectivityResult>.broadcast();

  // Stream getters
  Stream<ConnectivityResult> get connectivityStream => _connectivityStreamController.stream;

  // Current connectivity status
  ConnectivityResult _lastResult = ConnectivityResult.none;
  ConnectivityResult get currentConnectivity => _lastResult;

  // Initialize the service
  void initialize() {
    // Get the initial connectivity status
    Connectivity().checkConnectivity().then((result) {
      _lastResult = result;
      _connectivityStreamController.add(result);
    });

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      _lastResult = result;
      _connectivityStreamController.add(result);
    });
  }

  // Check if the device has an internet connection
  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    _lastResult = result;
    return result != ConnectivityResult.none;
  }

  // Dispose resources
  void dispose() {
    _connectivityStreamController.close();
  }
}