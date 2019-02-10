part of '../main.dart';

class ViewWidget extends StatefulWidget {
  final HAView view;

  const ViewWidget({
    Key key,
    this.view
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ViewWidgetState();
  }

}

class ViewWidgetState extends State<ViewWidget> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(0.0),
      //physics: const AlwaysScrollableScrollPhysics(),
      children: _buildChildren(context),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    List<Widget> result = [];

    if (widget.view.badges.isNotEmpty) {
      result.insert(0,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10.0,
            runSpacing: 1.0,
            children: _buildBadges(context),
          )
      );
    }

    List<Widget> cards = [];
    widget.view.cards.forEach((HACard card){
      cards.add(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: card.build(context),
          )
      );
    });

    result.add(
      Column (
        children: cards,
      )
    );

    return result;
  }

  List<Widget> _buildBadges(BuildContext context) {
    List<Widget> result = [];
    widget.view.badges.forEach((Entity entity) {
      if (!entity.isHidden) {
        result.add(entity.buildBadgeWidget(context));
      }
    });
    return result;
  }

  @override
  void dispose() {
    super.dispose();
  }


}