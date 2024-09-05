import 'controllers/file_browser.dart';
import 'filesystem_interface.dart';
import 'package:flutter/material.dart';
import 'package:filesize/filesize.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class GridViewLayout extends StatelessWidget {
  ScrollController? scrollCtrl;
  final FileBrowserController fileCtrl;
  final FileSystemEntry entry;

  GridViewLayout(
      {super.key,
      required this.fileCtrl,
      required this.entry,
      this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fileCtrl.sortedListing(entry),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data;
            if (data == null) return Container();
            final showParentEntry = !fileCtrl.isRootEntry(this.entry);
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150),
              shrinkWrap: true,
              itemCount: data.length + (showParentEntry ? 1 : 0),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                FileSystemEntryStat? entry;
                bool showInfo = false;
                if (showParentEntry && index == 0) {
                  showInfo = false;
                  var parentPath = path.dirname(this.entry.path);
                  // Check if this is root. If it is, then we end up with root again
                  parentPath = parentPath == this.entry.path ? '' : parentPath;
                  final parentEntry = FileSystemEntry(
                      name: '..',
                      isDirectory: true,
                      path: parentPath,
                      relativePath: path.dirname(this.entry.relativePath));
                  entry = new FileSystemEntryStat(
                      entry: parentEntry, lastModified: 0, size: 0, mode: 0);
                } else {
                  final idx = index - (showParentEntry ? 1 : 0);
                  entry = data[idx];
                }
                return Obx(() => InkWell(
                    splashColor: fileCtrl.selected.isEmpty
                        ? Colors.blue[100]
                        : Colors.transparent,
                    onTap: () {
                      if (entry!.entry.isDirectory) {
                        if (showParentEntry &&
                            index == 0 &&
                            fileCtrl.rootPathsSet.contains(entry.entry.path)) {
                          fileCtrl.currentDir.value = FileSystemEntry.blank();
                        } else if (entry.entry.isDirectory) {
                          fileCtrl.currentDir.value = entry.entry;
                        }
                      } else {
                        fileCtrl.toggleSelect(entry.entry);
                      }
                      if (fileCtrl.selected.isNotEmpty) {
                        // fileCtrl.toggleSelect(entry!.entry);
                      } else {
                        //
                      }
                    },
                    onLongPress: () {
                      fileCtrl.toggleSelect(entry!.entry);
                    },
                    child: Container(
                        color: fileCtrl.selected.contains(entry!.entry)
                            ? Colors.blue[200]
                            : Colors.transparent,
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.only(
                            left: 20.0, top: 10.0, bottom: 10.0),
                        child: GridViewEntry(
                            fs: fileCtrl.fs,
                            entry: entry,
                            showInfo: showInfo)
                    )
                  )
                );
              },
            );
          } else {
            return Container();
          }
        });
  }
}

class GridViewEntry extends StatelessWidget {
  final FileSystemInterface fs;
  final FileSystemEntryStat entry;
  final bool showInfo;

  const GridViewEntry({required this.fs, required this.entry, this.showInfo = false});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              margin: EdgeInsets.zero,
              alignment: Alignment.center,
              width: 64.0,
              height: 64.0,
              child: Thumbnail(fs: fs, entry: entry.entry)),
          Flexible(
              child: Text(entry.entry.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16.0,
                      color: Colors.black))),
          if (showInfo)
            Flexible(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                    width: 64.0,
                    child: Text(
                      filesize(entry.size, 0),
                      style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.0,
                          color: Colors.grey),
                    )),
                Text(
                    DateFormat('yyyy-MM-dd').format(
                        DateTime.fromMillisecondsSinceEpoch(
                            entry.lastModified)),
                    style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12.0,
                        color: Colors.grey))
              ],
            ))
        ]);
  }
}

class Thumbnail extends StatelessWidget {
  final FileSystemInterface fs;
  final FileSystemEntry entry;

  Thumbnail({required this.fs, required this.entry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fs.getThumbnail(entry, height: 36),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final thumbnail = snapshot.data;
          return thumbnail ?? Container();
        } else {
          return Container();
        }
      },
    );
  }
}
