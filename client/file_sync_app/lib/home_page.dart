import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:file_sync_app/sync_state_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watcher/watcher.dart';

import 'sync_folder_model.dart';

class FileSyncHomePage extends StatefulWidget {
  const FileSyncHomePage({super.key});

  @override
  State<FileSyncHomePage> createState() => _FileSyncHomePageState();
}

class _FileSyncHomePageState extends State<FileSyncHomePage> {
  List<SyncFolder> folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

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

      var watcher = DirectoryWatcher(selectedDirectory);
      watcher.events.listen((event) async => print(event));

      var syncFolder = SyncFolder(
        SyncState.notSynced,
        selectedDirectory,
        watcher,
      );

      final prefs = await SharedPreferences.getInstance();
      setState(() {
        folders.add(syncFolder);
        prefs.setStringList(
          'folders',
          folders.map((e) => jsonEncode(e)).toList(),
        );
      });
    }
  }

  Widget _buildFolderTile(BuildContext context, int index) {
    final syncFolder = folders[index];
    return ListTile(
      title: Text(syncFolder.dir),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSyncButton(context, index),
          _buildDeleteButton(context, index),
        ],
      ),
      leading: _buildSyncStateIcon(syncFolder.syncState),
    );
  }

  Widget _buildSyncButton(BuildContext context, int index) {
    return IconButton(
      icon: const Icon(Icons.sync),
      color: Colors.blue,
      onPressed: () {
        setState(() => folders[index].syncState = SyncState.syncingInProgress);
        folders[index].syncDir().then((_) {
          setState(
              () => folders[index].syncState = SyncState.syncedSuccessfully);
        }).catchError((error) {
          print(error);
          setState(() => folders[index].syncState = SyncState.error);
        });
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context, int index) {
    return IconButton(
      icon: const Icon(Icons.delete),
      color: Colors.red,
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              _buildRemoveFolderDialog(context, index),
        );
      },
    );
  }

  Widget _buildRemoveFolderDialog(BuildContext context, int index) {
    return AlertDialog(
      title: const Text('Remove folder'),
      content: const Text('Are you sure you want to remove this folder?'),
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
    );
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
            itemBuilder: (BuildContext context, int index) =>
                _buildFolderTile(context, index),
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

  Future<void> _loadFolders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final folderList = prefs.getStringList('folders');
    if (folderList != null) {
      setState(() {
        folders = folderList.map((folderJson) {
          final folderData = jsonDecode(folderJson) as Map<String, dynamic>;
          return SyncFolder.fromJson(folderData);
        }).toList();
      });
    }
  }

  // void _loadFolders() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     folders = prefs.getStringList('folders')?.map((e) {
  //           final map = jsonDecode(e);
  //           return SyncFolder.fromJson(map);
  //         }).toList() ??
  //         [];
  //   });
  // }
}
