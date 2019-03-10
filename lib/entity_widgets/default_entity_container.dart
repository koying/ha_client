part of '../main.dart';

class DefaultEntityContainer extends StatelessWidget {
  DefaultEntityContainer({
    Key key,
    @required this.state
  }) : super(key: key);

  final Widget state;

  @override
  Widget build(BuildContext context) {
    final EntityModel entityModel = EntityModel.of(context);
    return InkWell(
      onLongPress: () {
        if (entityModel.handleTap) {
          entityModel.entityWrapper.handleHold();
        }
      },
      onTap: () {
        if (entityModel.handleTap) {
          entityModel.entityWrapper.handleTap();
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          EntityIcon(),

          Flexible(
            fit: FlexFit.tight,
            flex: 3,
            child: EntityName(
              padding: EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 2.0),
            ),
          ),
          state
        ],
      ),
    );
  }
}