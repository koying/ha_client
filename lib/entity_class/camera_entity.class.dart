part of '../main.dart';

class CameraEntity extends Entity {

  static const SUPPORT_ON_OFF = 1;

  CameraEntity(Map rawData) : super(rawData);

  bool get supportOnOff => ((supportedFeatures &
  CameraEntity.SUPPORT_ON_OFF) ==
      CameraEntity.SUPPORT_ON_OFF);

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return CameraControlsWidget(
      url: '$homeAssistantWebHost/api/camera_proxy_stream/$entityId?token=${this.attributes['access_token']}',
    );
  }
}