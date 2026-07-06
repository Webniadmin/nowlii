import 'package:flutter/material.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart'
    show AppTextStylesQutes;

class WhenCard extends StatefulWidget {
  final double scale;

  const WhenCard({super.key, this.scale = 1.0});

  @override
  State<WhenCard> createState() => _WhenCardState();
}

class _WhenCardState extends State<WhenCard> {
  String selectedDateOption = '';

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
        setState(() {
          selectedDateOption = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
        decoration: BoxDecoration(
          color: selected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8 * s),
        ),
        child: Text(label, style: AppTextStylesQutes.workSansBlack24),
      ),
    );
  }

  Widget _selectDateButton(double s) {
    return GestureDetector(
      onTap: () {
        _showDateSelectionDialog();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12 * s, horizontal: 16 * s),
        decoration: BoxDecoration(
          color:
              selectedDateOption.isNotEmpty &&
                  selectedDateOption != 'Today' &&
                  selectedDateOption != 'Tomorrow'
              ? Colors.blue[50]
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8 * s),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              selectedDateOption.isNotEmpty &&
                      selectedDateOption != 'Today' &&
                      selectedDateOption != 'Tomorrow'
                  ? selectedDateOption
                  : 'Select a date',
              style: AppTextStylesQutes.workSansBlack24,
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
              setState(() {
                selectedDateOption = '$day Jan, $weekday';
              });
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
  int selectedIndex = 2;

  final dates = [
    {"day": "06", "weekday": "Monday"},
    {"day": "07", "weekday": "Tuesday"},
    {"day": "08", "weekday": "Wednesday"},
    {"day": "09", "weekday": "Thursday"},
    {"day": "10", "weekday": "Friday"},
    {"day": "11", "weekday": "Saturday"},
    {"day": "12", "weekday": "Sunday"},
  ];

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
                        "January 2026",
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
                    widget.onDateSelected(
                      dates[selectedIndex]["day"]!,
                      dates[selectedIndex]["weekday"]!,
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
