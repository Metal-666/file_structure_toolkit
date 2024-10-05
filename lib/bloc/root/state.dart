part of 'root.dart';

class State {
  final String? themeFlavorName;
  final String languageLocale;

  const State({
    this.themeFlavorName,
    this.languageLocale = 'en',
  });

  State copyWith({
    final String? Function()? themeFlavorName,
    final String Function()? languageLocale,
  }) =>
      State(
        themeFlavorName: themeFlavorName == null
            ? this.themeFlavorName
            : themeFlavorName.call(),
        languageLocale: languageLocale == null
            ? this.languageLocale
            : languageLocale.call(),
      );
}
