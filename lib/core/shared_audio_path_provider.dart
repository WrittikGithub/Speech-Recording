class SharedAudioPathProvider {
  static final Map<String, Map<String, String>> _audioPaths = {};

  static void setAudioPaths(String contentId, String? recordedPath, String? serverPath) {
    _audioPaths[contentId] = {
      'recorded': recordedPath ?? '',
      'server': serverPath ?? '',
    };
  }

  static String? getRecordedPath(String contentId) {
    return _audioPaths[contentId]?['recorded'];
  }

  static String? getServerPath(String contentId) {
    return _audioPaths[contentId]?['server'];
  }

  static void clearPaths(String contentId) {
    _audioPaths.remove(contentId);
  }

  static void clearAllPaths() {
    _audioPaths.clear();
  }
} 