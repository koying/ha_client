part of '../main.dart';

class UnsupportedCardWidget extends StatelessWidget {

  final HACard card;

  const UnsupportedCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((card.linkedEntity!= null) && (card.linkedEntity.entity.isHidden)) {
      return Container(width: 0.0, height: 0.0,);
    }
    List<Widget> body = [];
    body.add(CardHeaderWidget(name: card.name ?? ""));
    body.addAll(_buildCardBody(context));
    return Card(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: body
        )
    );
  }

  List<Widget> _buildCardBody(BuildContext context) {
    List<Widget> result = [];
    if (card.linkedEntity != null) {
      result.addAll(<Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0.0, Sizes.rowPadding, 0.0, Sizes.rowPadding),
            child: EntityModel(
                entityWrapper: card.linkedEntity,
                handleTap: true,
                child: card.linkedEntity.entity.buildDefaultWidget(context)
            ),
          )
      ]);
    } else {
      result.addAll(<Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, Sizes.rowPadding, Sizes.rightWidgetPadding, Sizes.rowPadding),
          child: Text("'${card.type}' card is not supported yet"),
        ),
      ]);
    }
    return result;
  }

}