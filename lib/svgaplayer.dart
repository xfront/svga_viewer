import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/player.dart';

class SvgaFileListView extends StatefulWidget {
  const SvgaFileListView({super.key});

  @override
  _SvgaFileListState createState() => _SvgaFileListState();
}

class _SvgaFileListState extends State<SvgaFileListView> {
  final RxList<XFile> svgaFileList = Get.find(tag: "file_list");

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
    return DropTarget(
      onDragDone: (detail) async {
        svgaFileList.clear();
        svgaFileList
            .addAll(detail.files.where((e) => e.path.endsWith(".svga")));
      },
      child: Obx(() => ListView.separated(
            itemCount: svgaFileList.length,
            itemBuilder: (BuildContext context, int index) {
              XFile file = svgaFileList[index];
              return SvgaFilePlayer(key: Key(file.path), svgaFile: file);
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
          )),
    );
  }
}

class SvgaFilePlayer extends StatefulWidget {
  XFile svgaFile;

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
    return SizedBox(width: 300, child:Column(
        children: [SVGAImage(animationController!), Text(widget.svgaFile.name)]));
  }
}
