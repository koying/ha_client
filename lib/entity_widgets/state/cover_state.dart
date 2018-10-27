part of '../../main.dart';

class CoverStateWidget extends StatelessWidget {
  void _open(CoverEntity entity) {
    eventBus.fire(new ServiceCallEvent(
        entity.domain, "open_cover", entity.entityId, null));
  }

  void _close(CoverEntity entity) {
    eventBus.fire(new ServiceCallEvent(
        entity.domain, "close_cover", entity.entityId, null));
  }

  void _stop(CoverEntity entity) {
    eventBus.fire(new ServiceCallEvent(
        entity.domain, "stop_cover", entity.entityId, null));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final CoverEntity entity = entityModel.entity;
    List<Widget> buttons = [];
    if (entity.supportOpen) {
      buttons.add(IconButton(
          icon: Icon(
            MaterialDesignIcons.createIconDataFromIconName("mdi:arrow-up"),
            size: Entity.iconSize,
          ),
          onPressed: entity.canBeOpened ? () => _open(entity) : null));
    } else {
      buttons.add(Container(
        width: Entity.iconSize + 20.0,
      ));
    }
    if (entity.supportStop) {
      buttons.add(IconButton(
          icon: Icon(
            MaterialDesignIcons.createIconDataFromIconName("mdi:stop"),
            size: Entity.iconSize,
          ),
          onPressed: () => _stop(entity)));
    } else {
      buttons.add(Container(
        width: Entity.iconSize + 20.0,
      ));
    }
    if (entity.supportClose) {
      buttons.add(IconButton(
          icon: Icon(
            MaterialDesignIcons.createIconDataFromIconName("mdi:arrow-down"),
            size: Entity.iconSize,
          ),
          onPressed: entity.canBeClosed ? () => _close(entity) : null));
    } else {
      buttons.add(Container(
        width: Entity.iconSize + 20.0,
      ));
    }

    return Row(
      children: buttons,
    );
  }
}