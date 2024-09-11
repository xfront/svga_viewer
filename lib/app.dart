import 'dart:convert';
import 'dart:io';

import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svga_viewer/path_view.dart';
import 'package:svga_viewer/svgaplayer.dart';
import 'file_browser/controllers/file_browser.dart';
import 'file_browser/file_browser.dart';
import 'file_browser/filesystem_interface.dart';
import 'file_browser/local_filesystem.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  /// Necessary when resizing the app so the tree view example inside the
  /// main view doesn't loose its tree states.
  static const treeViewKey = GlobalObjectKey('<TreeViewKey>');
  static const mainViewKey = GlobalObjectKey('<MainViewKey>');

  final controller = ResizableController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PreferredSizeWidget? appBar;
    Widget? body;
    Widget? drawer;

    Get.put(tag: "file_list", permanent: true, <File>[].obs);

    if (MediaQuery.of(context).size.width > 720) {
      body = ResizableContainer(
        controller: controller,
        direction: Axis.horizontal,
        children: const [
          ResizableChild(
              size: ResizableSize.ratio(0.3),
              child: FileTreeView(key: treeViewKey)),
          ResizableChild(
              size: ResizableSize.ratio(0.7),
              child: SvgaFileListView(key: mainViewKey)),
        ],
      );
    } else {
      appBar = AppBar(
        title: const Text('SVGA Viewer'),
        notificationPredicate: (_) => false,
        titleSpacing: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      );
      body = const SvgaFileListView(key: mainViewKey);
      drawer = const Drawer(child: FileTreeView(key: treeViewKey));
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      drawer: drawer,
    );
  }
}

FileSystemEntryStat? rootEntry;

class FileTreeView extends StatelessWidget {
  final fs = const LocalFileSystem();

  const FileTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([checkAndRequestPermission(fs), loadCurrentDir()]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data;
            if (data != null) {
              var curDir = data[1] as FileSystemEntry;
              final controller = FileBrowserController(fs: fs, expand: curDir);
              controller.updateRoots(data[0] as List<FileSystemEntryStat>);
              return Column(children: [
                PathView(controller.currentDir),
                Expanded(child: FileBrowser(controller: controller)),
              ]);
            }
          }
          return Container();
        });
  }

  Future<FileSystemEntry?> loadCurrentDir() async {
    final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

    var v = await asyncPrefs.getString('fbc_last_path');
    if (v == null) return FileSystemEntry.blank();
    var decoded = json.decode(v);
    return FileSystemEntry.fromJson(decoded);
  }

  Future<List<FileSystemEntryStat>?> checkAndRequestPermission(
      LocalFileSystem fs) async {
    var entry = FileSystemEntry.blank();
    if (Platform.isLinux || Platform.isMacOS) {
      entry = FileSystemEntry(
          name: '/', path: '/', relativePath: '/', isDirectory: true);
    } else if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        // We didn't ask for permission yet or the permission has been denied before but not permanently.
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        return null;
      }
      await checkAndRequestManageStoragePermission();
      final directories = await getExternalStorageDirectories();
      final roots = await Future.wait(directories!.map((dir) {
        final name = path.basename(dir.path);
        final relativePath = name;
        final dirPath = dir.path;
        final entry = FileSystemEntry(
            name: name,
            path: dirPath,
            relativePath: relativePath,
            isDirectory: true);
        return fs.stat(entry);
      }));
      return roots;
    }
    rootEntry = await fs.stat(entry);
    return List.from([rootEntry]);
  }

  Future<bool> checkAndRequestManageStoragePermission() async {
    var status = await Permission.manageExternalStorage.status;
    if (status.isDenied) {
      status = await Permission.manageExternalStorage.request();
    }
    return status.isGranted;
  }
}
