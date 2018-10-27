part of '../main.dart';

class SelectEntity extends Entity {
  List<String> get listOptions => attributes["options"] != null
      ? (attributes["options"] as List).cast<String>()
      : [];

  SelectEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return SelectStateWidget();
  }
}