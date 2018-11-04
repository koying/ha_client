part of '../main.dart';

class DefaultEntityContainer extends StatelessWidget {
  DefaultEntityContainer({
    Key key,
    @required this.state,
    @required this.height
  }) : super(key: key);

  final Widget state;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      //height: height,
      child: Row(
        children: <Widget>[
          EntityIcon(),
          Expanded(
            child: EntityName(),
          ),
          state
        ],
      ),
    );
  }
}