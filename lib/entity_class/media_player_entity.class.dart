part of '../main.dart';

class MediaPlayerEntity extends Entity {

  static const SUPPORT_PAUSE = 1;
  static const SUPPORT_SEEK = 2;
  static const SUPPORT_VOLUME_SET = 4;
  static const SUPPORT_VOLUME_MUTE = 8;
  static const SUPPORT_PREVIOUS_TRACK = 16;
  static const SUPPORT_NEXT_TRACK = 32;

  static const SUPPORT_TURN_ON = 128;
  static const SUPPORT_TURN_OFF = 256;
  static const SUPPORT_PLAY_MEDIA = 512;
  static const SUPPORT_VOLUME_STEP = 1024;
  static const SUPPORT_SELECT_SOURCE = 2048;
  static const SUPPORT_STOP = 4096;
  static const SUPPORT_CLEAR_PLAYLIST = 8192;
  static const SUPPORT_PLAY = 16384;
  static const SUPPORT_SHUFFLE_SET = 32768;
  static const SUPPORT_SELECT_SOUND_MODE = 65536;

  MediaPlayerEntity(Map rawData) : super(rawData);

  bool get supportPause => ((attributes["supported_features"] &
  MediaPlayerEntity.SUPPORT_PAUSE) ==
      MediaPlayerEntity.SUPPORT_PAUSE);
  bool get supportSeek => ((attributes["supported_features"] &
  MediaPlayerEntity.SUPPORT_SEEK) ==
      MediaPlayerEntity.SUPPORT_SEEK);
  bool get supportVolumeSet => ((attributes["supported_features"] &
  MediaPlayerEntity.SUPPORT_VOLUME_SET) ==
      MediaPlayerEntity.SUPPORT_VOLUME_SET);
  bool get supportVolumeMute => ((attributes["supported_features"] &
  MediaPlayerEntity.SUPPORT_VOLUME_MUTE) ==
      MediaPlayerEntity.SUPPORT_VOLUME_MUTE);
  bool get supportPreviousTrack => ((attributes["supported_features"] &
  MediaPlayerEntity.SUPPORT_PREVIOUS_TRACK) ==
      MediaPlayerEntity.SUPPORT_PREVIOUS_TRACK);
  bool get supportNextTrack => ((attributes["supported_features"] &
  MediaPlayerEntity.SUPPORT_NEXT_TRACK) ==
      MediaPlayerEntity.SUPPORT_NEXT_TRACK);

  bool get supportTurnOn => ((attributes["supported_features"] &
  MediaPlayerEntity.SUPPORT_TURN_ON) ==
      MediaPlayerEntity.SUPPORT_TURN_ON);
  bool get supportTurnOff => ((attributes["supported_features"] &
  MediaPlayerEntity.SUPPORT_TURN_OFF) ==
      MediaPlayerEntity.SUPPORT_TURN_OFF);

}