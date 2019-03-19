part of '../main.dart';

class SwitchEntity extends Entity {
  SwitchEntity(Map rawData, String webHost) : super(rawData, webHost);

  @override
  Widget _buildStatePart(BuildContext context) {
    return SwitchStateWidget();
  }
}