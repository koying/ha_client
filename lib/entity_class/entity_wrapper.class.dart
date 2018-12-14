part of '../main.dart';

class EntityWrapper {

  String displayName;
  String icon;
  EntityUIAction uiAction;
  Entity entity;


  EntityWrapper({
    this.entity,
    String icon,
    String displayName,
    this.uiAction
  }) {
    this.icon = icon ?? entity.icon;
    this.displayName = displayName ?? entity.displayName;
    if (this.uiAction == null) {
      this.uiAction = EntityUIAction();
    }
  }

  void handleTap() {
    switch (uiAction.tapAction) {
      case EntityUIAction.toggle: {
        eventBus.fire(
            ServiceCallEvent("homeassistant", "toggle", entity.entityId, null));
        break;
      }

      case EntityUIAction.callService: {
        if (uiAction.tapService != null) {
          eventBus.fire(
              ServiceCallEvent(uiAction.tapService.split(".")[0],
                  uiAction.tapService.split(".")[1], null,
                  uiAction.tapServiceData));
        }
        break;
      }

      case EntityUIAction.none: {
        break;
      }

      case EntityUIAction.moreInfo: {
        eventBus.fire(
            new ShowEntityPageEvent(entity));
        break;
      }

      default: {
        break;
      }
    }
  }

  void handleHold() {
      switch (uiAction.holdAction) {
        case EntityUIAction.toggle: {
          eventBus.fire(
              ServiceCallEvent("homeassistant", "toggle", entity.entityId, null));
          break;
        }

        case EntityUIAction.callService: {
          if (uiAction.holdService != null) {
            eventBus.fire(
                ServiceCallEvent(uiAction.holdService.split(".")[0],
                    uiAction.holdService.split(".")[1], null,
                    uiAction.holdServiceData));
          }
          break;
        }

        case EntityUIAction.moreInfo: {
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