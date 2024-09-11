import 'package:flutter/material.dart';

class FileSystemEntry {
  final String name;
  final String path;
  final String relativePath;
  final bool isDirectory;

  FileSystemEntry(
      {required this.name,
      required this.path,
      required this.relativePath,
      required this.isDirectory});

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['name'] = name;
    map['relativePath'] = relativePath;
    map['path'] = path;
    map['isDirectory'] = isDirectory;
    return map;
  }

  factory FileSystemEntry.fromJson(Map<String, dynamic> json) {
    String name = json['name'];
    String relativePath = json['relativePath'];
    String path = json['path'];
    bool isDirectory = json['isDirectory'];
    return FileSystemEntry(
        name: name,
        path: path,
        relativePath: relativePath,
        isDirectory: isDirectory);
  }

  factory FileSystemEntry.root() {
    return FileSystemEntry(
        isDirectory: true, name: '/', path: '/', relativePath: '/');
  }

  factory FileSystemEntry.blank() {
    return FileSystemEntry(
        isDirectory: false, name: '', path: '', relativePath: '');
  }

  @override
  bool operator ==(Object rhs) =>
      identical(this, rhs) || rhs is FileSystemEntry && path == rhs.path;

  @override
  int get hashCode => path.hashCode;
}

class FileSystemEntryStat {
  final FileSystemEntry entry;
  int lastModified;
  int size;
  int mode;

  bool get isDir => entry.isDirectory;

  FileSystemEntryStat(
      {required this.entry,
      this.lastModified = 0,
      this.size = 0,
      this.mode = 0});

  factory FileSystemEntryStat.fromJson(dynamic json) {
    final entry = FileSystemEntry.fromJson(json['entry']);
    int lastModified = json['lastModified'];
    int mode = json['mode'];
    int size = json['size'];

    return FileSystemEntryStat(
        entry: entry, lastModified: lastModified, mode: mode, size: size);
  }

  Map<String, dynamic> toJson() {
    var map = new Map<String, dynamic>();
    map['entry'] = entry.toJson();
    map['lastModified'] = lastModified;
    map['mode'] = mode;
    map['size'] = size;
    return map;
  }
}

class FileEntry extends FileSystemEntry {
  FileEntry(
      {required String name,
      required String path,
      required String relativePath})
      : super(
            name: name,
            path: path,
            relativePath: relativePath,
            isDirectory: false);
}

class FolderEntry extends FileSystemEntry {
  FolderEntry(
      {required String name,
      required String path,
      required String relativePath})
      : super(
          name: name,
          path: path,
          relativePath: relativePath,
          isDirectory: true,
        );
}

abstract class FileSystemInterface {
  const FileSystemInterface();

  Future<FileSystemEntryStat> stat(FileSystemEntry entry);

  Future<List<FileSystemEntryStat>> listContents(FileSystemEntry entry);

  Future<Widget> getThumbnail(FileSystemEntry entry,
      {double? width, double? height}) async {
    if (entry.isDirectory) {
      return Icon(Icons.folder_outlined, size: height, color: Colors.grey);
    }
    return Icon(Icons.description, size: height, color: Colors.grey);
  }

  Future<Stream<List<int>>> read(FileSystemEntry entry, {int bufferSize = 512});
}
