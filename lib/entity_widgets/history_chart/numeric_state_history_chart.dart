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
          selectedState: "${selectedState ?? '-'}",
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
      double value = double.tryParse(stateData["state"]);
      double previousValue = 0.0;
      bool hiddenDot = (value == null);
      bool hiddenLine;
      if (hiddenDot && i > 0) {
        previousValue = data[i-1].value ?? data[i-1].previousValue;
      }
      if (i < (widget.rawHistory.length - 1)) {
        double nextValue = double.tryParse(widget.rawHistory[i+1]["state"]);
        hiddenLine = (nextValue == null || hiddenDot);
      } else {
        hiddenLine = hiddenDot;
      }
      data.add(NumericEntityStateHistoryMoment(value, previousValue, hiddenDot, hiddenLine, time, i));
    }
    data.add(NumericEntityStateHistoryMoment(data.last.value, data.last.previousValue,  data.last.hiddenDot, data.last.hiddenLine, now, widget.rawHistory.length));
    if (_selectedId == -1) {
      _selectedId = 0;
    }
    return [
      new charts.Series<NumericEntityStateHistoryMoment, DateTime>(
        id: 'State',
        colorFn: (NumericEntityStateHistoryMoment historyMoment, __) => EntityColors.chartHistoryStateColor("on", -1),
        domainFn: (NumericEntityStateHistoryMoment historyMoment, _) => historyMoment.time,
        measureFn: (NumericEntityStateHistoryMoment historyMoment, _) => historyMoment.value ?? historyMoment.previousValue,
        data: data,
        strokeWidthPxFn: (NumericEntityStateHistoryMoment historyMoment, __) => historyMoment.hiddenLine ? 0.0 : 2.0,
        radiusPxFn: (NumericEntityStateHistoryMoment historyMoment, __) {
          if (historyMoment.hiddenDot) {
            return 0.0;
          } else if (historyMoment.id == _selectedId) {
            return 5.0;
          } else {
            return 1.0;
          }
        },
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
  final double previousValue;
  final int id;
  final bool hiddenDot;
  final bool hiddenLine;

  NumericEntityStateHistoryMoment(this.value, this.previousValue, this.hiddenDot, this.hiddenLine, this.time,  this.id);
}