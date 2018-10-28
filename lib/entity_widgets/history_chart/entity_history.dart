part of '../../main.dart';

class EntityHistoryWidgetType {
  static const int simple = 0;
  static const int valueToTime = 1;
  static const int randomColors = 2;
}

class EntityHistoryWidget extends StatefulWidget {

  final int type;

  const EntityHistoryWidget({Key key, @required this.type}) : super(key: key);

  @override
  _EntityHistoryWidgetState createState() {
    return new _EntityHistoryWidgetState();
  }
}

class _EntityHistoryWidgetState extends State<EntityHistoryWidget> {

  List _history;
  bool _needToUpdateHistory;
  int _selectedId = -1;

  @override
  void initState() {
    super.initState();
    _needToUpdateHistory = true;
  }

  void _loadHistory(HomeAssistant ha, String entityId) {
    ha.getHistory(entityId).then((history){
      setState(() {
        _history = history.isNotEmpty ? history[0] : [];
        _needToUpdateHistory = false;
      });
    }).catchError((e) {
      TheLogger.error("Error loading $entityId history: $e");
      setState(() {
        _history = [];
        _needToUpdateHistory = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final HomeAssistantModel homeAssistantModel = HomeAssistantModel.of(context);
    final EntityModel entityModel = EntityModel.of(context);
    final Entity entity = entityModel.entity;
    if (!_needToUpdateHistory) {
      _needToUpdateHistory = true;
    } else {
      _loadHistory(homeAssistantModel.homeAssistant, entity.entityId);
    }
    return _buildChart();
  }

  Widget _buildChart() {
    List<Widget> children = [];
    if (_history == null) {
      children.add(
          Text("Loading history...")
      );
    } else if (_history.isEmpty) {
      children.add(
          Text("No history for last 24h")
      );
    } else {
      children.add(
          _selectChartWidget()
      );
    }
    children.add(Divider());
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, Entity.rowPadding, 0.0, Entity.rowPadding),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _selectChartWidget() {
    switch (widget.type) {
      case EntityHistoryWidgetType.simple: {
          return SimpleStateHistoryChartWidget(
            rawHistory: _history,
          );
      }

      case EntityHistoryWidgetType.valueToTime: {
        return NumericStateHistoryChartWidget(
          rawHistory: _history,
        );
      }

      default: {
        return SimpleStateHistoryChartWidget(
          rawHistory: _history,
        );
      }
    }

  }

}