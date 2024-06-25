part of 'home.dart';

class State {
  final bool isDraggingOver;
  final String? currentlyScanningDirectory;
  final IMap<String, String> failedTreeFiles;
  final IList<Tree> trees;
  final IList<TreeElement> treeElements;

  const State({
    this.isDraggingOver = false,
    this.currentlyScanningDirectory,
    this.failedTreeFiles = const IMap.empty(),
    this.trees = const IList.empty(),
    this.treeElements = const IList.empty(),
  });

  State copyWith({
    final bool Function()? isDraggingOver,
    final String? Function()? currentlyScanningDirectory,
    final IMap<String, String> Function()? failedTreeFiles,
    final IList<Tree> Function()? trees,
    final IList<TreeElement> Function()? treeElements,
  }) =>
      State(
        isDraggingOver: isDraggingOver == null
            ? this.isDraggingOver
            : isDraggingOver.call(),
        currentlyScanningDirectory: currentlyScanningDirectory == null
            ? this.currentlyScanningDirectory
            : currentlyScanningDirectory.call(),
        failedTreeFiles: failedTreeFiles == null
            ? this.failedTreeFiles
            : failedTreeFiles.call(),
        trees: trees == null ? this.trees : trees.call(),
        treeElements:
            treeElements == null ? this.treeElements : treeElements.call(),
      );
}
