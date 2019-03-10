part of '../main.dart';

class LockEntity extends Entity {
  LockEntity(Map rawData) : super(rawData);

  bool get isLocked => state == "locked";

  @override
  Widget _buildStatePart(BuildContext context) {
    return LockStateWidget(
      assumedState: false,
    );
  }

  @override
  Widget _buildStatePartForPage(BuildContext context) {
    return LockStateWidget(
      assumedState: true,
    );
  }
}