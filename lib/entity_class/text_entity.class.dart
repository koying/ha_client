part of '../main.dart';

class TextEntity extends Entity {
  TextEntity(Map rawData) : super(rawData);

  int get valueMinLength => attributes["min"] ?? -1;
  int get valueMaxLength => attributes["max"] ?? -1;
  String get valuePattern => attributes["pattern"] ?? null;
  bool get isTextField => attributes["mode"] == "text";
  bool get isPasswordField => attributes["mode"] == "password";

  @override
  Widget _buildStatePart(BuildContext context) {
    return TextInputStateWidget();
  }
}