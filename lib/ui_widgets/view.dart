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

  StreamSubscription _refreshDataSubscription;
  Completer _refreshCompleter;

  @override
  void initState() {
    super.initState();
    _refreshDataSubscription = eventBus.on<RefreshDataFinishedEvent>().listen((event) {
      if ((_refreshCompleter != null) && (!_refreshCompleter.isCompleted)) {
        _refreshCompleter.complete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.amber,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: _buildChildren(context),
      ),
      onRefresh: () => _refreshData(),
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

    widget.view.cards.forEach((HACard card){
      result.add(
          card.build(context)
      );
    });

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

  Future _refreshData() {
    if ((_refreshCompleter != null) && (!_refreshCompleter.isCompleted)) {
      TheLogger.debug("Previous data refresh is still in progress");
    } else {
      _refreshCompleter = Completer();
      eventBus.fire(RefreshDataEvent());
    }
    return _refreshCompleter.future;
  }

  @override
  void dispose() {
    _refreshDataSubscription.cancel();
    super.dispose();
  }


}