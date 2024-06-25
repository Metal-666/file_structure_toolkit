part of 'root.dart';

class State {
  final String? themeFlavorName;

  const State({this.themeFlavorName});

  State copyWith({
    final String? Function()? themeFlavorName,
  }) =>
      State(
        themeFlavorName: themeFlavorName == null
            ? this.themeFlavorName
            : themeFlavorName.call(),
      );
}
