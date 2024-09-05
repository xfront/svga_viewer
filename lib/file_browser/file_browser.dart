library file_browser;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/file_browser.dart';
import 'filesystem_interface.dart';
import 'list_view.dart';
import 'grid_view.dart';
import 'tree_view.dart';
import 'local_filesystem.dart';

class FileBrowser extends StatelessWidget {
  ScrollController? scrollCtrl;
  late final FileBrowserController controller;

  FileBrowser(
      {super.key, List<FileSystemEntryStat>? roots, FileBrowserController? controller, this.scrollCtrl}) {
    if (controller != null) {
      this.controller = controller;
    } else {
      if (roots == null) {
        throw 'Must specify roots or controller';
      }
      this.controller = FileBrowserController(fs: LocalFileSystem());
      this.controller.updateRoots(roots);
      this.controller.showDirectoriesFirst.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.currentLayout.value) {
        case Layout.LIST_VIEW:
          return ListViewLayout(
              fileCtrl: controller, entry: controller.currentDir.value, scrollCtrl: scrollCtrl);
        case Layout.GRID_VIEW:
          return GridViewLayout(
              fileCtrl: controller, entry: controller.currentDir.value, scrollCtrl: scrollCtrl);
        case Layout.TREE_VIEW:
          return TreeViewLayout(
              fileCtrl: controller, entry: FileSystemEntry.blank());
      }
    });
  }
}
