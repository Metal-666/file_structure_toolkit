part of 'root.dart';

class Bloc extends flutter_bloc.Bloc<Event, State> {
  Bloc() : super(const State()) {
    on<Startup>((final event, final emit) async {
      await Settings.init();

      emit(
        state.copyWith(
          themeFlavorName: () =>
              Settings.themeFlavorName.value ?? themeFlavorMap.keys.first,
          languageLocale: () => Settings.languageLocale.value,
        ),
      );
    });
    on<ChangeTheme>(
      (final event, final emit) async {
        if (event.flavorName == state.themeFlavorName) {
          return;
        }

        await Settings.themeFlavorName.save(event.flavorName);

        emit(state.copyWith(themeFlavorName: () => event.flavorName));
      },
    );
    on<ChangeLocale>(
      (final event, final emit) async {
        if (event.languageLocale == state.languageLocale) {
          return;
        }

        await Settings.languageLocale.save(event.languageLocale);

        emit(state.copyWith(languageLocale: () => event.languageLocale));
      },
    );
  }
}
