part of '../../main.dart';

class FlatServiceButton extends StatelessWidget {

  final String serviceDomain;
  final String serviceName;
  final String text;
  final double fontSize;

  FlatServiceButton({
    Key key,
    this.serviceDomain,
    this.serviceName: "turn_on",
    @required this.text,
    this.fontSize: Sizes.stateFontSize
  }) : super(key: key);

  void _setNewState(Entity entity) {
    eventBus.fire(new ServiceCallEvent(serviceDomain ?? entity.domain, serviceName, entity.entityId, null));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return SizedBox(
        height: fontSize*2.5,
        child: FlatButton(
          onPressed: (() {
            _setNewState(entityModel.entityWrapper.entity);
          }),
          child: Text(
            text,
            textAlign: TextAlign.right,
            style:
            new TextStyle(fontSize: fontSize, color: Colors.blue),
          ),
        )
    );
  }
}