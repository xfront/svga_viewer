import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'getx/BaseController.dart';

import 'svgaplayer.dart';
import 'getx/BaseView.dart';

class _FilePickerCtrl extends BaseController {
  RxList<XFile> _fileList = <XFile>[].obs;
  String _extension = ".svga";
  bool _lockParentWindow = false;
  bool _multiPick = true;
  FileType _pickingType = FileType.any;

  @override
  void onDetached() {
    // TODO: implement onDetached
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  @override
  void onInactive() {
    // TODO: implement onInactive
  }

  @override
  void onPaused() {
    // TODO: implement onPaused
  }

  @override
  void onResumed() {
    // TODO: implement onResumed
  }

  void _pickFiles() async {
    try {
      _fileList.value = (await FilePicker.platform.pickFiles(
            compressionQuality: 30,
            type: _pickingType,
            allowMultiple: _multiPick,
            onFileLoading: (FilePickerStatus status) => print(status),
            allowedExtensions: _extension.isNotEmpty
                ? _extension.replaceAll(' ', '').split(',')
                : null,
            dialogTitle: "",
            initialDirectory: "/",
            lockParentWindow: _lockParentWindow,
          ))
              ?.files
              .map((e) => e.xFile)
              .toList() ??
          [];
    } on PlatformException catch (e) {
    } catch (e) {}
  }
}

class FilePickerDemo extends BaseStatelessWidget<_FilePickerCtrl> {
  FilePickerDemo() {
    Get.lazyPut(() => _FilePickerCtrl());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVGA查看器'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '动作',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: <Widget>[
                    SizedBox(
                      width: 120,
                      child: FloatingActionButton.extended(
                          onPressed: () => controller._pickFiles(),
                          label: Text(controller._multiPick ? '选择多文件' : '选择文件'),
                          icon: const Icon(Icons.description)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(
                height: 20.0,
              ),
              Obx(() => SvgaFileListView(
                    svgaFileList: controller._fileList.value,
                  )
              )
            ],
          ),
        ),
      ),
    );
  }
}
