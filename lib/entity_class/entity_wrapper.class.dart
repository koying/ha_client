part of '../main.dart';

class EntityWrapper {

  String displayName;
  String icon;
  String tapAction;
  String holdAction;
  String actionService;
  Map<String, dynamic> actionServiceData;
  Entity entity;


  EntityWrapper({
    this.entity,
    String icon,
    String displayName,
    this.tapAction: EntityTapAction.moreInfo,
    this.holdAction,
    this.actionService,
    this.actionServiceData
  }) {
    this.icon = icon ?? entity.icon;
    this.displayName = displayName ?? entity.displayName;
  }

}