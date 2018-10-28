part of '../main.dart';

class EntityHistoryWidgetType {
  static const int simplest = 0;
  static const int valueToTime = 0;
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
  DateTime _selectionTimeStart;
  DateTime _selectionTimeEnd;
  Map<String, String> _selectionData;
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
    if (_selectionTimeStart != null) {
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Text(
                "${_selectionData["State"]}",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectionData["State"] == "on" ? Colors.green : Colors.red
                ),
              ),
            ),
            Column(
              children: <Widget>[
                Text("${formatDate(_selectionTimeStart, [M, ' ', d, ', ', HH, ':', nn, ':', ss])}"),
                Text("${formatDate(_selectionTimeEnd ?? _selectionTimeStart, [M, ' ', d, ', ', HH, ':', nn, ':', ss])}"),
              ],
            )
          ],
        )
      );
    } else {
      children.add(
          Container(height: 32.0,)
      );
    }
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
          SizedBox(
            height: 70.0,
            child: charts.TimeSeriesChart(
              _createHistoryData(),
              animate: false,
              dateTimeFactory: const charts.LocalDateTimeFactory(),
              primaryMeasureAxis: charts.NumericAxisSpec(
                renderSpec: charts.NoneRenderSpec()
              ),
              selectionModels: [
                new charts.SelectionModelConfig(
                  type: charts.SelectionModelType.info,
                  listener: _onSelectionChanged,
                )
              ],
              behaviors: [
                charts.PanAndZoomBehavior(),
              ],
            ),
          )
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

  _onSelectionChanged(charts.SelectionModel model) {
    final selectedDatum = model.selectedDatum;

    DateTime timeStart;
    DateTime timeEnd;
    int selectedId;
    final measures = <String, String>{};

    if ((selectedDatum.isNotEmpty) &&(selectedDatum.first.datum.endTime != null)) {
      timeStart = selectedDatum.first.datum.startTime;
      timeEnd = selectedDatum.first.datum.endTime;
      selectedId = selectedDatum.first.datum.id;
      TheLogger.debug("Selected datum length is ${selectedDatum.length}");
      selectedDatum.forEach((charts.SeriesDatum datumPair) {
        measures[datumPair.series.displayName] = datumPair.datum.state;
      });
      setState(() {
        _selectionTimeStart = timeStart;
        _selectionTimeEnd = timeEnd;
        _selectionData = measures;
        _selectedId = selectedId;
        _needToUpdateHistory = false;
      });
    } else {
      setState(() {
        _needToUpdateHistory = false;
      });
    }
  }


  List<charts.Series<EntityStateHistoryMoment, DateTime>> _createHistoryData() {
    List<EntityStateHistoryMoment> data = [];
    DateTime now = DateTime.now();
    for (var i = 0; i < _history.length; i++) {
      var stateData = _history[i];
      DateTime startTime = DateTime.tryParse(stateData["last_updated"]);
      DateTime endTime;
      if (i < (_history.length - 1)) {
        endTime = DateTime.tryParse(_history[i+1]["last_updated"]);
      } else {
        endTime = now;
      }
      data.add(EntityStateHistoryMoment(stateData["state"], startTime, endTime, i));
    }
    data.add(EntityStateHistoryMoment(data.last.state, now, null, _history.length));
    return [
      new charts.Series<EntityStateHistoryMoment, DateTime>(
        id: 'State',
        strokeWidthPxFn: (EntityStateHistoryMoment historyMoment, __) => (historyMoment.id == _selectedId) ? 70.0 : 40.0,
        colorFn: ((EntityStateHistoryMoment historyMoment, __) {
          if (historyMoment.state == "on") {
            if (historyMoment.id == _selectedId) {
              return charts.MaterialPalette.green.makeShades(2)[0];
            } else {
              return charts.MaterialPalette.green.makeShades(2)[1];
            }
          } else {
            if (historyMoment.id == _selectedId) {
              return charts.MaterialPalette.red.makeShades(2)[0];
            } else {
              return charts.MaterialPalette.red.makeShades(2)[1];
            }
          }
        }),
        domainFn: (EntityStateHistoryMoment historyMoment, _) => historyMoment.startTime,
        measureFn: (EntityStateHistoryMoment historyMoment, _) => 0,
        data: data,
      )
    ];
  }

}

class EntityStateHistoryMoment {
  final DateTime startTime;
  final DateTime endTime;
  final String state;
  final int id;

  EntityStateHistoryMoment(this.state, this.startTime, this.endTime,  this.id);
}