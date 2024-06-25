part of 'home.dart';

class Bloc extends flutter_bloc.Bloc<Event, State> {
  bool shouldCancelDirectoryScan = false;

  Bloc() : super(const State()) {
    on<Startup>((final event, final emit) {});
    on<DragEntered>((final event, final emit) {
      emit(state.copyWith(isDraggingOver: () => true));
    });
    on<DragExited>((final event, final emit) {
      emit(state.copyWith(isDraggingOver: () => false));
    });
    on<DragDone>((final event, final emit) async {
      final parsed = await parseTrees(
        event.details.files.map((final file) => File(file.path)).toList(),
      );

      final trees = [...state.trees, ...parsed.$1.map((final tree) => tree.$2)];

      emit(
        state.copyWith(
          isDraggingOver: () => false,
          failedTreeFiles: () => parsed.$2.lock,
          trees: () => trees.lock,
          treeElements: () => mergeTreeElements(
            [
              ...parsed.$1.map((final tree) => tree.$1),
              state.treeElements.unlock,
            ],
          ).lock,
        ),
      );
    });
    on<SeenFailedFiles>(
      (final event, final emit) =>
          emit(state.copyWith(failedTreeFiles: () => const IMap.empty())),
    );
    on<ChoseDirectoryToScan>((final event, final emit) async {
      emit(
        state.copyWith(
          currentlyScanningDirectory: () => event.directory.path,
        ),
      );

      final rootPathLength = event.directory.path.length + 1;

      final treeElements = state.treeElements.unlock;
      final tree = Tree(event.directory.path);

      Future<void> populateRecursive(final Directory directory) async {
        if (shouldCancelDirectoryScan) {
          return;
        }

        try {
          for (final element in await directory.list().toList()) {
            if (shouldCancelDirectoryScan) {
              return;
            }

            if (element is! File && element is! Directory) {
              continue;
            }

            final path = element.path.substring(rootPathLength);

            final type = switch (element) {
              File _ => TreeElementType.file,
              Directory _ => TreeElementType.directory,
              _ => throw UnimplementedError(),
            };

            final parent = directory == event.directory ||
                    directory.parent == event.directory
                ? null
                : directory.path.substring(rootPathLength);

            final containingTrees = [tree];

            final existingTreeElement = treeElements.firstWhereOrNull(
              (final treeElement) =>
                  treeElement.matchesSignature(path, type, parent),
            );

            if (existingTreeElement != null) {
              containingTrees.addAll(existingTreeElement.containingTrees);

              treeElements.remove(existingTreeElement);
            }

            final newTreeElement = TreeElement(
              path,
              containingTrees.lock,
              type,
              parent,
            );

            treeElements.add(newTreeElement);

            if (type == TreeElementType.directory) {
              await populateRecursive(element as Directory);
            }
          }
        } catch (exception) {
          final treeElement = treeElements.firstWhere(
            (final treeElement) => treeElement.matchesDirectory(directory),
          );

          treeElements.remove(treeElement);

          treeElements.add(
            treeElement.copyWith(
              childrenScanError: () => exception.toString(),
            ),
          );
        }
      }

      await populateRecursive(event.directory);

      if (shouldCancelDirectoryScan) {
        shouldCancelDirectoryScan = false;

        emit(
          state.copyWith(
            currentlyScanningDirectory: () => null,
          ),
        );

        return;
      }

      emit(
        state.copyWith(
          currentlyScanningDirectory: () => null,
          trees: () => [
            ...state.trees,
            tree,
          ].lock,
          treeElements: () => treeElements.lock,
        ),
      );
    });
    on<CancelDirectoryScan>((final event, final emit) {
      shouldCancelDirectoryScan = true;
    });
    on<CloseTreeTab>(
      (final event, final emit) => emit(
        state.copyWith(
          trees: () => state.trees.remove(event.tree),
          treeElements: () => state.treeElements
              .map(
                (final treeElement) => treeElement.copyWith(
                  containingTrees: () =>
                      treeElement.containingTrees.remove(event.tree),
                ),
              )
              .where(
                (final treeElement) => treeElement.containingTrees.isNotEmpty,
              )
              .toIList(),
        ),
      ),
    );
    on<ExportScan>((final event, final emit) async {
      final file = await event.file.create(recursive: true);

      const encoder = JsonEncoder.withIndent('  ');

      final jsonTree = JsonTree(event.tree.path);
      final treeDirectories = <TreeElement, JsonTreeDirectory>{};

      for (final treeElement in state.treeElements.where(
        (final treeElement) => treeElement.belongsToTree(event.tree),
      )) {
        final parentTreeElement = treeElement.parent == null
            ? null
            : state.treeElements.firstWhereOrNull(
                (final parentTreeElement) =>
                    treeElement.parent == parentTreeElement.path,
              );

        switch (treeElement.type) {
          case TreeElementType.directory:
            {
              JsonTreeDirectory? jsonTreeDirectory =
                  treeDirectories[treeElement];

              if (jsonTreeDirectory == null) {
                jsonTreeDirectory = JsonTreeDirectory(treeElement.path);

                treeDirectories[treeElement] = jsonTreeDirectory;
              }

              if (parentTreeElement == null) {
                jsonTree.directories.add(jsonTreeDirectory);

                break;
              }

              final JsonTreeDirectory? containingDirectory =
                  treeDirectories[parentTreeElement];

              if (containingDirectory != null) {
                containingDirectory.directories.add(jsonTreeDirectory);

                break;
              }

              treeDirectories[parentTreeElement] = JsonTreeDirectory(
                parentTreeElement.path,
                directories: [jsonTreeDirectory],
              );

              break;
            }

          case TreeElementType.file:
            {
              final jsonTreeFile = JsonTreeFile(treeElement.path);

              if (parentTreeElement == null) {
                jsonTree.files.add(jsonTreeFile);

                break;
              }

              final JsonTreeDirectory? containingDirectory =
                  treeDirectories[parentTreeElement];

              if (containingDirectory != null) {
                containingDirectory.files.add(jsonTreeFile);

                break;
              }

              treeDirectories[parentTreeElement] = JsonTreeDirectory(
                parentTreeElement.path,
                files: [jsonTreeFile],
              );

              break;
            }
        }
      }

      await file.writeAsString(encoder.convert(jsonTree.toJson()));
    });
    on<ImportTrees>((final event, final emit) async {
      final parsed = await parseTrees(event.files);

      final trees = [...state.trees, ...parsed.$1.map((final tree) => tree.$2)];

      emit(
        state.copyWith(
          isDraggingOver: () => false,
          failedTreeFiles: () => parsed.$2.lock,
          trees: () => trees.lock,
          treeElements: () => mergeTreeElements(
            [
              ...parsed.$1.map((final tree) => tree.$1),
              state.treeElements.unlock,
            ],
          ).lock,
        ),
      );
    });
  }

  Future<
      (
        List<(List<TreeElement>, Tree)> trees,
        Map<String, String> failedFiles
      )> parseTrees(
    final List<File> files,
  ) async {
    final List<(List<TreeElement>, Tree)> trees = [];
    final Map<String, String> failedFiles = {};

    for (final file in files) {
      try {
        if (!lib_path.extension(file.path).endsWith('.json')) {
          throw Exception('File is not a JSON document!');
        }

        final fileContent = await file.readAsString();

        final jsonTree =
            JsonTree.fromJson(jsonDecode(fileContent) as Map<String, Object?>);

        final tree = Tree(jsonTree.path);
        final treeElements = <TreeElement>[];

        void populateRecursive(
          final JsonTreeDirectory jsonTreeDirectory,
          final String? parent,
        ) {
          for (final jsonTreeDirectory in jsonTreeDirectory.directories) {
            final treeDirectory = TreeElement(
              jsonTreeDirectory.path,
              [tree].lock,
              TreeElementType.directory,
              parent,
            );

            treeElements.add(treeDirectory);

            populateRecursive(jsonTreeDirectory, treeDirectory.path);
          }

          for (final jsonTreeFile in jsonTreeDirectory.files) {
            treeElements.add(
              TreeElement(
                jsonTreeFile.path,
                [tree].lock,
                TreeElementType.file,
                parent,
              ),
            );
          }
        }

        populateRecursive(jsonTree, null);

        trees.add((treeElements, tree));
      } catch (exception) {
        failedFiles[lib_path.basename(file.path)] = exception.toString();
      }
    }

    return (trees, failedFiles);
  }

  List<TreeElement> mergeTreeElements(
    final List<List<TreeElement>> allTreeElements,
  ) {
    if (allTreeElements.isEmpty) {
      return [];
    }

    final result = allTreeElements.first;

    for (int i = 1; i < allTreeElements.length; i++) {
      final treeElements = allTreeElements[i];

      for (final treeElement in treeElements) {
        final addedTreeElement = result.firstWhereOrNull(
          (final addedTreeElement) => addedTreeElement.matchesSignature(
            treeElement.path,
            treeElement.type,
            treeElement.parent,
          ),
        );

        if (addedTreeElement != null) {
          result.remove(addedTreeElement);

          result.add(
            TreeElement(
              treeElement.path,
              [
                ...treeElement.containingTrees,
                ...addedTreeElement.containingTrees,
              ].lock,
              treeElement.type,
              treeElement.parent,
            ),
          );
        } else {
          result.add(treeElement);
        }
      }
    }

    return result;
  }
}
