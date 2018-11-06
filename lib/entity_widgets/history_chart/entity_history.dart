part of '../../main.dart';

class EntityHistoryWidgetType {
  static const int simple = 0;
  static const int numericState = 1;
  static const int numericAttributes = 2;
}

class EntityHistoryConfig {
  final int chartType;
  final List<String> numericAttributesToShow;
  final bool numericState;

  EntityHistoryConfig({this.chartType, this.numericAttributesToShow, this.numericState: true});

}

class EntityHistoryWidget extends StatefulWidget {

  final EntityHistoryConfig config;

  const EntityHistoryWidget({Key key, @required this.config}) : super(key: key);

  @override
  _EntityHistoryWidgetState createState() {
    return new _EntityHistoryWidgetState();
  }
}

class _EntityHistoryWidgetState extends State<EntityHistoryWidget> {

  List _history;
  bool _needToUpdateHistory;

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
          Text("No history")
      );
    } else {
      children.add(
          _selectChartWidget()
      );
    }
    children.add(Divider());
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, Entity.rowPadding),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _selectChartWidget() {
    switch (widget.config.chartType) {

      case EntityHistoryWidgetType.simple: {
          return SimpleStateHistoryChartWidget(
            rawHistory: _history,
          );
      }

      case EntityHistoryWidgetType.numericState: {
        return NumericStateHistoryChartWidget(
          rawHistory: _history,
          config: widget.config,
        );
      }

      case EntityHistoryWidgetType.numericAttributes: {
        return CombinedHistoryChartWidget(
          rawHistory: _history,
          config: widget.config,
        );
      }

      default: {
        TheLogger.debug("  Simple selected as default");
        return SimpleStateHistoryChartWidget(
          rawHistory: _history,
        );
      }
    }

  }

}