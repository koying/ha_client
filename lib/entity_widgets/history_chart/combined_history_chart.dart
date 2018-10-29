part of '../../main.dart';

class CombinedHistoryChartWidget extends StatefulWidget {
  final rawHistory;
  final EntityHistoryConfig config;

  const CombinedHistoryChartWidget({Key key, @required this.rawHistory, @required this.config}) : super(key: key);


  @override
  State<StatefulWidget> createState() {
    return new _CombinedHistoryChartWidgetState();
  }

}

class _CombinedHistoryChartWidgetState extends State<CombinedHistoryChartWidget> {

  int _selectedId = -1;
  List<charts.Series<CombinedEntityStateHistoryMoment, DateTime>> _parsedHistory;

  @override
  Widget build(BuildContext context) {
    _parsedHistory = _parseHistory();
    DateTime selectedTime;
    List<String> selectedStates = [];
    List<int> colorIndexes = [];
    if ((_selectedId > -1) && (_parsedHistory != null) && (_parsedHistory.first.data.length >= (_selectedId + 1))) {
      selectedTime = _parsedHistory.first.data[_selectedId].time;
      _parsedHistory.where((item) { return item.id == "value"; }).forEach((item) {
        selectedStates.add("${item.data[_selectedId].value}");
        colorIndexes.add(item.data[_selectedId].colorId);
      });
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        CombinedHistoryControlWidget(
          selectedTimeStart: selectedTime,
          selectedStates: selectedStates,
          onPrevTap: () => _selectPrev(),
          onNextTap: () => _selectNext(),
          colorIndexes: colorIndexes,
        ),
        SizedBox(
          height: 150.0,
          child: charts.TimeSeriesChart(
            _parsedHistory,
            animate: false,
            primaryMeasureAxis: new charts.NumericAxisSpec(
                tickProviderSpec:
                new charts.BasicNumericTickProviderSpec(zeroBound: false)),
            dateTimeFactory: const charts.LocalDateTimeFactory(),
            defaultRenderer: charts.LineRendererConfig(
              includeArea: false,
              includePoints: true
            ),
            selectionModels: [
              new charts.SelectionModelConfig(
                type: charts.SelectionModelType.info,
                listener: (model) => _onSelectionChanged(model),
              )
            ],
            behaviors: [
              charts.PanAndZoomBehavior(),
            ],
          ),
        )
      ],
    );
  }

  double _parseToDouble(temp1) {
    if (temp1 is int) {
      return temp1.toDouble();
    } else if (temp1 is double) {
      return temp1;
    } else {
      return double.tryParse("$temp1");
    }
  }

  List<charts.Series<CombinedEntityStateHistoryMoment, DateTime>> _parseHistory() {
    TheLogger.debug("  parsing history...");
    Map<String, List<CombinedEntityStateHistoryMoment>> dataList = {};
    int colorIdCounter = 0;
    widget.config.numericAttributesToShow.forEach((String attrName) {
      TheLogger.debug("    parsing attribute $attrName");
      List<CombinedEntityStateHistoryMoment> data = [];
      DateTime now = DateTime.now();
      for (var i = 0; i < widget.rawHistory.length; i++) {
        var stateData = widget.rawHistory[i];
        DateTime time = DateTime.tryParse(stateData["last_updated"])?.toLocal();
        if (stateData["attributes"] != null) {
          data.add(CombinedEntityStateHistoryMoment(_parseToDouble(stateData["attributes"]["$attrName"]), stateData["state"], time, i, colorIdCounter));
        } else {
          data.add(CombinedEntityStateHistoryMoment(null, stateData["state"], time, i, colorIdCounter));
        }
      }
      data.add(CombinedEntityStateHistoryMoment(data.last.value, data.last.state, now, widget.rawHistory.length, colorIdCounter));
      dataList.addAll({attrName: data});
      colorIdCounter += 1;
    });

    if ((_selectedId == -1) && (dataList.isNotEmpty)) {
      _selectedId = 0;
    }
    List<charts.Series<CombinedEntityStateHistoryMoment, DateTime>> result = [];
    dataList.forEach((attrName, dataItem) {
      TheLogger.debug("  adding ${dataItem.length} data values");
      result.addAll([
        new charts.Series<CombinedEntityStateHistoryMoment, DateTime>(
          id: "value",
          colorFn: (CombinedEntityStateHistoryMoment historyMoment, __) => EntityColors.chartHistoryStateColor("_", historyMoment.colorId),
          radiusPxFn: (CombinedEntityStateHistoryMoment historyMoment, __) => (historyMoment.id == _selectedId) ? 5.0 : 1.0,
          domainFn: (CombinedEntityStateHistoryMoment historyMoment, _) => historyMoment.time,
          measureFn: (CombinedEntityStateHistoryMoment historyMoment, _) => historyMoment.value,
          data: dataItem,
          /*domainLowerBoundFn: (CombinedEntityStateHistoryMoment historyMoment, _) => historyMoment.time.subtract(Duration(hours: 1)),
          domainUpperBoundFn: (CombinedEntityStateHistoryMoment historyMoment, _) => historyMoment.time.add(Duration(hours: 1)),*/
        )
      ]);
    });
    return result;
  }

  void _selectPrev() {
    if (_selectedId > 0) {
      setState(() {
        _selectedId -= 1;
      });
    }
  }

  void _selectNext() {
    if (_selectedId < (_parsedHistory.first.data.length - 1)) {
      setState(() {
        _selectedId += 1;
      });
    }
  }

  void _onSelectionChanged(charts.SelectionModel model) {
    final selectedDatum = model.selectedDatum;

    int selectedId;

    if (selectedDatum.isNotEmpty) {
      selectedId = selectedDatum.first.datum.id;
      setState(() {
        _selectedId = selectedId;
      });
    } else {
      setState(() {
      });
    }
  }
}

class CombinedHistoryControlWidget extends StatelessWidget {

  final Function onPrevTap;
  final Function onNextTap;
  final DateTime selectedTimeStart;
  final DateTime selectedTimeEnd;
  final List<String> selectedStates;
  final List<int> colorIndexes;

  const CombinedHistoryControlWidget({Key key, this.onPrevTap, this.onNextTap, this.selectedTimeStart, this.selectedTimeEnd, this.selectedStates, @ required this.colorIndexes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedTimeStart != null) {
      return
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.chevron_left),
              padding: EdgeInsets.all(0.0),
              iconSize: 40.0,
              onPressed: onPrevTap,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: _buildStates(),
              ),
            ),
            _buildTime(),
            IconButton(
              icon: Icon(Icons.chevron_right),
              padding: EdgeInsets.all(0.0),
              iconSize: 40.0,
              onPressed: onNextTap,
            ),
          ],
        );

    } else {
      return Container(height: 48.0);
    }
  }

  Widget _buildStates() {
    List<Widget> children = [];
    for (int i = 0; i < selectedStates.length; i++) {
      children.add(
          Text(
            "${selectedStates[i]}",
            textAlign: TextAlign.right,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: EntityColors.historyStateColor(selectedStates[i], colorIndexes[i]),
                fontSize: 22.0
            ),
          )
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
  }

  Widget _buildTime() {
    List<Widget> children = [];
    children.add(
        Text("${formatDate(selectedTimeStart, [M, ' ', d, ', ', HH, ':', nn, ':', ss])}", textAlign: TextAlign.left,)
    );
    if (selectedTimeEnd != null) {
      children.add(
          Text("${formatDate(selectedTimeEnd, [M, ' ', d, ', ', HH, ':', nn, ':', ss])}", textAlign: TextAlign.left,)
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

}

class CombinedEntityStateHistoryMoment {
  final DateTime time;
  final double value;
  final int id;
  final int colorId;
  final String state;

  CombinedEntityStateHistoryMoment(this.value, this.state, this.time,  this.id, this.colorId);
}
