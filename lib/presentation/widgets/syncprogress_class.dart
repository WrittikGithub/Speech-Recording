import 'dart:async';

class SyncProgress {
  static final SyncProgress _instance = SyncProgress._internal();
  factory SyncProgress() => _instance;
  SyncProgress._internal();

  final _syncProgressController = StreamController<SyncProgressState>.broadcast();
  Stream<SyncProgressState> get syncProgressStream => _syncProgressController.stream;

  int _totalItems = 0;
  int _completedItems = 0;
  bool _isSyncing = false;

  void startSync(int totalItems) {
    _totalItems = totalItems;
    _completedItems = 0;
    _isSyncing = true;
    _emitProgress();
  }

  void updateProgress() {
    _completedItems++;
    _emitProgress();
  }

  void completeSync() {
    _isSyncing = false;
    _emitProgress();
  }

  void _emitProgress() {
    _syncProgressController.add(
      SyncProgressState(
        totalItems: _totalItems,
        completedItems: _completedItems,
        isSyncing: _isSyncing,
      ),
    );
  }

  void dispose() {
    _syncProgressController.close();
  }
}

class SyncProgressState {
  final int totalItems;
  final int completedItems;
  final bool isSyncing;

  SyncProgressState({
    required this.totalItems,
    required this.completedItems,
    required this.isSyncing,
  });

  double get progress => totalItems == 0 ? 0 : completedItems / totalItems;
}