part of '../home.dart';

class Tree {
  final String path;

  const Tree(this.path);
}

class TreeElement {
  final String path;
  final IList<Tree> containingTrees;
  final TreeElementType type;
  final String? parent;
  final String? childrenScanError;

  String get name => lib_path.basename(path);

  const TreeElement(
    this.path,
    this.containingTrees,
    this.type, [
    this.parent,
    this.childrenScanError,
  ]);

  bool matchesDirectory(final Directory directory) =>
      type == TreeElementType.directory && path == directory.path;

  bool belongsToTree(final Tree tree) => containingTrees.contains(tree);

  bool matchesSignature(
    final String path,
    final TreeElementType type,
    final String? parent,
  ) =>
      path == this.path && type == this.type && parent == this.parent;

  TreeElement copyWith({
    final String Function()? path,
    final IList<Tree> Function()? containingTrees,
    final TreeElementType Function()? type,
    final String? Function()? parent,
    final String? Function()? childrenScanError,
  }) =>
      TreeElement(
        path == null ? this.path : path.call(),
        containingTrees == null ? this.containingTrees : containingTrees.call(),
        type == null ? this.type : type.call(),
        parent == null ? this.parent : parent.call(),
        childrenScanError == null
            ? this.childrenScanError
            : childrenScanError.call(),
      );
}

enum TreeElementType { file, directory }
