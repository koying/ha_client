part of '../main.dart';

class GlanceCardWidget extends StatelessWidget {

  final HACard card;

  const GlanceCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((card.linkedEntity!= null) && (card.linkedEntity.isHidden)) {
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
    List<Entity> toShow = card.entities.where((entity) {return !entity.isHidden;}).toList();
    int columnsCount = toShow.length >= card.columnsCount ? card.columnsCount : toShow.length;
    card.entities.forEach((Entity entity) {
      if (!entity.isHidden) {
        result.add(
          SizedBox(
            width: width / columnsCount,
            child: entity.buildGlanceWidget(context),
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