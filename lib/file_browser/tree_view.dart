// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

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
  final FileSystemEntry expand;
  final FileBrowserController fileCtrl;
  final RxList<File> svgaFileList = Get.find(tag: "file_list");

  TreeViewLayout(
      {super.key,
      required this.fileCtrl,
      required this.entry,
      required this.expand});

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
          fileCtrl.currentDir.value = node.content.entry;
          svgaFileList.value = filterSvga(node);
        },
      ),
    };
  }

  List<File> filterSvga(TreeViewNode<Node> node) {
    return (node.content.isDir ? node.children : [node])
        .where(
            (e) => !e.content.isDir && e.content.entry.name.endsWith(".svga"))
        .map((e) => File(e.content.entry.path))
        .toList(growable: true);
  }

  Widget _getTree(BuildContext context, List<TreeViewNode<Node>> roots) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      treeController.expandAll();

      TreeViewNode<Node>? findNode(
          List<TreeViewNode<Node>> roots, FileSystemEntry target) {
        for (var n in roots) {
          if (n.content.entry == target) {
            return n;
          }
          var node = findNode(n.children, target);
          if (node != null) return node;
        }
        return null;
      }

      final node = findNode(roots, expand);
      if (node != null) {
        _selectedNode = node;
        treeController.expandNode(node);
      }
    });

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
            tree: roots,
            onNodeToggle: (TreeViewNode<Node> node) {
              _selectedNode = node;
            },
            cacheExtent: 100,
            treeNodeBuilder: _treeNodeBuilder,
            treeRowBuilder: _treeRowBuilder,
            indentation: TreeViewIndentationType.standard,
          ),
        ),
      ),
    );
  }

  List<TreeViewNode<Node>> fileList2NodeList(
      List<FileSystemEntryStat> fileList) {
    return fileList.map((e) => TreeViewNode(e)).toList();
  }

  Future<List<TreeViewNode<Node>>> expandTo(
      List<FileSystemEntryStat> roots, FileSystemEntry expand) async {
    List<TreeViewNode<Node>> rootNodes = fileList2NodeList(roots);
    if (expand == FileSystemEntry.blank()) return rootNodes;
    int idx = roots.indexWhere((e) => expand.path.startsWith(e.entry.path));
    TreeViewNode<Node> parent = idx != -1
        ? rootNodes[idx]
        : TreeViewNode(FileSystemEntryStat(entry: FileSystemEntry.root()));
    var parts =
        expand.path.substring(parent.content.entry.path.length).split("/");
    if (parts.isEmpty || parts[0].isEmpty) return rootNodes;

    for (int i = 0; i < parts.length; ++i) {
      var children = await fileCtrl.sortedListing(parent.content.entry);
      parent.children.addAll(fileList2NodeList(children));

      String part = parts[i];
      FileSystemEntry entry = FileSystemEntry(
          name: part,
          path: parent.content.entry.path == "/"
              ? "/$part"
              : "${parent.content.entry.path}/$part",
          relativePath: part,
          isDirectory: i < parts.length - 1 || expand.isDirectory);
      parent = parent.children[
          parent.children.indexWhere((e) => e.content.entry == entry)];
    }
    return rootNodes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fileCtrl.sortedListing(entry).then((e) => expandTo(e, expand)),
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
