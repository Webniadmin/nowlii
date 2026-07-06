import 'package:flutter/material.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart'
    show AppTextStylesQutes;

class WhenCard extends StatefulWidget {
  final double scale;
  final Function(String, DateTime)? onDateSelected;

  const WhenCard({super.key, this.scale = 1.0, this.onDateSelected});

  @override
  State<WhenCard> createState() => _WhenCardState();
}

class _WhenCardState extends State<WhenCard> {
  String selectedDateOption = '';

  void _updateDate(String option, DateTime date) {
    setState(() {
      selectedDateOption = option;
    });
    widget.onDateSelected?.call(option, date);
  }

  @override
  Widget build(BuildContext context) {
    double s = widget.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: Color(0xFFDFEFFF),
        borderRadius: BorderRadius.circular(12 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Image.asset(
                Assets.svgIcons.whenPng.path,
                height: 24 * s,
                width: 24 * s,
              ),
              SizedBox(width: 8 * s),
              Text('WHEN?', style: AppTextStylesQutes.workSansBlack24),
            ],
          ),
          SizedBox(height: 12 * s),
          // Date options
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dateOption('Today', selectedDateOption == 'Today', s),
              SizedBox(height: 10 * s),
              _dateOption('Tomorrow', selectedDateOption == 'Tomorrow', s),
              SizedBox(height: 10 * s),
              _selectDateButton(s),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateOption(String label, bool selected, double s) {
    return GestureDetector(
      onTap: () {
        DateTime date;
        if (label == 'Today') {
          date = DateTime.now();
        } else {
          date = DateTime.now().add(const Duration(days: 1));
        }
        _updateDate(label, date);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFBFDBFE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8 * s),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label, 
          style: AppTextStylesQutes.workSansBlack24.copyWith(
            color: selected ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _selectDateButton(double s) {
    final bool isCustomDateSelected = selectedDateOption.isNotEmpty &&
        selectedDateOption != 'Today' &&
        selectedDateOption != 'Tomorrow';
    
    return GestureDetector(
      onTap: () {
        _showDateSelectionDialog();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 12 * s),
        decoration: BoxDecoration(
          color: isCustomDateSelected ? const Color(0xFFBFDBFE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8 * s),
          border: Border.all(
            color: isCustomDateSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              isCustomDateSelected ? selectedDateOption : 'Select a date',
              style: AppTextStylesQutes.workSansBlack24.copyWith(
                color: isCustomDateSelected ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                fontWeight: isCustomDateSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: DateSelectionScreen(
            onDateSelected: (day, weekday) {
              // Get the actual date from the dialog
              final now = DateTime.now();
              final selectedDay = int.parse(day);
              
              // Find the matching date within next 7 days
              DateTime? matchedDate;
              for (int i = 0; i < 7; i++) {
                final date = now.add(Duration(days: i));
                if (date.day == selectedDay) {
                  matchedDate = date;
                  break;
                }
              }
              
              final date = matchedDate ?? now;
              _updateDate('$day ${_getMonthName(date.month)}, $weekday', date);
              Navigator.of(context).pop();
            },
            onClose: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class DateSelectionScreen extends StatefulWidget {
  final Function(String day, String weekday) onDateSelected;
  final VoidCallback onClose;

  const DateSelectionScreen({
    super.key,
    required this.onDateSelected,
    required this.onClose,
  });

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  int selectedIndex = 0;
  late List<Map<String, dynamic>> dates;
  late String currentMonthYear;

  @override
  void initState() {
    super.initState();
    _generateDates();
  }

  void _generateDates() {
    final now = DateTime.now();
    dates = [];
    
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      dates.add({
        "day": date.day.toString().padLeft(2, '0'),
        "weekday": _getWeekdayName(date.weekday),
        "fullDate": date,
      });
    }
    
    // Get current month and year
    currentMonthYear = _getMonthName(now.month) + ' ${now.year}';
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // double cardWidth = constraints.maxWidth * 0.85;

        return Container(
          width: 335,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFDFEFFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Select a date",
                      style: AppTextStylesQutes.workSansBlack20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Only 7 days ahead – because a week is enough to get moving.",
                style: AppTextStylesQutes.workSansSemiBold18,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        currentMonthYear,
                        style: AppTextStylesQutes.workSansSemiBosld18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        itemCount: dates.length,
                        itemBuilder: (context, i) {
                          bool selected = selectedIndex == i;
                          return InkWell(
                            onTap: () => setState(() => selectedIndex = i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 20,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    dates[i]["day"]!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? const Color(0xFF4B39EF)
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      dates[i]["weekday"]!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected
                                            ? const Color(0xFF4B39EF)
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check,
                                      color: Color(0xFF4B39EF),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final selectedDate = dates[selectedIndex];
                    widget.onDateSelected(
                      selectedDate["day"]!,
                      selectedDate["weekday"]!,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A22),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    "Choose date",
                    style: AppTextStylesQutes.workSansBlack20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
