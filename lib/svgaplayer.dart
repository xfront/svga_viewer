import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/player.dart';

class SvgaFileListView extends StatefulWidget {
  List<XFile> svgaFileList;

  SvgaFileListView({super.key, required this.svgaFileList});

  @override
  _SvgaFileListState createState() => _SvgaFileListState();
}

class _SvgaFileListState extends State<SvgaFileListView> {
  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          widget.svgaFileList = detail.files;
        });
      },
      child: SizedBox(
          width: 1000,
          height: 500,
          child: ListView.separated(
            itemCount: widget.svgaFileList.length,
            itemBuilder: (BuildContext context, int index) {
              XFile file = widget.svgaFileList[index];
              return SvgaFilePlayer(key: Key(file.path), svgaFile: file);
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(),
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
  late SVGAAnimationController animationController;

  @override
  void initState() {
    animationController = SVGAAnimationController(vsync: this);
    loadAnimation();
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void loadAnimation() async {
    final fileData = await widget.svgaFile.readAsBytes();
    final videoItem = await SVGAParser.shared.decodeFromBuffer(fileData);
    animationController.videoItem = videoItem;
    animationController
        .repeat() // Try to use .forward() .reverse()
        .whenComplete(() => animationController.videoItem = null);
  }

  @override
  Widget build(BuildContext context) {
    return SVGAImage(animationController);
  }
}
