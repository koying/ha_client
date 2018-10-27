part of '../main.dart';

class CoverEntity extends Entity {
  @override
  double widgetHeight = 38.0;

  static const SUPPORT_OPEN = 1;
  static const SUPPORT_CLOSE = 2;
  static const SUPPORT_SET_POSITION = 4;
  static const SUPPORT_STOP = 8;
  static const SUPPORT_OPEN_TILT = 16;
  static const SUPPORT_CLOSE_TILT = 32;
  static const SUPPORT_STOP_TILT = 64;
  static const SUPPORT_SET_TILT_POSITION = 128;

  bool get supportOpen => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_OPEN) ==
      CoverEntity.SUPPORT_OPEN);
  bool get supportClose => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_CLOSE) ==
      CoverEntity.SUPPORT_CLOSE);
  bool get supportSetPosition => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_SET_POSITION) ==
      CoverEntity.SUPPORT_SET_POSITION);
  bool get supportStop => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_STOP) ==
      CoverEntity.SUPPORT_STOP);

  bool get supportOpenTilt => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_OPEN_TILT) ==
      CoverEntity.SUPPORT_OPEN_TILT);
  bool get supportCloseTilt => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_CLOSE_TILT) ==
      CoverEntity.SUPPORT_CLOSE_TILT);
  bool get supportStopTilt => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_STOP_TILT) ==
      CoverEntity.SUPPORT_STOP_TILT);
  bool get supportSetTiltPosition => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_SET_TILT_POSITION) ==
      CoverEntity.SUPPORT_SET_TILT_POSITION);


  double get currentPosition => _getDoubleAttributeValue('current_position');
  double get currentTiltPosition => _getDoubleAttributeValue('current_tilt_position');
  bool get canBeOpened => ((state != "opening") && (state != "open"));
  bool get canBeClosed => ((state != "closing") && (state != "closed"));
  bool get canTiltBeOpened => currentPosition < 100;
  bool get canTiltBeClosed => currentPosition > 0;

  CoverEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return CoverStateWidget();
  }

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return CoverControlWidget();
  }

}