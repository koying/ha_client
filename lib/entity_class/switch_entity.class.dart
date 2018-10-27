part of '../main.dart';

class SwitchEntity extends Entity {
  SwitchEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return SwitchStateWidget();
  }
}