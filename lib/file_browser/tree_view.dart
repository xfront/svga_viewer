// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cross_file/cross_file.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'controllers/file_browser.dart';
import 'filesystem_interface.dart';

typedef Node = FileSystemEntryStat;

/// The class containing a TreeView that highlights the selected node.
/// The custom TreeView.treeNodeBuilder makes tapping the whole row of a parent
/// toggle the node open and closed with TreeView.toggleNodeWith. The
/// scrollbars will appear as the content exceeds the bounds of the viewport.
class TreeViewLayout extends StatelessWidget {
  final FileSystemEntry entry;
  final FileBrowserController fileCtrl;
  final RxList<XFile> svgaFileList = Get.find(tag: "file_list");

  TreeViewLayout({super.key, required this.fileCtrl, required this.entry});

  /// The [TreeViewController] associated with this [TreeView].
  final TreeViewController treeController = TreeViewController();

  /// The [ScrollController] associated with the vertical axis.
  final ScrollController verticalController = ScrollController();

  TreeViewNode<Node>? _selectedNode;
  final ScrollController _horizontalController = ScrollController();

  TreeRow _treeRowBuilder(TreeViewNode<Node> node) {
    if (_selectedNode == node) {
      return TreeRow(
        extent: FixedTreeRowExtent(node.content.isDir ? 60.0 : 50.0),
        recognizerFactories: _getTapRecognizer(node),
        backgroundDecoration: TreeRowDecoration(
          color: Colors.amber[100],
        ),
        foregroundDecoration:
            const TreeRowDecoration(border: TreeRowBorder.all(BorderSide())),
      );
    }
    return TreeRow(
      extent: FixedTreeRowExtent(node.content.isDir ? 60.0 : 50.0),
      recognizerFactories: _getTapRecognizer(node),
    );
  }

  Widget _treeNodeBuilder(
    BuildContext context,
    TreeViewNode<Node> node,
    AnimationStyle toggleAnimationStyle,
  ) {
    final bool isFolder = node.content.isDir;
    final BorderSide border = BorderSide(
      width: 2,
      color: Colors.purple[300]!,
    );
    // TRY THIS: TreeView.toggleNodeWith can be wrapped around any Widget (even
    // the whole row) to trigger parent nodes to toggle opened and closed.
    // Currently, the toggle is triggered in _getTapRecognizer below using the
    // TreeViewController.
    return Row(
      children: <Widget>[
        // Custom indentation
        SizedBox(width: 10.0 * node.depth! + 8.0),
        DecoratedBox(
          decoration: BoxDecoration(
            border: node.parent != null
                ? Border(left: border, bottom: border)
                : null,
          ),
          child: const SizedBox(height: 50.0, width: 20.0),
        ),
        // Leading icon for parent nodes
        if (isFolder)
          DecoratedBox(
            decoration: BoxDecoration(border: Border.all()),
            child: SizedBox.square(
              dimension: 20.0,
              child: Icon(
                node.isExpanded ? Icons.remove : Icons.add,
                size: 14,
              ),
            ),
          ),
        // Spacer
        const SizedBox(width: 8.0),
        // Content
        Text(node.content.entry.name),
      ],
    );
  }

  Map<Type, GestureRecognizerFactory> _getTapRecognizer(
      TreeViewNode<Node> node) {
    return <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(),
        (TapGestureRecognizer t) => t.onTap = () async {
          if (node.content.isDir && node.children.isEmpty) {
            var children = await fileCtrl.sortedListing(node.content.entry);
            node.children.addAll(fileList2NodeList(children));
          }

          // Toggling the node here instead means any tap on the row can
          // toggle parent nodes opened and closed.
          treeController.toggleNode(node);
          _selectedNode = node;
          svgaFileList.value = filterSvga(node);
        },
      ),
    };
  }

  List<XFile> filterSvga(TreeViewNode<Node> node) {
    return (node.content.isDir? node.children : [node])
        .where((e) => !e.content.isDir && e.content.entry.name.endsWith(".svga"))
        .map((e) => XFile(e.content.entry.path))
        .toList(growable: true);
  }

  Widget _getTree(BuildContext context, List<FileSystemEntryStat> roots) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: Scrollbar(
          controller: verticalController,
          thumbVisibility: true,
          child: TreeView<Node>(
            controller: treeController,
            verticalDetails: ScrollableDetails.vertical(
              controller: verticalController,
            ),
            horizontalDetails: ScrollableDetails.horizontal(
              controller: _horizontalController,
            ),
            tree: fileList2NodeList(roots).toList(),
            onNodeToggle: (TreeViewNode<Node> node) {
              _selectedNode = node;
            },
            treeNodeBuilder: _treeNodeBuilder,
            treeRowBuilder: _treeRowBuilder,
            // No internal indentation, the custom treeNodeBuilder applies its
            // own indentation to decorate in the indented space.
            indentation: TreeViewIndentationType.none,
          ),
        ),
      ),
    );
  }

  fileList2NodeList(List<FileSystemEntryStat> fileList) {
    return fileList.map((e) => TreeViewNode(e));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fileCtrl.sortedListing(entry),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data;
            if (data == null) return Container();
            return _getTree(context, data);
          } else {
            return Container();
          }
        });
  }
}
