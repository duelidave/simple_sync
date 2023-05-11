import 'dart:io';

import 'package:file_sync_app/constants.dart';
import 'package:file_sync_app/helper.dart';
import 'package:watcher/watcher.dart';

import 'sync_state_model.dart';

class SyncFolder {
  SyncState syncState;
  String dir;
  late DirectoryWatcher watcher;

  SyncFolder(this.syncState, this.dir, this.watcher) {
    watchAndSync();
  }

  //function that send folder as json to server
  Future<void> syncDir() async {
    FileSystemHelper fileSystemHelper = FileSystemHelper(serverUrl: serverUrl);
    await fileSystemHelper.sendDirectoryData(Directory(dir));
  }

  //use watcher listen to changes and sync folder
  void watchAndSync() {
    watcher.events.listen((event) async {
      if (event.type == ChangeType.ADD ||
          event.type == ChangeType.MODIFY ||
          event.type == ChangeType.REMOVE) {
        await syncDir();
      }
    });
  }

  static SyncFolder fromJson(Map<String, dynamic> json) {
    final syncStateString = json['syncState'] as String;
    final dir = json['dir'] as String;

    final syncState = _syncStateFromString(syncStateString);
    final watcher = DirectoryWatcher(dir);

    return SyncFolder(syncState, dir, watcher);
  }

  Map<String, dynamic> toJson() {
    return {
      'syncState': _syncStateToString(syncState),
      'dir': dir,
    };
  }

  String _syncStateToString(SyncState state) {
    return state.toString().split('.').last;
  }

  static SyncState _syncStateFromString(String stateString) {
    return SyncState.values.firstWhere(
      (state) => state.toString().split('.').last == stateString,
      orElse: () => SyncState.notSynced,
    );
  }
}
