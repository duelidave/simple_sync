import 'package:watcher/watcher.dart';

import 'sync_state_model.dart';

class SyncFolder {
  SyncState syncState;
  String dir;
  DirectoryWatcher watcher;

  SyncFolder(this.syncState, this.dir, this.watcher);
}
