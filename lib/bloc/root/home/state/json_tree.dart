part of '../home.dart';

@JsonCodable()
abstract class JsonTreeElementBase {
  final String path;

  const JsonTreeElementBase(this.path);
}

@JsonCodable()
class JsonTreeDirectory extends JsonTreeElementBase {
  final List<JsonTreeDirectory> directories;
  final List<JsonTreeFile> files;

  JsonTreeDirectory(
    super.path, {
    final List<JsonTreeDirectory>? directories,
    final List<JsonTreeFile>? files,
  })  : directories = directories ?? [],
        files = files ?? [];
}

@JsonCodable()
class JsonTree extends JsonTreeDirectory {
  JsonTree(
    super.path, {
    super.directories,
    super.files,
  });
}

@JsonCodable()
class JsonTreeFile extends JsonTreeElementBase {
  const JsonTreeFile(super.path);
}
