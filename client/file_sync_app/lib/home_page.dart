import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:file_sync_app/constants.dart';
import 'package:file_sync_app/helper.dart';
import 'package:file_sync_app/sync_state_model.dart';
import 'package:flutter/material.dart';
import 'package:watcher/watcher.dart';

import 'sync_folder_model.dart';

class FileSyncHomePage extends StatefulWidget {
  const FileSyncHomePage({super.key});

  @override
  State<FileSyncHomePage> createState() => _FileSyncHomePageState();
}

class _FileSyncHomePageState extends State<FileSyncHomePage> {
  List<SyncFolder> folders = [];

  Future<void> addFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      if (folders.map((e) => e.dir).contains(selectedDirectory)) {
        return;
      }

      await for (var entity in Directory(selectedDirectory)
          .list(recursive: true, followLinks: false)) {
        print(entity.path);
      }

      FileSystemHelper fileSystemHelper =
          FileSystemHelper(serverUrl: serverUrl);
      await fileSystemHelper.sendDirectoryData(Directory(selectedDirectory));

      var watcher = DirectoryWatcher(selectedDirectory);
      watcher.events.listen((event) async => print(event));

      setState(() {
        folders
            .add(SyncFolder(SyncState.notSynced, selectedDirectory, watcher));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Sync'),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: folders.length,
            itemBuilder: (BuildContext context, int index) {
              final syncFolder = folders[index];
              return ListTile(
                title: Text(syncFolder.dir),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Remove folder'),
                        content: const Text(
                            'Are you sure you want to remove this folder?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => folders.removeAt(index));
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                leading: _buildSyncStateIcon(syncFolder.syncState),
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: addFolder,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSyncStateIcon(SyncState syncState) {
    switch (syncState) {
      case SyncState.notSynced:
        return const Icon(Icons.cloud_upload_outlined);
      case SyncState.syncingInProgress:
        return const CircularProgressIndicator();
      case SyncState.syncedSuccessfully:
        return const Icon(Icons.cloud_done);
      case SyncState.error:
        return const Icon(Icons.error_outline);
    }
  }
}
