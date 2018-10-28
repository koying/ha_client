part of '../../main.dart';

class SimpleStateHistoryChartWidget extends StatefulWidget {
  final rawHistory;

  const SimpleStateHistoryChartWidget({Key key, this.rawHistory}) : super(key: key);


  @override
  State<StatefulWidget> createState() {
    return new _SimpleStateHistoryChartWidgetState();
  }

}

class _SimpleStateHistoryChartWidgetState extends State<SimpleStateHistoryChartWidget> {

  int _selectedId = -1;
  List<charts.Series<SimpleEntityStateHistoryMoment, DateTime>> _parsedHistory;

  @override
  Widget build(BuildContext context) {
    _parsedHistory = _parseHistory();
    DateTime selectedTimeStart;
    DateTime selectedTimeEnd;
    String selectedState;
    if ((_selectedId > -1) && (_parsedHistory != null) && (_parsedHistory.first.data.length >= (_selectedId + 1))) {
      selectedTimeStart = _parsedHistory.first.data[_selectedId].startTime;
      selectedTimeEnd = _parsedHistory.first.data[_selectedId].endTime;
      selectedState = _parsedHistory.first.data[_selectedId].state;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        HistoryControlWidget(
          selectedTimeStart: selectedTimeStart,
          selectedTimeEnd: selectedTimeEnd,
          selectedState: selectedState,
          onPrevTap: () => _selectPrev(),
          onNextTap: () => _selectNext(),
        ),
        SizedBox(
          height: 70.0,
          child: charts.TimeSeriesChart(
            _parsedHistory,
            animate: false,
            dateTimeFactory: const charts.LocalDateTimeFactory(),
            primaryMeasureAxis: charts.NumericAxisSpec(
                renderSpec: charts.NoneRenderSpec()
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

  List<charts.Series<SimpleEntityStateHistoryMoment, DateTime>> _parseHistory() {
    List<SimpleEntityStateHistoryMoment> data = [];
    DateTime now = DateTime.now();
    for (var i = 0; i < widget.rawHistory.length; i++) {
      var stateData = widget.rawHistory[i];
      DateTime startTime = DateTime.tryParse(stateData["last_updated"])?.toLocal();
      DateTime endTime;
      if (i < (widget.rawHistory.length - 1)) {
        endTime = DateTime.tryParse(widget.rawHistory[i+1]["last_updated"])?.toLocal();
      } else {
        endTime = now;
      }
      data.add(SimpleEntityStateHistoryMoment(stateData["state"], startTime, endTime, i));
    }
    data.add(SimpleEntityStateHistoryMoment(data.last.state, now, null, widget.rawHistory.length));
    return [
      new charts.Series<SimpleEntityStateHistoryMoment, DateTime>(
        id: 'State',
        strokeWidthPxFn: (SimpleEntityStateHistoryMoment historyMoment, __) => (historyMoment.id == _selectedId) ? 70.0 : 40.0,
        colorFn: (SimpleEntityStateHistoryMoment historyMoment, __) => EntityColors.historyStateColor(historyMoment.state),
        domainFn: (SimpleEntityStateHistoryMoment historyMoment, _) => historyMoment.startTime,
        measureFn: (SimpleEntityStateHistoryMoment historyMoment, _) => 0,
        data: data,
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
    if (_selectedId < (_parsedHistory.first.data.length - 2)) {
      setState(() {
        _selectedId += 1;
      });
    }
  }

  void _onSelectionChanged(charts.SelectionModel model) {
    final selectedDatum = model.selectedDatum;

    int selectedId;

    if ((selectedDatum.isNotEmpty) &&(selectedDatum.first.datum.endTime != null)) {
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

class HistoryControlWidget extends StatelessWidget {

  final Function onPrevTap;
  final Function onNextTap;
  final DateTime selectedTimeStart;
  final DateTime selectedTimeEnd;
  final String selectedState;

  const HistoryControlWidget({Key key, this.onPrevTap, this.onNextTap, this.selectedTimeStart, this.selectedTimeEnd, this.selectedState}) : super(key: key);

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
                  child: Text(
                    "$selectedState",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: EntityColors.stateColor(selectedState),
                        fontSize: 22.0
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("${formatDate(selectedTimeStart, [M, ' ', d, ', ', HH, ':', nn, ':', ss])}", textAlign: TextAlign.left,),
                    Text("${formatDate(selectedTimeEnd ?? selectedTimeStart, [M, ' ', d, ', ', HH, ':', nn, ':', ss])}", textAlign: TextAlign.left,),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                padding: EdgeInsets.all(0.0),
                iconSize: 40.0,
                onPressed: onNextTap,
              ),
            ],
          );

    } else {
      return Container(height: 32.0);
    }
  }

}

class SimpleEntityStateHistoryMoment {
  final DateTime startTime;
  final DateTime endTime;
  final String state;
  final int id;

  SimpleEntityStateHistoryMoment(this.state, this.startTime, this.endTime,  this.id);
}