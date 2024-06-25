part of 'root.dart';

class Bloc extends flutter_bloc.Bloc<Event, State> {
  Bloc() : super(const State()) {
    on<Startup>((final event, final emit) async {
      await Settings.init();

      emit(
        state.copyWith(
          themeFlavorName: () =>
              Settings.themeFlavorName.value ?? themeFlavorMap.keys.first,
        ),
      );
    });
    on<ChangeTheme>(
      (final event, final emit) async {
        await Settings.themeFlavorName.save(event.flavorName);

        emit(state.copyWith(themeFlavorName: () => event.flavorName));
      },
    );
  }
}
