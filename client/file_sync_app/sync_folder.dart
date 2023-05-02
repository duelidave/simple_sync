import 'package:watcher/watcher.dart';

import 'sync_state.dart';

class SyncFolder {
  SyncState syncState;
  String path;
  DirectoryWatcher directoryWatcher;
  SyncFolder(this.syncState, this.path, this.directoryWatcher);
}
