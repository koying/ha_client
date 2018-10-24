part of 'main.dart';

class GroupBasedUI {
  List<HACView> views;

  GroupBasedUI() {
    views = [];
  }

  Widget build(BuildContext context) {
    return TabBarView(
        children: _buildViews(context)
    );
  }

  List<Widget> _buildViews(BuildContext context) {
    TheLogger.log("Debug", "Building UI");
    List<Widget> result = [];
    views.forEach((view) {
      result.add(
        view.build(context)
      );
    });
    return result;
  }

}

class HACView {
  List<HACCard> cards = [];
  List<Entity> badges = [];
  Entity linkedEntity;
  String name;
  String id;
  int count;

  HACView({
    this.name,
    this.id,
    this.count
  });

  Widget build(BuildContext context) {
    return NewViewWidget(
      view: this,
    );
  }
}

class NewViewWidget extends StatefulWidget {
  final HACView view;

  const NewViewWidget({
    Key key,
    this.view
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return NewViewWidgetState();
  }

}

class NewViewWidgetState extends State<NewViewWidget> {

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

    widget.view.cards.forEach((HACCard card){
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
      TheLogger.log("Debug","Previous data refresh is still in progress");
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

class HACCard {
  List<Entity> entities = [];
  Entity linkedEntity;
  String name;
  String id;

  HACCard({
    this.name,
    this.id,
    this.linkedEntity
  });

  Widget build(BuildContext context) {
    return NewCardWidget(
      card: this,
    );
  }

}

class NewCardWidget extends StatelessWidget {

  final HACCard card;

  const NewCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((card.linkedEntity!= null) && (card.linkedEntity.isHidden)) {
        return Container(width: 0.0, height: 0.0,);
    }
    List<Widget> body = [];
    body.add(_buildCardHeader());
    body.addAll(_buildCardBody(context));
    return Card(
        child: new Column(mainAxisSize: MainAxisSize.min, children: body)
    );
  }

  Widget _buildCardHeader() {
    var result;
    if ((card.name != null) && (card.name.trim().length > 0)) {
      result = new ListTile(
        title: Text("${card.name}",
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)),
      );
    } else {
      result = new Container(width: 0.0, height: 0.0);
    }
    return result;
  }

  List<Widget> _buildCardBody(BuildContext context) {
    List<Widget> result = [];
    card.entities.forEach((Entity entity) {
      if (!entity.isHidden) {
        result.add(
            Padding(
              padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
              child: entity.buildDefaultWidget(context),
            ));
      }
    });
    return result;
  }

}