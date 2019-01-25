part of '../main.dart';

class ButtonEntity extends Entity {
  ButtonEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return FlatServiceButton(
      text: "EXECUTE",
    );
  }
}