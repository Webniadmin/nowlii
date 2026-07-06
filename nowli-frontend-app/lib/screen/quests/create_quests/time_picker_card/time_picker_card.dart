import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nowlii/themes/create_qutes.dart';

class TimePickerCard extends StatefulWidget {
  final double scale;
  final String? initialTime;
  final Function(String)? onTimeSelected; // Add callback

  const TimePickerCard({
    super.key, 
    this.scale = 1.0,
    this.initialTime,
    this.onTimeSelected, // Add callback
  });

  @override
  State<TimePickerCard> createState() => _TimePickerCardState();
}

class _TimePickerCardState extends State<TimePickerCard> {
  bool _isExpanded = false;
  int _selectedHour = DateTime.now().hour;
  int _selectedMinute = DateTime.now().minute;
  bool _isPM = DateTime.now().hour >= 12;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Parse initial time if provided (format: "10:00")
    if (widget.initialTime != null) {
      try {
        final parts = widget.initialTime!.split(':');
        if (parts.length == 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          _selectedHour = hour;
          _selectedMinute = minute;
          _isPM = hour >= 12;
        }
      } catch (e) {
        // If parsing fails, use current time
        debugPrint('Failed to parse initial time: $e');
      }
    }
    
    // Notify initial time after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyTimeChange();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _notifyTimeChange() {
    // Format time as HH:MM (24-hour format)
    final timeString = '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
    widget.onTimeSelected?.call(timeString);
  }
  
  void _incrementHour() {
    setState(() {
      _selectedHour++;
      if (_selectedHour >= 24) {
        _selectedHour = 0;
      }
      _isPM = _selectedHour >= 12;
    });
    _notifyTimeChange();
  }
  
  void _decrementHour() {
    setState(() {
      _selectedHour--;
      if (_selectedHour < 0) {
        _selectedHour = 23;
      }
      _isPM = _selectedHour >= 12;
    });
    _notifyTimeChange();
  }
  
  void _incrementMinute() {
    setState(() {
      _selectedMinute++;
      if (_selectedMinute >= 60) {
        _selectedMinute = 0;
      }
    });
    _notifyTimeChange();
  }
  
  void _decrementMinute() {
    setState(() {
      _selectedMinute--;
      if (_selectedMinute < 0) {
        _selectedMinute = 59;
      }
    });
    _notifyTimeChange();
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
                Expanded(
                  child: Text(
                    'What time?',
                    style: AppTextStylesQutes.workSansExtraBold32,
                  ),
                ),
                Container(
                  width: 32 * s,
                  height: 32 * s,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(8 * s),
                  ),
                  child: Icon(
                    _isExpanded ? Icons.remove : Icons.add,
                    color: Colors.white,
                    size: 20 * s,
                  ),
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
    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12 * s),
      ),
      child: Column(
        children: [
          // Hour and Minute selectors
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour selector
              _buildTimeSelector(
                value: _displayHour,
                onIncrement: _incrementHour,
                onDecrement: _decrementHour,
                label: 'Hour',
                s: s,
              ),
              SizedBox(width: 16 * s),
              Text(
                ':',
                style: TextStyle(
                  fontSize: 32 * s,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(width: 16 * s),
              // Minute selector
              _buildTimeSelector(
                value: _selectedMinute,
                onIncrement: _incrementMinute,
                onDecrement: _decrementMinute,
                label: 'Minute',
                s: s,
              ),
              SizedBox(width: 16 * s),
              // AM/PM toggle
              _buildAmPmToggle(s),
            ],
          ),
          SizedBox(height: 12 * s),
          // Selected time display
          Text(
            'Selected: ${_displayHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} ${_isPM ? 'PM' : 'AM'}',
            style: TextStyle(
              fontSize: 14 * s,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeSelector({
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required String label,
    required double s,
  }) {
    return Column(
      children: [
        // Increment button
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 48 * s,
            height: 36 * s,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white,
              size: 24 * s,
            ),
          ),
        ),
        SizedBox(height: 8 * s),
        // Value display
        Container(
          width: 60 * s,
          height: 50 * s,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8 * s),
            border: Border.all(
              color: const Color(0xFF3B82F6),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 24 * s,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * s),
        // Decrement button
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 48 * s,
            height: 36 * s,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 24 * s,
            ),
          ),
        ),
        SizedBox(height: 4 * s),
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 12 * s,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAmPmToggle(double s) {
    return Column(
      children: [
        SizedBox(height: 36 * s), // Align with increment button
        SizedBox(height: 8 * s),
        GestureDetector(
          onTap: () {
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
            _notifyTimeChange();
          },
          child: Container(
            width: 60 * s,
            height: 50 * s,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Center(
              child: Text(
                _isPM ? 'PM' : 'AM',
                style: TextStyle(
                  fontSize: 18 * s,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * s),
        SizedBox(height: 36 * s), // Align with decrement button
        SizedBox(height: 4 * s),
        Text(
          'Period',
          style: TextStyle(
            fontSize: 12 * s,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }


}
