import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class FileSystemHelper {
  final String serverUrl;

  FileSystemHelper({required this.serverUrl});

  Future<Map<String, dynamic>> directoryToJson(Directory directory) async {
    Map<String, dynamic> jsonMap = {};

    List<FileSystemEntity> entities = await directory.list().toList();
    for (FileSystemEntity entity in entities) {
      if (entity is File) {
        String fileName = entity.path.split('/').last;
        int fileSize = await entity.length();

        List<int> fileBytes = await entity.readAsBytes();
        Digest hashSum = sha256.convert(fileBytes);

        jsonMap[fileName] = {
          'type': 'file',
          'uuid': const Uuid().v4(),
          'name': fileName,
          'hashsum': hashSum.toString(),
        };
      } else if (entity is Directory) {
        String dirName = entity.path.split('/').last;
        jsonMap[dirName] = {
          'type': 'directory',
          'uuid': const Uuid().v4(),
          'name': dirName,
          'children': await directoryToJson(entity),
        };
      }
    }

    return jsonMap;
  }

  void sendData(Map<String, dynamic> data) async {
    WebSocket ws = await WebSocket.connect(serverUrl);
    ws.add(json.encode(data));
    ws.close();
  }

  Future<void> sendDirectoryData(Directory directory) async {
    Map<String, dynamic> directoryData = await directoryToJson(directory);
    sendData(directoryData);
  }
}

