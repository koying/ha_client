part of '../main.dart';

class GlanceCardWidget extends StatelessWidget {

  final HACard card;

  const GlanceCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((card.linkedEntity!= null) && (card.linkedEntity.entity.isHidden)) {
      return Container(width: 0.0, height: 0.0,);
    }
    List<Widget> rows = [];
    rows.add(CardHeaderWidget(name: card.name));
    rows.add(_buildRows(context));
    return Card(
        child: new Column(mainAxisSize: MainAxisSize.min, children: rows)
    );
  }

  Widget _buildRows(BuildContext context) {
    List<Widget> result = [];
    double width = MediaQuery.of(context).size.width - Sizes.leftWidgetPadding - (2*Sizes.rightWidgetPadding);
    List<EntityWrapper> toShow = card.entities.where((entity) {return !entity.entity.isHidden;}).toList();
    int columnsCount = toShow.length >= card.columnsCount ? card.columnsCount : toShow.length;
    card.entities.forEach((EntityWrapper entity) {
      if (!entity.entity.isHidden) {
        result.add(
          SizedBox(
            width: width / columnsCount,
            child: EntityModel(
              entityWrapper: entity,
              child: entity.entity.buildGlanceWidget(context, card.showName, card.showState),
              handleTap: true
            ),
          )
        );
      }
    });
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, Sizes.rowPadding, 0.0, 2*Sizes.rowPadding),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runSpacing: Sizes.rowPadding*2,
        children: result,
      ),
    );
  }

}