part of '../../main.dart';

class LockStateWidget extends StatelessWidget {

  void _lock(Entity entity) {
    eventBus.fire(new ServiceCallEvent("lock", "lock", entity.entityId, null));
  }

  void _unlock(Entity entity) {
    eventBus.fire(new ServiceCallEvent("lock", "unlock", entity.entityId, null));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final LockEntity entity = entityModel.entityWrapper.entity;
    return SizedBox(
      height: 34.0,
      child: FlatButton(
        onPressed: (() {
          entity.isLocked ? _unlock(entity) : _lock(entity);
        }),
        child: Text(
          entity.isLocked ? "UNLOCK" : "LOCK",
          textAlign: TextAlign.right,
          style:
          new TextStyle(fontSize: Sizes.stateFontSize, color: Colors.blue),
        ),
      )
    );
  }
}