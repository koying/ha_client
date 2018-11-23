part of '../main.dart';

class EntityWrapper {

  String displayName;
  String icon;
  String tapAction;
  String holdAction;
  String tapActionService;
  Map<String, dynamic> tapActionServiceData;
  String holdActionService;
  Map<String, dynamic> holdActionServiceData;
  Entity entity;


  EntityWrapper({
    this.entity,
    String icon,
    String displayName,
    this.tapAction: EntityTapAction.moreInfo,
    this.holdAction: EntityTapAction.none,
    this.tapActionService,
    this.tapActionServiceData,
    this.holdActionService,
    this.holdActionServiceData
  }) {
    this.icon = icon ?? entity.icon;
    this.displayName = displayName ?? entity.displayName;
  }

  void handleTap() {
    switch (tapAction) {
      case EntityTapAction.toggle: {
        eventBus.fire(
            ServiceCallEvent("homeassistant", "toggle", entity.entityId, null));
        break;
      }

      case EntityTapAction.callService: {
        eventBus.fire(
            ServiceCallEvent(tapActionService.split(".")[0], tapActionService.split(".")[1], null, tapActionServiceData));
        break;
      }

      case EntityTapAction.none: {
        break;
      }

      default: {
        eventBus.fire(
            new ShowEntityPageEvent(entity));
        break;
      }
    }
  }

  void handleHold() {
      switch (holdAction) {
        case EntityTapAction.toggle: {
          eventBus.fire(
              ServiceCallEvent("homeassistant", "toggle", entity.entityId, null));
          break;
        }

        case EntityTapAction.callService: {
          eventBus.fire(
              ServiceCallEvent(tapActionService.split(".")[0], tapActionService.split(".")[1], null, tapActionServiceData));
          break;
        }

        case EntityTapAction.moreInfo: {
          eventBus.fire(
              new ShowEntityPageEvent(entity));
          break;
        }

        default: {
          break;
        }
      }
  }

}