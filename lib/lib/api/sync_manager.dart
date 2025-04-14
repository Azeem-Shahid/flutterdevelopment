// lib/services/sync_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'database_helper_api.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncManager {
  // Singleton pattern
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();

  // Stream getter
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // Initialize the sync manager and set up auto-sync
  void initialize(BuildContext context) {
    print("Initializing SyncManager...");

    // Listen for connectivity changes and try to sync when connected
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _syncData(context);
      }
    });

    // Schedule periodic sync attempts
    _startPeriodicSync(context);

    // Try to sync immediately if connected
    _checkAndSync(context);
  }

  // Start periodic sync attempts
  void _startPeriodicSync(BuildContext context) {
    // Cancel any existing timer
    _syncTimer?.cancel();

    // Create a new timer for sync attempts every 15 minutes
    _syncTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      _checkAndSync(context);
    });
  }

  // Check connectivity and sync if online
  Future<void> _checkAndSync(BuildContext context) async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    if (result != ConnectivityResult.none) {
      await _syncData(context);
    }
  }

  // Sync data with the server
  Future<bool> _syncData(BuildContext context) async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus(isSyncing: true, message: 'Syncing data...'));

    try {
      // Check if we have unsynced data
      int unsyncedCount = await _dbHelper.getUnsyncedCount();

      if (unsyncedCount <= 0) {
        _isSyncing = false;
        _syncStatusController.add(SyncStatus(
            isSyncing: false,
            message: 'No data to sync',
            success: true
        ));
        return true;
      }

      // Attempt to sync
      final syncResult = await _dbHelper.syncAllWithApi();

      if (syncResult['success']) {
        _syncStatusController.add(SyncStatus(
            isSyncing: false,
            message: syncResult['message'],
            success: true,
            syncedCount: syncResult['count'],
            failedCount: syncResult['total'] - syncResult['count']
        ));

        // Show a snackbar if context is available and we synced something
        if (context.mounted && syncResult['count'] > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synced ${syncResult['count']} of ${syncResult['total']} results'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(10),
            ),
          );
        }

        return true;
      } else {
        _syncStatusController.add(SyncStatus(
            isSyncing: false,
            message: syncResult['message'],
            success: false
        ));
        return false;
      }
    } catch (e) {
      print('Sync error: $e');
      _syncStatusController.add(SyncStatus(
          isSyncing: false,
          message: 'Sync error: ${e.toString()}',
          success: false
      ));
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Manual sync triggered by user
  Future<bool> manualSync(BuildContext context) async {
    bool isOnline = await _isConnected();
    if (!isOnline) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot sync: No internet connection'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
          ),
        );
      }
      return false;
    }

    return await _syncData(context);
  }

  // Check if connected
  Future<bool> _isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}

class SyncStatus {
  final bool isSyncing;
  final String message;
  final bool success;
  final int syncedCount;
  final int failedCount;

  SyncStatus({
    required this.isSyncing,
    required this.message,
    this.success = true,
    this.syncedCount = 0,
    this.failedCount = 0
  });
}