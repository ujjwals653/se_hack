import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/features/timetable/data/models/timetable.dart';
import 'package:se_hack/features/timetable/data/models/timetable_entry.dart';
import 'package:se_hack/features/timetable/presentation/timetable_bloc.dart';
import 'package:se_hack/features/timetable/presentation/widgets/day_tab_bar.dart';
import 'package:se_hack/features/timetable/presentation/widgets/edit_entry_sheet.dart';
import 'package:se_hack/features/timetable/presentation/widgets/timeline_slot.dart';

class MyClassesScreen extends StatefulWidget {
  final Timetable timetable;
  final String userId;

  const MyClassesScreen({
    super.key,
    required this.timetable,
    required this.userId,
  });

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  late String _selectedDay;

  // Pastel color palette for different subjects
  static const List<Color> _subjectColors = [
    Color(0xFFFFB74D), // Orange
    Color(0xFF81C784), // Green
    Color(0xFF64B5F6), // Blue
    Color(0xFFE57373), // Red
    Color(0xFFBA68C8), // Purple
    Color(0xFF4DD0E1), // Teal
    Color(0xFFFFD54F), // Yellow
    Color(0xFFA1887F), // Brown
    Color(0xFFFF8A65), // Deep Orange
    Color(0xFF9575CD), // Deep Purple
    Color(0xFF4DB6AC), // Teal accent
    Color(0xFFF06292), // Pink
  ];

  final Map<String, Color> _subjectColorMap = {};

  @override
  void initState() {
    super.initState();
    // Select today's day or default to Mon
    final now = DateTime.now();
    final dayIndex = now.weekday - 1; // Monday = 0
    if (dayIndex >= 0 && dayIndex < Timetable.dayKeys.length) {
      _selectedDay = Timetable.dayKeys[dayIndex];
    } else {
      _selectedDay = 'Mon';
    }
    _buildColorMap(widget.timetable);
  }

  void _buildColorMap(Timetable timetable) {
    _subjectColorMap.clear();
    int colorIdx = 0;
    for (final entries in timetable.days.values) {
      for (final entry in entries) {
        if (!entry.isFree && !_subjectColorMap.containsKey(entry.subject)) {
          _subjectColorMap[entry.subject] = _subjectColors[colorIdx % _subjectColors.length];
          colorIdx++;
        }
      }
    }
  }

  Color _getColorForEntry(TimetableEntry entry) {
    if (entry.isFree) return Colors.blue.shade200;
    return _subjectColorMap[entry.subject] ?? _subjectColors[0];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimetableBloc, TimetableState>(
      builder: (context, state) {
        // Use latest timetable from state if available
        final timetable = (state is TimetableLoaded) ? state.timetable : widget.timetable;
        _buildColorMap(timetable);
        final entries = timetable.days[_selectedDay] ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFF4C4D7B),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // App Bar
                _buildAppBar(context),
                // Body with rounded top
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        DayTabBar(
                          selectedDay: _selectedDay,
                          onDaySelected: (day) {
                            setState(() => _selectedDay = day);
                          },
                        ),
                        const SizedBox(height: 8),
                        // Timeline list
                        Expanded(
                          child: entries.isEmpty
                              ? _buildEmptyDayState()
                              : ListView.builder(
                                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                                  itemCount: entries.length,
                                  itemBuilder: (context, index) {
                                    final entry = entries[index];
                                    return TimelineSlot(
                                      entry: entry,
                                      color: _getColorForEntry(entry),
                                      onTap: () => _showEditSheet(
                                        context,
                                        entry: entry,
                                        index: index,
                                      ),
                                      onLongPress: () => _confirmDelete(
                                        context,
                                        entry,
                                        index,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showEditSheet(context),
            backgroundColor: const Color(0xFF4C4D7B),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'My Classes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Discard / Re-upload button
          GestureDetector(
            onTap: () => _showDiscardDialog(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No classes on $_selectedDay',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a period',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, {TimetableEntry? entry, int? index}) {
    final bloc = context.read<TimetableBloc>();
    final currentState = bloc.state;
    final timetable = (currentState is TimetableLoaded) ? currentState.timetable : widget.timetable;
    final entries = timetable.days[_selectedDay] ?? [];
    final periodNum = entry?.period ?? (entries.length + 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditEntrySheet(
        entry: entry,
        periodNumber: periodNum,
        onSave: (updatedEntry) {
          if (index != null) {
            bloc.add(TimetableEntryUpdated(
              userId: widget.userId,
              day: _selectedDay,
              index: index,
              entry: updatedEntry,
            ));
          } else {
            bloc.add(TimetableEntryAdded(
              userId: widget.userId,
              day: _selectedDay,
              entry: updatedEntry,
            ));
          }
        },
        onDelete: index != null
            ? () {
                bloc.add(TimetableEntryDeleted(
                  userId: widget.userId,
                  day: _selectedDay,
                  index: index,
                ));
              }
            : null,
      ),
    );
  }

  void _confirmDelete(BuildContext context, TimetableEntry entry, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Period'),
        content: Text('Remove "${entry.subject}" from $_selectedDay?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TimetableBloc>().add(TimetableEntryDeleted(
                    userId: widget.userId,
                    day: _selectedDay,
                    index: index,
                  ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard Timetable'),
        content: const Text(
          'This will delete your current timetable. You can upload a new one after.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TimetableBloc>().add(
                    TimetableDiscardRequested(widget.userId),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
