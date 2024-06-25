part of 'home.dart';

abstract class Event {
  const Event();
}

class Startup extends Event {
  const Startup();
}

class DragEntered extends Event {
  final DropEventDetails details;

  const DragEntered(this.details);
}

class DragExited extends Event {
  final DropEventDetails details;

  const DragExited(this.details);
}

class DragDone extends Event {
  final DropDoneDetails details;

  const DragDone(this.details);
}

class SeenFailedFiles extends Event {
  const SeenFailedFiles();
}

class ChoseDirectoryToScan extends Event {
  final Directory directory;

  const ChoseDirectoryToScan(this.directory);
}

class CancelDirectoryScan extends Event {}

class CloseTreeTab extends Event {
  final Tree tree;

  const CloseTreeTab(this.tree);
}

class ExportScan extends Event {
  final File file;
  final Tree tree;

  const ExportScan(this.file, this.tree);
}

class ImportTrees extends Event {
  final List<File> files;

  const ImportTrees(this.files);
}
