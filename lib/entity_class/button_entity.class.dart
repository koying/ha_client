part of '../main.dart';

class ButtonEntity extends Entity {
  ButtonEntity(Map rawData, String webHost) : super(rawData, webHost);


  @override
  Widget _buildStatePart(BuildContext context) {
    return FlatServiceButton(
      entityId: entityId,
      serviceDomain: domain,
      serviceName: 'turn_on',
      text: domain == "scene" ? "ACTIVATE" : "EXECUTE",
    );
  }
}