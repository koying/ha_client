part of '../../main.dart';

class NumericStateHistoryChartWidget extends StatefulWidget {
  final rawHistory;
  final EntityHistoryConfig config;

  const NumericStateHistoryChartWidget({Key key, @required this.rawHistory, @required this.config}) : super(key: key);


  @override
  State<StatefulWidget> createState() {
    return new _NumericStateHistoryChartWidgetState();
  }

}

class _NumericStateHistoryChartWidgetState extends State<NumericStateHistoryChartWidget> {

  int _selectedId = -1;
  List<charts.Series<NumericEntityStateHistoryMoment, DateTime>> _parsedHistory;

  @override
  Widget build(BuildContext context) {
    _parsedHistory = _parseHistory();
    DateTime selectedTime;
    double selectedState;
    if ((_selectedId > -1) && (_parsedHistory != null) && (_parsedHistory.first.data.length >= (_selectedId + 1))) {
      selectedTime = _parsedHistory.first.data[_selectedId].time;
      selectedState = _parsedHistory.first.data[_selectedId].value;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        HistoryControlWidget(
          selectedTimeStart: selectedTime,
          selectedState: "$selectedState",
          onPrevTap: () => _selectPrev(),
          onNextTap: () => _selectNext(),
          colorIndex: -1,
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
              includePoints: true
            ),
            /*primaryMeasureAxis: charts.NumericAxisSpec(
                renderSpec: charts.NoneRenderSpec()
            ),*/
            selectionModels: [
              new charts.SelectionModelConfig(
                type: charts.SelectionModelType.info,
                listener: (model) => _onSelectionChanged(model),
              )
            ],
          ),
        )
      ],
    );
  }

  List<charts.Series<NumericEntityStateHistoryMoment, DateTime>> _parseHistory() {
    List<NumericEntityStateHistoryMoment> data = [];
    DateTime now = DateTime.now();
    for (var i = 0; i < widget.rawHistory.length; i++) {
      var stateData = widget.rawHistory[i];
      DateTime time = DateTime.tryParse(stateData["last_updated"])?.toLocal();
      data.add(NumericEntityStateHistoryMoment(double.tryParse(stateData["state"]), time, i));
    }
    data.add(NumericEntityStateHistoryMoment(data.last.value, now, widget.rawHistory.length));
    if (_selectedId == -1) {
      _selectedId = 0;
    }
    return [
      new charts.Series<NumericEntityStateHistoryMoment, DateTime>(
        id: 'State',
        colorFn: (NumericEntityStateHistoryMoment historyMoment, __) => EntityColors.chartHistoryStateColor("on", -1),
        domainFn: (NumericEntityStateHistoryMoment historyMoment, _) => historyMoment.time,
        measureFn: (NumericEntityStateHistoryMoment historyMoment, _) => historyMoment.value,
        data: data,
        radiusPxFn: (NumericEntityStateHistoryMoment historyMoment, __) => (historyMoment.id == _selectedId) ? 5.0 : 1.0,
      )
    ];
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

class NumericEntityStateHistoryMoment {
  final DateTime time;
  final double value;
  final int id;

  NumericEntityStateHistoryMoment(this.value, this.time,  this.id);
}