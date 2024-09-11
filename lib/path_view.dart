import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import 'file_browser/filesystem_interface.dart';

class PathView extends StatelessWidget {
  Rx<FileSystemEntry> currentPath;
  ScrollController controller = ScrollController();

  PathView(this.currentPath, {super.key});

  void onClickPart(List<String> paths, int idx) {
    var parts = paths.sublist(0, idx + 1);
    currentPath.value = FileSystemEntry(
        name: parts[idx],
        path: parts.join("/"),
        relativePath: parts.join("/"),
        isDirectory: true);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 30,
        child: Obx(() => Scrollbar(
            controller: controller,
            child: ListView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                children: toUi(currentPath.value)))));
  }

  List<Widget> toUi(FileSystemEntry path) {
    var parts = path.path.split("/");
    var list = <Widget>[];
    for (int i = 0; i < parts.length; ++i) {
      String p = parts[i];
      if (p.isEmpty) p = "/";
      TextButton text = TextButton(
        iconAlignment: IconAlignment.start,
        onPressed: () => onClickPart(parts, i),
        //定义一下文本样式
        style: ButtonStyle(
          //设置水波纹颜色
          overlayColor: WidgetStateProperty.all(Colors.yellow),
          //设置按钮内边距
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 5)),
          side: WidgetStateProperty.all(
              const BorderSide(color: Colors.grey, width: 1)),
          shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
        ),
        child: Text(p),
      );
      list.add(text);
    }
    return list;
  }
}
