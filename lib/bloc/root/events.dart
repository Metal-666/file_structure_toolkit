part of 'root.dart';

abstract class Event {
  const Event();
}

class Startup extends Event {
  const Startup();
}

class ChangeTheme extends Event {
  final String? flavorName;

  const ChangeTheme(this.flavorName);
}
