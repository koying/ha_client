part of '../main.dart';

class _DateTimeEntityWidgetState extends _EntityWidgetState {
  bool get hasDate => widget.entity._attributes["has_date"] ?? false;
  bool get hasTime => widget.entity._attributes["has_time"] ?? false;
  int get year => widget.entity._attributes["year"] ?? 1970;
  int get month => widget.entity._attributes["month"] ?? 1;
  int get day => widget.entity._attributes["day"] ?? 1;
  int get hour => widget.entity._attributes["hour"] ?? 0;
  int get minute => widget.entity._attributes["minute"] ?? 0;
  int get second => widget.entity._attributes["second"] ?? 0;
  String get formattedState => _getFormattedState();
  DateTime get dateTimeState => _getDateTimeState();

  DateTime _getDateTimeState() {
    return DateTime(this.year, this.month, this.day, this.hour, this.minute, this.second);
  }

  String _getFormattedState() {
    String formattedState = "";
    if (this.hasDate) {
      formattedState += formatDate(dateTimeState, [M, ' ', d, ', ', yyyy]);
    }
    if (this.hasTime) {
      formattedState += " "+formatDate(dateTimeState, [HH, ':', nn]);
    }
    return formattedState;
  }

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(widget.entity.domain, "set_datetime", widget.entity.entityId,
        newValue));
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    return Padding(
        padding:
        EdgeInsets.fromLTRB(0.0, 0.0, Entity.RIGHT_WIDGET_PADDING, 0.0),
        child: GestureDetector(
          child: Text(
              "$formattedState",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: Entity.STATE_FONT_SIZE,
              )),
          onTap: () => _handleStateTap(context),
        )
    );
  }

  void _handleStateTap(BuildContext context) {
    if (hasDate) {
      _showDatePicker(context).then((date) {
        if (date != null) {
          if (hasTime) {
            _showTimePicker(context).then((time){
              sendNewState({"date": "${formatDate(date, [yyyy, '-', mm, '-', dd])}", "time": "${formatDate(DateTime(1970, 1, 1, time.hour, time.minute), [HH, ':', nn])}"});
            });
          } else {
            sendNewState({"date": "${formatDate(date, [yyyy, '-', mm, '-', dd])}"});
          }
        }
      });
    } else if (hasTime) {
      _showTimePicker(context).then((time){
        if (time != null) {
          sendNewState({"time": "${formatDate(DateTime(1970, 1, 1, time.hour, time.minute), [HH, ':', nn])}"});
        }
      });
    } else {
      TheLogger.log("Warning", "${widget.entity.entityId} has no date and no time");
    }
  }

  Future _showDatePicker(BuildContext context) {
    return showDatePicker(
        context: context,
        initialDate: dateTimeState,
        firstDate: DateTime(1970),
        lastDate: DateTime(2037) //Unix timestamp will finish at Jan 19, 2038
    );
  }

  Future _showTimePicker(BuildContext context) {
    return showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(dateTimeState)
    );
  }
}