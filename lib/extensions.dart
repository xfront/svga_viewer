import 'dart:io';

class _PathStat {
  final String path;
  final DateTime dateTime;

  const _PathStat(this.path, this.dateTime);
}

extension FileExtensions on List<File> {
  Future<List<File>> sortByName({bool desc = false}) async {
    sort((a, b) {
      if (desc) (a, b) = (b, a);
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
    return this;
  }

  Future<List<File>> sortByDate({bool desc = false}) async {
    final List<_PathStat> dateStat = [];

    for (final entity in this) {
      final stat = await entity.stat();
      dateStat.add(_PathStat(entity.path, stat.modified));
    }

    dateStat.sort((a, b) {
      if (desc) (a, b) = (b, a);
      return a.dateTime.compareTo(b.dateTime);
    });

    return dateStat
        .map((pathStat) =>
            this.firstWhere((entity) => entity.path == pathStat.path))
        .toList();
  }

  Future<List<FileSystemEntity>> sortByType({bool desc = false}) async {
    final List<File> files = this;

    files.sort((a, b) {
      var aa = a.path.toLowerCase().split('.').last;
      var bb = b.path.toLowerCase().split('.').last;
      if (desc) (aa, bb) = (bb, aa);
      return aa.compareTo(bb);
    });

    return files;
  }

  Future<List<FileSystemEntity>> sortBySize({bool desc = false}) async {
    final List<File> files = this;

    files.sort((a, b) {
      if (desc) (a, b) = (b, a);
      return a.lengthSync().compareTo(b.lengthSync());
    });

    return this;
  }
}
