part of '../main.dart';

class LastUpdatedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Entity.leftWidgetPadding, 0.0, 0.0, 0.0),
      child: Text(
        '${entityModel.entity.lastUpdated}',
        textAlign: TextAlign.left,
        style: TextStyle(
            fontSize: Entity.smallFontSize, color: Colors.black26),
      ),
    );
  }
}