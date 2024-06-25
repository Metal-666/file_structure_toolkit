import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '/bloc/root/home/home.dart' as home;
import '/bloc/root/root.dart' as root;

const treeFilefilterSpecification = {'JSON file': '*.json'};

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(final context) => _pageRoot(
        _mainPanel(
          _menuBar(),
          _treesPanel(
            _treePanelBuilder,
          ),
        ),
        _dropOverlay(),
        _directoryScanOverlay(),
      );

  BlocProvider<home.Bloc> _pageRoot(
    final Widget mainPanel,
    final Widget dropOverlay,
    final Widget directoryScanOverlay,
  ) =>
      BlocProvider(
        create: (final context) => home.Bloc()..add(const home.Startup()),
        child: Scaffold(
          body: BlocConsumer<home.Bloc, home.State>(
            listenWhen: (final previous, final current) =>
                current.failedTreeFiles.isNotEmpty,
            listener: (final context, final state) async {
              await showDialog<void>(
                context: context,
                builder: (final context) =>
                    _failedFilesDialog(context, state.failedTreeFiles),
              );

              if (!context.mounted) {
                log('Huh?');

                return;
              }

              context.read<home.Bloc>().add(const home.SeenFailedFiles());
            },
            buildWhen: (final previous, final current) =>
                previous.failedTreeFiles != current.failedTreeFiles,
            builder: (final context, final state) => DropTarget(
              enable: state.failedTreeFiles.isEmpty,
              onDragEntered: (final details) =>
                  context.read<home.Bloc>().add(home.DragEntered(details)),
              onDragExited: (final details) =>
                  context.read<home.Bloc>().add(home.DragExited(details)),
              onDragDone: (final details) =>
                  context.read<home.Bloc>().add(home.DragDone(details)),
              child: Stack(
                children: [
                  mainPanel,
                  dropOverlay,
                  directoryScanOverlay,
                ],
              ),
            ),
          ),
        ),
      );

  Widget _mainPanel(
    final Widget menuBar,
    final Widget treesPanel,
  ) =>
      Column(
        children: [
          menuBar,
          Expanded(child: treesPanel),
        ],
      );

  Widget _menuBar() => Builder(
        builder: (final context) {
          final theme = Theme.of(context);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final directoryPicker = DirectoryPicker()
                        ..title = 'Pick Directory to Scan:';

                      final directory = directoryPicker.getDirectory();

                      if (directory == null) {
                        return;
                      }

                      context
                          .read<home.Bloc>()
                          .add(home.ChoseDirectoryToScan(directory));
                    },
                    icon: const Icon(FluentIcons.search_16_regular),
                    label: const Text('Scan'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final filePicker = OpenFilePicker()
                        ..title = 'Pick File to Import:'
                        ..fileMustExist = true
                        ..filterSpecification = treeFilefilterSpecification;

                      final files = filePicker.getFiles();

                      if (files.isEmpty) {
                        return;
                      }

                      context.read<home.Bloc>().add(home.ImportTrees(files));
                    },
                    icon: const Icon(FluentIcons.arrow_import_16_regular),
                    label: const Text('Import'),
                  ),
                  const Spacer(),
                  BlocBuilder<root.Bloc, root.State>(
                    buildWhen: (final previous, final current) =>
                        previous.themeFlavorName != current.themeFlavorName,
                    builder: (final context, final state) => MenuAnchor(
                      menuChildren: [
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            'Theme:',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const Divider(height: 0),
                        ...root.themeFlavorMap.keys.map(
                          (final flavor) => MenuItemButton(
                            style: MenuItemButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () => context
                                .read<root.Bloc>()
                                .add(root.ChangeTheme(flavor)),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    flavor,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                if (flavor == state.themeFlavorName)
                                  Icon(
                                    FluentIcons.checkmark_16_regular,
                                    color: theme.colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      builder: (
                        final context,
                        final controller,
                        final child,
                      ) =>
                          IconButton(
                        padding: const EdgeInsets.all(4),
                        onPressed: () => controller.isOpen
                            ? controller.close()
                            : controller.open(),
                        icon: Image.network(
                          'https://github.com/catppuccin/catppuccin/blob/main/assets/logos/exports/1544x1544_circle.png?raw=true',
                          height: 35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _treesPanel(
    final Widget Function(
      BuildContext context,
      home.Tree tree,
      IList<home.TreeElement> elements,
    ) treePanelBuilder,
  ) =>
      BlocBuilder<home.Bloc, home.State>(
        buildWhen: (final previous, final current) =>
            previous.trees != current.trees,
        builder: (final context, final state) => Row(
          children: state.trees
              .map(
                (final tree) => Expanded(
                  child: treePanelBuilder(
                    context,
                    tree,
                    state.treeElements,
                  ),
                ),
              )
              .toList(),
        ),
      );

  Widget _treePanelBuilder(
    final BuildContext context,
    final home.Tree tree,
    final IList<home.TreeElement> treeElements,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final treeController = TreeController<home.TreeElement>(
      roots:
          treeElements.where((final treeElement) => treeElement.parent == null),
      childrenProvider: (final treeElement) => switch (treeElement.type) {
        home.TreeElementType.file => [],
        home.TreeElementType.directory => treeElements.where(
            (final childTreeElement) =>
                childTreeElement.parent == treeElement.path,
          ),
      },
      defaultExpansionState: true,
    );

    final missingElements = treeElements.count(
      (final treeElement) => !treeElement.containingTrees.contains(tree),
    );
    final isMissingElements = missingElements > 0;

    return Column(
      children: [
        Card(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(tree.path),
              ),
              Text(
                isMissingElements
                    ? 'Missing elements: $missingElements'
                    : 'No missing elements!',
                style: textTheme.bodyMedium?.copyWith(
                  color: isMissingElements
                      ? colorScheme.error
                      : colorScheme.secondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  final saveFilePicker = SaveFilePicker()
                    ..title = 'Export scan results:'
                    ..filterSpecification = treeFilefilterSpecification
                    ..fileName = 'tree'
                    ..defaultExtension = '.json';

                  final file = saveFilePicker.getFile();

                  if (file == null) {
                    return;
                  }

                  context.read<home.Bloc>().add(home.ExportScan(file, tree));
                },
                icon: const Icon(FluentIcons.arrow_export_16_regular),
              ),
              IconButton(
                onPressed: () {
                  if (treeController.isTreeExpanded) {
                    treeController.collapseAll();
                  } else {
                    treeController.expandAll();
                  }
                },
                icon:
                    const Icon(FluentIcons.arrow_maximize_vertical_20_regular),
              ),
              IconButton(
                onPressed: () =>
                    context.read<home.Bloc>().add(home.CloseTreeTab(tree)),
                icon: const Icon(FluentIcons.dismiss_16_regular),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedTreeView<home.TreeElement>(
            treeController: treeController,
            nodeBuilder: (
              final BuildContext context,
              final TreeEntry<home.TreeElement> entry,
            ) {
              final treeElement = entry.node;

              final isMissing = !treeElement.containingTrees.contains(tree);
              final foregroundColor =
                  isMissing ? colorScheme.onError : colorScheme.onSurface;

              return TextButton(
                onPressed: () => treeController.toggleExpansion(treeElement),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                  shape: const LinearBorder(),
                  backgroundColor:
                      isMissing ? colorScheme.error : colorScheme.surface,
                ),
                child: TreeIndentation(
                  guide: IndentGuide.connectingLines(
                    color: foregroundColor,
                    indent: 25,
                  ),
                  entry: entry,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        Text(
                          treeElement.childrenScanError == null
                              ? treeElement.name
                              : '${treeElement.name} [SCAN FAILED: ${treeElement.childrenScanError}]',
                          style: textTheme.labelLarge?.copyWith(
                            color: foregroundColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dropOverlay() => IgnorePointer(
        child: BlocBuilder<home.Bloc, home.State>(
          buildWhen: (final previous, final current) =>
              previous.isDraggingOver != current.isDraggingOver,
          builder: (final context, final state) {
            final theme = Theme.of(context);

            return AnimatedOpacity(
              opacity: state.isDraggingOver ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: theme.colorScheme.primary.withOpacity(0.4),
                child: Center(
                  child: Text(
                    '<Drop file here>',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _directoryScanOverlay() => BlocBuilder<home.Bloc, home.State>(
        buildWhen: (final previous, final current) =>
            previous.currentlyScanningDirectory !=
            current.currentlyScanningDirectory,
        builder: (final context, final state) {
          final visible = state.currentlyScanningDirectory != null;

          return IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                              BlocBuilder<home.Bloc, home.State>(
                                buildWhen: (final previous, final current) =>
                                    current.currentlyScanningDirectory != null,
                                builder: (final context, final state) => Text(
                                  'Scanning directory: ${state.currentlyScanningDirectory}',
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => context
                                .read<home.Bloc>()
                                .add(home.CancelDirectoryScan()),
                            icon: const Icon(FluentIcons.dismiss_16_regular),
                            label: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _failedFilesDialog(
    final BuildContext context,
    final IMap<String, String> failedFiles,
  ) =>
      AlertDialog(
        title: const Text('Failed to load files:'),
        content: Column(
          children: failedFiles.entries
              .map((final failedFile) => Text(failedFile.key))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ok'),
          ),
        ],
      );
}
