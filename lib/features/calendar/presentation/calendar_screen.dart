import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:se_hack/features/calendar/bloc/calendar_bloc.dart';
import 'package:se_hack/features/calendar/domain/calendar_event_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);
  static const Color _surface = Color(0xFFF5F5FA);

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _focusedMonth = DateTime(today.year, today.month);
    _selectedDate = DateTime(today.year, today.month, today.day);
    _focusedMonth = DateTime(today.year, today.month);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    if (date == _selectedDate) return;
    _fadeController.forward(from: 0);
    setState(() {
      _selectedDate = date;
      _focusedMonth = DateTime(date.year, date.month);
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    _selectDate(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekStrip(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        activeBackgroundColor: _primary,
        activeForegroundColor: Colors.white,
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
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            label: 'Add Task',
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
            onTap: () {
              _showAddTaskBottomSheet(context);
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.schedule),
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            label: 'Sync Timetable',
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing Timetable...')),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.group_work),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            label: 'Sync Squad Deadlines',
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
            onTap: () {
              context.read<CalendarBloc>().add(
                CalendarSyncSquadDeadlinesRequested(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing Squad Deadlines to Calendar...'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'My Calendar',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Today shortcut
          GestureDetector(
            onTap: _goToToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Today',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Refresh
          BlocBuilder<CalendarBloc, CalendarState>(
            builder: (context, state) {
              final loading = state is CalendarLoading;
              return GestureDetector(
                onTap: loading
                    ? null
                    : () => context.read<CalendarBloc>().add(
                        CalendarRefreshRequested(),
                      ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Calendar Widget ─────────────────────────────────────────────────────────

  Widget _buildWeekStrip() {
    return Container(
      color: _primary,
      child: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          List<CalendarEventModel> events = [];
          if (state is CalendarLoaded) {
            events = state.events;
          }

          return TableCalendar<CalendarEventModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedMonth,
            currentDay: DateTime.now(),
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDate, selectedDay)) {
                _selectDate(selectedDay);
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedMonth = focusedDay;
              // Remove setState to prevent unnecessary rebuilds if checking month label
              // Month label usually updates within TableCalendar itself, but if we need
              // external sync, we shouldn't _selectDate here unless we want to jump selected date.
              // To sync external _focusedMonth nicely:
              Future.microtask(() => setState(() {}));
            },
            eventLoader: (day) {
              return events.where((e) => e.occursOn(day)).toList();
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              formatButtonTextStyle: GoogleFonts.inter(
                color: _primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              formatButtonDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
              titleTextStyle: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
              ),
              weekendStyle: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: GoogleFonts.inter(color: Colors.white),
              weekendTextStyle: GoogleFonts.inter(color: Colors.white),
              outsideTextStyle: GoogleFonts.inter(color: Colors.white38),
              todayTextStyle: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              selectedTextStyle: GoogleFonts.inter(
                color: _primary,
                fontWeight: FontWeight.bold,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            calendarBuilders: CalendarBuilders(
              singleMarkerBuilder: (context, date, event) {
                return Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent,
                  ),
                  width: 5.0,
                  height: 5.0,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading || state is CalendarInitial) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }

        if (state is CalendarNeedsAuth) {
          return _buildNeedsAuthState();
        }

        if (state is CalendarError) {
          return _buildErrorState(state.message);
        }

        if (state is CalendarLoaded) {
          return _buildAgenda(state.events);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAgenda(List<CalendarEventModel> allEvents) {
    final dayEvents = allEvents
        .where((e) => e.occursOn(_selectedDate))
        .toList();

    return RefreshIndicator(
      color: _accent,
      onRefresh: () async {
        context.read<CalendarBloc>().add(CalendarRefreshRequested());
        // Wait briefly for UX
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: dayEvents.isEmpty
            ? _buildEmptyDay()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: dayEvents.length,
                itemBuilder: (context, i) => _buildEventCard(dayEvents[i]),
              ),
      ),
    );
  }

  Widget _buildEventCard(CalendarEventModel event) {
    final Color eventColor = event.colorHex != null
        ? _hexToColor(event.colorHex!)
        : _accent;

    final timeStr = event.isAllDay
        ? 'All day'
        : event.start != null
        ? '${DateFormat('h:mm a').format(event.start!)} – ${event.end != null ? DateFormat('h:mm a').format(event.end!) : ''}'
        : '';

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        context.read<CalendarBloc>().add(
          CalendarEventDeleteRequested(event.id),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task deleted'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: _accent,
              onPressed: () {
                context.read<CalendarBloc>().add(
                  CalendarEventUndoDeleteRequested(event),
                );
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color strip
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: eventColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          if (event.isAllDay)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: eventColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'All day',
                                style: GoogleFonts.inter(
                                  color: eventColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (timeStr.isNotEmpty && !event.isAllDay) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (event.location != null &&
                          event.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (event.description != null &&
                          event.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDay() {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available_outlined,
                  size: 48,
                  color: _accent.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No events',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('EEEE, MMM d').format(_selectedDate),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeedsAuthState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 48,
                color: _accent.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connect Google Calendar',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Allow Lumina to read your Google Calendar events to display them here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect Calendar'),
              onPressed: () =>
                  context.read<CalendarBloc>().add(CalendarLoadRequested()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  context.read<CalendarBloc>().add(CalendarLoadRequested()),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showAddTaskBottomSheet(BuildContext context) {
    String title = '';
    String description = '';
    String location = '';
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(hours: 1));
    bool isAllDay = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Task',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => title = v,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: start,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) {
                                if (!context.mounted) return;
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(start),
                                );
                                if (t != null)
                                  setState(
                                    () => start = DateTime(
                                      d.year,
                                      d.month,
                                      d.day,
                                      t.hour,
                                      t.minute,
                                    ),
                                  );
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('MMM d, h:mm a').format(start),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: end,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) {
                                if (!context.mounted) return;
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(end),
                                );
                                if (t != null)
                                  setState(
                                    () => end = DateTime(
                                      d.year,
                                      d.month,
                                      d.day,
                                      t.hour,
                                      t.minute,
                                    ),
                                  );
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('MMM d, h:mm a').format(end),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => location = v,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => description = v,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (title.trim().isEmpty) return;
                        final eventModel = CalendarEventModel(
                          id: 'temp_id_${DateTime.now().millisecondsSinceEpoch}',
                          title: title.trim(),
                          start: start,
                          end: end,
                          description: description.isNotEmpty
                              ? description.trim()
                              : null,
                          location: location.isNotEmpty
                              ? location.trim()
                              : null,
                          isAllDay: isAllDay,
                        );
                        this.context.read<CalendarBloc>().add(
                          CalendarEventAddRequested(eventModel),
                        );
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse('FF$cleaned', radix: 16) ?? 0xFF7B61FF;
    return Color(value);
  }
}
