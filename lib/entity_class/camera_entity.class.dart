part of '../main.dart';

class CameraEntity extends Entity {

  static const SUPPORT_ON_OFF = 1;

  CameraEntity(Map rawData) : super(rawData);

  bool get supportOnOff => ((attributes["supported_features"] &
  CameraEntity.SUPPORT_ON_OFF) ==
      CameraEntity.SUPPORT_ON_OFF);

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return CameraControlsWidget(
      url: 'https://citadel.vynn.co:8123${this.entityPicture}',
    );
  }
}