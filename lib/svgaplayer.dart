import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/player.dart';

class SvgaFileListView extends StatefulWidget {
  const SvgaFileListView({super.key});

  @override
  _SvgaFileListState createState() => _SvgaFileListState();
}

enum SortBy {
  name,
  date,
  type,
  size,
}

class _SvgaFileListState extends State<SvgaFileListView> {
  final RxList<File> svgaFileList = Get.find(tag: "file_list");
  final viewType = 0.obs;
  final sortType = SortBy.name.obs;
  final sortDesc = false.obs;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget? getSortIcon(SortBy sort) {
    return sortType.value == sort
        ? Icon(sortDesc.value ? Icons.arrow_downward : Icons.arrow_upward)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PopupMenuButton<int>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Text('列表'),
              ),
              const PopupMenuItem(
                value: 1,
                child: Text('表格'),
              ),
            ],
            onSelected: (value) {
              // 处理操作菜单选项的回调
              // TODO: 根据选中的操作执行相应的逻辑
              print('选中的选项: $value');
              viewType.value = value;
            },
            icon: const Icon(Icons.view_list),
          ),
          PopupMenuButton<SortBy>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortBy.name,
                child: TextButton.icon(
                  iconAlignment: IconAlignment.end,
                  label: Text('名称'),
                  icon: getSortIcon(SortBy.name),
                  onPressed: null,
                ),
              ),
              PopupMenuItem(
                value: SortBy.type,
                child: TextButton.icon(
                  iconAlignment: IconAlignment.end,
                  label: Text('类型'),
                  icon: getSortIcon(SortBy.type),
                  onPressed: null,
                ),
              ),
              PopupMenuItem(
                value: SortBy.size,
                child: TextButton.icon(
                  iconAlignment: IconAlignment.end,
                  label: Text('大小'),
                  icon: getSortIcon(SortBy.size),
                  onPressed: null,
                ),
              ),
              PopupMenuItem(
                value: SortBy.date,
                child: TextButton.icon(
                  iconAlignment: IconAlignment.end,
                  label: Text('时间'),
                  icon: getSortIcon(SortBy.date),
                  onPressed: null,
                ),
              ),
            ],
            onSelected: (type) {
              // 处理操作菜单选项的回调
              // TODO: 根据选中的操作执行相应的逻辑
              var desc = (type == sortType.value) ? sortDesc.value ^ true : false;
              print('选中的选项: $type, desc:$desc');
              sortType.value = type;
              sortDesc.value = desc;

              switch (type) {
                case SortBy.name:
                  svgaFileList.sortByName(desc: desc);
                case SortBy.date:
                  svgaFileList.sortByDate(desc: desc);
                case SortBy.type:
                  svgaFileList.sortByType(desc: desc);
                case SortBy.size:
                  svgaFileList.sortBySize(desc: desc);
              }
            },
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      Expanded(
        child: DropTarget(
            onDragDone: (detail) async {
              svgaFileList.clear();
              svgaFileList.addAll(detail.files
                  .where((e) => e.path.endsWith(".svga"))
                  .map((e) => File(e.path)));
            },
            child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: Obx(
                  () => viewType.value == 0
                      ? ListView.separated(
                          controller: scrollController,
                          itemCount: svgaFileList.length,
                          itemBuilder: (BuildContext context, int index) {
                            File file = svgaFileList[index];
                            return SvgaFilePlayer(
                                key: Key(file.path), svgaFile: file);
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(),
                        )
                      : MasonryGridView.count(
                          controller: scrollController,
                          crossAxisCount: 3,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          itemCount: svgaFileList.length,
                          itemBuilder: (BuildContext context, int index) {
                            File file = svgaFileList[index];
                            return SvgaFilePlayer(
                                key: Key(file.path), svgaFile: file);
                          },
                        ),
                ))),
      )
    ]);
  }
}

class SvgaFilePlayer extends StatefulWidget {
  File svgaFile;

  SvgaFilePlayer({super.key, required this.svgaFile});

  @override
  _SvgaFileState createState() => _SvgaFileState();
}

class _SvgaFileState extends State<SvgaFilePlayer>
    with SingleTickerProviderStateMixin {
  late SVGAAnimationController? animationController;

  @override
  void initState() {
    super.initState();
    animationController = SVGAAnimationController(vsync: this);
    this._loadAnimation();
  }

  @override
  void dispose() {
    animationController?.dispose();
    animationController = null;
    super.dispose();
  }

  void _loadAnimation() async {
    final fileData = await widget.svgaFile.readAsBytes();
    final videoItem = await SVGAParser.shared.decodeFromBuffer(fileData);
    if (mounted) {
      setState(() {
        animationController?.videoItem = videoItem;
        _playAnimation();
      });
    }
  }

  void _playAnimation() {
    if (animationController?.isCompleted == true) {
      animationController?.reset();
    }
    animationController?.repeat(); // or animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 300,
        child: Column(children: [
          SVGAImage(animationController!),
          Text(widget.svgaFile.path.substring(widget.svgaFile.path.lastIndexOf("/")+1))
        ]));
  }
}
