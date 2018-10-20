part of 'main.dart';

class View extends StatefulWidget {
  final String displayName;
  final List<Entity> childEntities;
  final int count;

  View({
    Key key,
    @required this.childEntities,
    @required this.count,
    this.displayName
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ViewState();
  }

}

class ViewState extends State<View> {

  StreamSubscription _refreshDataSubscription;
  Completer _refreshCompleter;
  List<Entity> _childEntitiesAsBadges;
  Map<String, Entity> _childEntitiesAsCards;

  @override
  void initState() {
    super.initState();
    _refreshDataSubscription = eventBus.on<RefreshDataFinishedEvent>().listen((event) {
      if ((_refreshCompleter != null) && (!_refreshCompleter.isCompleted)) {
        _refreshCompleter.complete();
      }
    });
    _childEntitiesAsCards = {};
    _childEntitiesAsBadges = [];
    _composeEntities();
  }

  void _composeEntities() {
    widget.childEntities.forEach((Entity entity){
      if (!entity.isGroup) {
        if (entity.isBadge) {
          _childEntitiesAsBadges.add(entity);
        } else {
          String groupIdToAdd = "${entity.domain}.${entity.domain}${widget.count}";
          if (_childEntitiesAsCards[groupIdToAdd] == null) {
            _childEntitiesAsCards[groupIdToAdd] = entity;
          }
          _childEntitiesAsCards[groupIdToAdd].childEntities.add(entity);
        }
      } else {
        _childEntitiesAsCards[entity.entityId] = entity;
        _childEntitiesAsCards[entity.entityId].childEntities = entity.childEntities;
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

    if (_childEntitiesAsBadges.isNotEmpty) {
      result.insert(0,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10.0,
            runSpacing: 1.0,
            children: _buildBadges(context),
          )
      );
    }

    _childEntitiesAsCards.forEach((String id, Entity groupEntity){
      result.add(
          HACard(
            entities: groupEntity.childEntities,
            friendlyName: groupEntity.displayName,
            hidden: groupEntity.isHidden
          )
      );
    });

    return result;
  }

  List<Widget> _buildBadges(BuildContext context) {
    List<Widget> result = [];
    _childEntitiesAsBadges.forEach((Entity entity) {
      result.add(entity.buildBadgeWidget(context));
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