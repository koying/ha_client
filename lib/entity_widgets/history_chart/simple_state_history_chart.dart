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
          colorIndex: _parsedHistory.first.data[_selectedId].colorId,
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
    Map<String, int> cachedStates = {};
    for (var i = 0; i < widget.rawHistory.length; i++) {
      var stateData = widget.rawHistory[i];
      DateTime startTime = DateTime.tryParse(stateData["last_updated"])?.toLocal();
      DateTime endTime;
      if (i < (widget.rawHistory.length - 1)) {
        endTime = DateTime.tryParse(widget.rawHistory[i+1]["last_updated"])?.toLocal();
      } else {
        endTime = now;
      }
      if (cachedStates[stateData["state"]] == null) {
        cachedStates.addAll({"${stateData["state"]}": cachedStates.length});
      }
      data.add(SimpleEntityStateHistoryMoment(stateData["state"], startTime, endTime, i, cachedStates[stateData["state"]]));
    }
    data.add(SimpleEntityStateHistoryMoment(data.last.state, now, null, widget.rawHistory.length, data.last.colorId));
    if (_selectedId == -1) {
      _selectedId = 0;
    }
    return [
      new charts.Series<SimpleEntityStateHistoryMoment, DateTime>(
        id: 'State',
        strokeWidthPxFn: (SimpleEntityStateHistoryMoment historyMoment, __) => (historyMoment.id == _selectedId) ? 70.0 : 40.0,
        colorFn: (SimpleEntityStateHistoryMoment historyMoment, __) => EntityColors.chartHistoryStateColor(historyMoment.state, historyMoment.colorId),
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
  final int colorIndex;

  const HistoryControlWidget({Key key, this.onPrevTap, this.onNextTap, this.selectedTimeStart, this.selectedTimeEnd, this.selectedState, @ required this.colorIndex}) : super(key: key);

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
                        color: EntityColors.historyStateColor(selectedState, colorIndex),
                        fontSize: 22.0
                    ),
                  ),
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

class SimpleEntityStateHistoryMoment {
  final DateTime startTime;
  final DateTime endTime;
  final String state;
  final int id;
  final int colorId;

  SimpleEntityStateHistoryMoment(this.state, this.startTime, this.endTime,  this.id, this.colorId);
}