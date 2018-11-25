part of '../main.dart';

class GlanceCardWidget extends StatelessWidget {

  final HACard card;

  const GlanceCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((card.linkedEntityWrapper!= null) && (card.linkedEntityWrapper.entity.isHidden)) {
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
    List<EntityWrapper> toShow = card.entities.where((entity) {return !entity.entity.isHidden;}).toList();
    int columnsCount = toShow.length >= card.columnsCount ? card.columnsCount : toShow.length;

    toShow.forEach((EntityWrapper entity) {
      result.add(
        FractionallySizedBox(
          widthFactor: 1/columnsCount,
          child: EntityModel(
            entityWrapper: entity,
            child: GlanceEntityContainer(
              showName: card.showName,
              showState: card.showState,
            ),
            handleTap: true
          ),
        )
      );
    });
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, Sizes.rowPadding, 0.0, 2*Sizes.rowPadding),
      child: Wrap(
        //alignment: WrapAlignment.spaceAround,
        runSpacing: Sizes.rowPadding*2,
        children: result,
      ),
    );
  }

}