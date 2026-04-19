import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:se_hack/features/calendar/bloc/calendar_bloc.dart';
import 'package:se_hack/features/calendar/domain/calendar_event_model.dart';
import 'package:go_router/go_router.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;

  // Predefined beautiful pastel gradients for our timeline cards
  final List<List<Color>> _pastelGradients = [
    [const Color(0xFFFFB155), const Color(0xFFFF9D2A)], // Peach/Orange
    [const Color(0xFF62D3E7), const Color(0xFF38BDF8)], // Cyan/Blue
    [const Color(0xFFFF6288), const Color(0xFFFF416C)], // Pink/Red
    [const Color(0xFF8B78FF), const Color(0xFF624BFF)], // Purple
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
  }

  void _selectDate(DateTime date) {
    if (date == _selectedDate) return;
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildHorizontalDateSelector(),
            const SizedBox(height: 24),
            _buildOngoingHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildTimelineBody()),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFF7B61FF),
        foregroundColor: Colors.white,
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add_task),
            backgroundColor: const Color(0xFF38BDF8),
            foregroundColor: Colors.white,
            label: 'Add Task',
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
            onTap: () {},
          ),
          SpeedDialChild(
            child: const Icon(Icons.schedule),
            backgroundColor: const Color(0xFFFF9D2A),
            foregroundColor: Colors.white,
            label: 'Sync Timetable',
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              // Usually pop, but if in tab, maybe disabled or fallback. For now we use the arrow layout
            },
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_rounded, size: 16, color: Colors.black87),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM').format(_selectedDate.subtract(const Duration(days: 30))),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMMM').format(_selectedDate),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          Row(
            children: [
              Text(
                DateFormat('MMM').format(_selectedDate.add(const Duration(days: 30))),
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black87),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDateSelector() {
    // Generate dates around the selected date
    final List<DateTime> dates = [];
    final startDate = _selectedDate.subtract(const Duration(days: 3));
    for (int i = 0; i < 30; i++) {
        dates.add(startDate.add(Duration(days: i)));
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () => _selectDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7B61FF) : Colors.white,
                borderRadius: BorderRadius.circular(35), // Pill shape
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('E').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOngoingHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Ongoing',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineBody() {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading || state is CalendarInitial) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF)));
        }
        if (state is CalendarNeedsAuth) {
          return _buildNeedsAuthState();
        }
        if (state is CalendarLoaded) {
          return _buildTimelineAgenda(state.events);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildNeedsAuthState() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B61FF)),
        onPressed: () => context.read<CalendarBloc>().add(CalendarLoadRequested()),
        child: const Text('Connect Calendar', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTimelineAgenda(List<CalendarEventModel> allEvents) {
    final dayEvents = allEvents.where((e) => e.occursOn(_selectedDate)).toList();
    // Sort events by start time
    dayEvents.sort((a, b) => (a.start ?? DateTime.now()).compareTo(b.start ?? DateTime.now()));

    if (dayEvents.isEmpty) {
      return Center(
        child: Text(
          'No scheduled events.',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade400),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        final List<Color> gradient = _pastelGradients[index % _pastelGradients.length];

        final timeStr = event.start != null ? DateFormat('h a').format(event.start!) : 'All day';
        final durationStr = event.start != null && event.end != null
            ? '${DateFormat('h:mm a').format(event.start!)} - ${DateFormat('h:mm a').format(event.end!)}'
            : '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timescale Column
              SizedBox(
                width: 50,
                child: Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              
              // Custom Timeline tracking line and dot
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: gradient[0], shape: BoxShape.circle),
                  ),
                  Container(
                    width: 2,
                    height: 90, // Defines the spacing height between segments
                    color: gradient[0].withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Glassmorphic Gradient Event Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[1].withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (event.location != null && event.location!.isNotEmpty) ...[
                         const SizedBox(height: 4),
                         Text(
                           event.location!,
                           style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                         ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (event.description != null && event.description!.isNotEmpty) 
                             const Icon(Icons.people_alt_rounded, size: 14, color: Colors.white),
                          const Spacer(),
                          Text(
                            durationStr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
