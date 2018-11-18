part of '../main.dart';

class DefaultEntityContainer extends StatelessWidget {
  DefaultEntityContainer({
    Key key,
    @required this.state
  }) : super(key: key);

  final Widget state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        EntityIcon(),

        Flexible(
          fit: FlexFit.tight,
          flex: 3,
          child: EntityName(),
        ),
        state
      ],
    );
  }
}