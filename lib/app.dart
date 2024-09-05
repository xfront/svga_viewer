import 'dart:io';

import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:path/path.dart' as path;
import 'package:svga_viewer/svgaplayer.dart';
import 'file_browser/controllers/file_browser.dart';
import 'file_browser/file_browser.dart';
import 'file_browser/filesystem_interface.dart';
import 'file_browser/local_filesystem.dart';

class App extends StatelessWidget {
  const App({super.key});

  ThemeData createTheme(Color color, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.primary,
        textColor: colorScheme.onPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_fancy_tree_view',
      debugShowCheckedModeBanner: false,
      home: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  /// Necessary when resizing the app so the tree view example inside the
  /// main view doesn't loose its tree states.
  static const treeViewKey = GlobalObjectKey('<TreeViewKey>');
  static const mainViewKey = GlobalObjectKey('<MainViewKey>');

  @override
  Widget build(BuildContext context) {
    PreferredSizeWidget? appBar;
    Widget? body;
    Widget? drawer;

    Get.put(tag: "file_list", permanent: true, <XFile>[].obs ) ;

    if (MediaQuery.of(context).size.width > 720) {
      body = const Row(
        children: [
          SizedBox(width: 300, child: FileTreeView(key: treeViewKey)),
          VerticalDivider(width: 1),
          Expanded(child: SvgaFileListView(key: mainViewKey)),
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
      body = SvgaFileListView(key: mainViewKey);
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
    final _verticalScrollController = ScrollController();
    final _horizontalScrollController = ScrollController();

    return FutureBuilder(
      future: checkAndRequestPermission(fs),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data;
          if (data != null) {
            final controller = FileBrowserController(fs: fs);
            controller.updateRoots(data);
            return FileBrowser(
                controller: controller, scrollCtrl: _verticalScrollController);
          }
        }
        return Container();
      }
    );
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
