import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nowlii/themes/create_qutes.dart';

class TimePickerCard extends StatefulWidget {
  final double scale;

  const TimePickerCard({super.key, this.scale = 1.0});

  @override
  State<TimePickerCard> createState() => _TimePickerCardState();
}

class _TimePickerCardState extends State<TimePickerCard> {
  bool _isExpanded = false;
  int _selectedHour = DateTime.now().hour;
  int _selectedMinute = DateTime.now().minute;
  int _selectedSecond = DateTime.now().second;
  bool _isPM = DateTime.now().hour >= 12;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _selectedSecond++;
        if (_selectedSecond >= 60) {
          _selectedSecond = 0;
          _selectedMinute++;
          if (_selectedMinute >= 60) {
            _selectedMinute = 0;
            _selectedHour++;
            if (_selectedHour >= 24) {
              _selectedHour = 0;
            }
            _isPM = _selectedHour >= 12;
          }
        }
      });
    });
  }

  int get _displayHour {
    if (_selectedHour == 0) return 12;
    if (_selectedHour > 12) return _selectedHour - 12;
    return _selectedHour;
  }

  @override
  Widget build(BuildContext context) {
    return _buildTimeCard(widget.scale);
  }

  Widget _buildTimeCard(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8 * s),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 20 * s,
                  ),
                ),
                SizedBox(width: 8 * s),
                //  AppTextStylesQutes.workSansExtraBold32
                Text(
                  'What time?',
                  style: AppTextStylesQutes.workSansExtraBold32,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[SizedBox(height: 16 * s), _buildTimePicker(s)],
        ],
      ),
    );
  }

  Widget _buildTimePicker(double s) {
    return Column(
      children: [
        _buildTimeRow(
          s,
          (_displayHour - 1) <= 0 ? 12 : _displayHour - 1,
          (_selectedMinute - 1) < 0 ? 59 : _selectedMinute - 1,
          (_selectedSecond - 1) < 0 ? 59 : _selectedSecond - 1,
          !_isPM,
          isGrayed: true,
        ),
        SizedBox(height: 8 * s),
        Container(height: 1, color: Colors.grey[300]),
        SizedBox(height: 8 * s),
        _buildTimeRow(
          s,
          _displayHour,
          _selectedMinute,
          _selectedSecond,
          _isPM,
          isSelected: true,
        ),
        SizedBox(height: 8 * s),
        Container(height: 1, color: Colors.grey[300]),
        SizedBox(height: 8 * s),
        _buildTimeRow(
          s,
          (_displayHour + 1) > 12 ? 1 : _displayHour + 1,
          (_selectedMinute + 1) >= 60 ? 0 : _selectedMinute + 1,
          (_selectedSecond + 1) >= 60 ? 0 : _selectedSecond + 1,
          _isPM,
          isGrayed: true,
        ),
      ],
    );
  }

  Widget _buildTimeRow(
    double s,
    int hour,
    int minute,
    int second,
    bool isPM, {
    bool isSelected = false,
    bool isGrayed = false,
  }) {
    final textColor = isSelected
        ? Colors.blue[700]!
        : isGrayed
        ? Colors.grey[400]!
        : Colors.grey[600]!;

    final fontWeight = isSelected ? FontWeight.bold : FontWeight.normal;
    final fontSize = isSelected ? 20.0 * s : 16.0 * s;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeUnit(
          hour.toString().padLeft(2, '0'),
          textColor,
          fontWeight,
          fontSize,
        ),
        Text(
          ' : ',
          style: TextStyle(
            color: textColor,
            fontWeight: fontWeight,
            fontSize: fontSize,
          ),
        ),
        _buildTimeUnit(
          minute.toString().padLeft(2, '0'),
          textColor,
          fontWeight,
          fontSize,
        ),
        Text(
          ' : ',
          style: TextStyle(
            color: textColor,
            fontWeight: fontWeight,
            fontSize: fontSize,
          ),
        ),
        _buildTimeUnit(
          second.toString().padLeft(2, '0'),
          textColor,
          fontWeight,
          fontSize,
        ),
        SizedBox(width: 16 * s),
        GestureDetector(
          onTap: isSelected
              ? () {
                  setState(() {
                    _isPM = !_isPM;
                    if (_isPM) {
                      _selectedHour = _selectedHour < 12
                          ? _selectedHour + 12
                          : _selectedHour;
                    } else {
                      _selectedHour = _selectedHour >= 12
                          ? _selectedHour - 12
                          : _selectedHour;
                    }
                  });
                }
              : null,
          child: Text(
            isPM ? 'PM' : 'AM',
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeUnit(
    String value,
    Color color,
    FontWeight weight,
    double size,
  ) {
    return Text(
      value,
      style: TextStyle(
        color: color,
        fontWeight: weight,
        fontSize: size,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
