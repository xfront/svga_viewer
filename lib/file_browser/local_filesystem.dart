import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:chunked_stream/chunked_stream.dart';
import 'semaphore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imageLib;
import 'package:path/path.dart' as path;
import 'filesystem_interface.dart';

final _semaphore = Semaphore(max(Platform.numberOfProcessors - 1, 1));

class LocalFileSystem extends FileSystemInterface {
  const LocalFileSystem();

  @override
  Future<Widget> getThumbnail(FileSystemEntry entry,
      {double? width, double? height}) async {
    if (!entry.isDirectory) {
      final ext = path.extension(entry.name).toLowerCase();
      if (ext == '.png' || ext == '.jpg' || ext == '.jpeg') {
        await _semaphore.acquire();
        final bytes = await compute(getThumbnailFromFile,
            ComputeArguments(path: entry.path, width: width, height: height));
        _semaphore.release();
        return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain);
      }
    }
    return super.getThumbnail(entry, width: width, height: height);
  }

  @override
  Future<FileSystemEntryStat> stat(FileSystemEntry entry) async {
    if (entry.isDirectory) {
      final stat = await Directory(entry.path).stat();
      return FileSystemEntryStat(
          entry: entry,
          lastModified: stat.modified.millisecondsSinceEpoch,
          size: stat.size,
          mode: stat.mode);
    } else {
      final stat = await File(entry.path).stat();
      return FileSystemEntryStat(
          entry: entry,
          lastModified: stat.modified.millisecondsSinceEpoch,
          size: stat.size,
          mode: stat.mode);
    }
  }

  @override
  Future<List<FileSystemEntryStat>> listContents(FileSystemEntry entry) {
    var files = <FileSystemEntryStat>[];
    var completer = Completer<List<FileSystemEntryStat>>();
    final dir = Directory(entry.path);
    var lister = dir.list(recursive: false);
    lister.listen((file) async {
      final name = path.basename(file.path);
      final relativePath = path.join(entry.relativePath, name);
      var child = FileSystemEntry.blank();
      if (File(file.path).existsSync()) {
        child =
            FileEntry(name: name, path: file.path, relativePath: relativePath);
      } else if (Directory(file.path).existsSync()) {
        child = FolderEntry(
            name: name, path: file.path, relativePath: relativePath);
      }
      files.add(await stat(child));
    },
        // should also register onError
        onDone: () => completer.complete(files));
    return completer.future;
  }

  @override
  Future<Stream<List<int>>> read(FileSystemEntry entry,
      {int bufferSize = 512}) async {
    final stream = bufferChunkedStream(new File(entry.path).openRead(),
        bufferSize: bufferSize);
    return stream;
  }
}

FutureOr<List<int>> getThumbnailFromFile(ComputeArguments args) async {
  final image = imageLib.decodeImage(new File(args.path).readAsBytesSync());
  if (image != null) {
    // Resize the image to a thumbnail (maintaining the aspect ratio).
    int? rw, rh;
    if (args.width != null) {
      rw = args.width!.round();
    }
    if (args.height != null) {
      rh = args.height!.round();
    }
    final thumbnail = imageLib.copyResize(image, width: rw, height: rh);
    final bytes = imageLib.encodePng(thumbnail);
    return bytes;
  } else {
    throw 'Error decoding image';
  }
}

class ComputeArguments {
  final String path;
  final double? width;
  final double? height;

  ComputeArguments(
      {required this.path, required this.width, required this.height});
}
