part of '../main.dart';

class DateTimeEntity extends Entity {
  bool get hasDate => _attributes["has_date"] ?? false;
  bool get hasTime => _attributes["has_time"] ?? false;
  int get year => _attributes["year"] ?? 1970;
  int get month => _attributes["month"] ?? 1;
  int get day => _attributes["day"] ?? 1;
  int get hour => _attributes["hour"] ?? 0;
  int get minute => _attributes["minute"] ?? 0;
  int get second => _attributes["second"] ?? 0;
  String get formattedState => _getFormattedState();
  DateTime get dateTimeState => _getDateTimeState();

  DateTimeEntity(Map rawData) : super(rawData);

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
    eventBus.fire(new ServiceCallEvent(_domain, "set_datetime", _entityId,
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
      TheLogger.log("Warning", "$entityId has no date and no time");
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