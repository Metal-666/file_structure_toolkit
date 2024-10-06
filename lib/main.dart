import 'package:flutter/material.dart';

import 'package:catppuccin_flutter/catppuccin_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '/bloc/root/root.dart' as root;
import '/pages/home.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(final BuildContext context) => BlocProvider(
        create: (final context) => root.Bloc()..add(const root.Startup()),
        child: BlocBuilder<root.Bloc, root.State>(
          buildWhen: (final previous, final current) =>
              previous.themeFlavorName != current.themeFlavorName ||
              previous.languageLocale != current.languageLocale,
          builder: (final context, final state) {
            final themeFlavor = root.themeFlavorMap[state.themeFlavorName] ??
                root.themeFlavorMap.values.first;

            final Flavor flavor = themeFlavor.$1;
            final Brightness brightness = themeFlavor.$2;

            final bool isDark = brightness == Brightness.dark;

            final themeData = ThemeData.from(
              useMaterial3: true,
              colorScheme: ColorScheme(
                brightness: brightness,
                primary: flavor.mauve,
                onPrimary: flavor.base,
                secondary: flavor.teal,
                onSecondary: isDark ? flavor.lavender : flavor.text,
                tertiary: flavor.flamingo,
                onTertiary: flavor.base,
                surface: flavor.mantle,
                onSurface: flavor.text,
                error: flavor.red,
                onError: flavor.base,
              ),
            );

            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(state.languageLocale),
              theme: themeData.copyWith(
                canvasColor: flavor.crust,
                scaffoldBackgroundColor: flavor.base,
                cardTheme: themeData.cardTheme.copyWith(
                  margin: const EdgeInsets.all(2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              home: const HomePage(),
            );
          },
        ),
      );
}
