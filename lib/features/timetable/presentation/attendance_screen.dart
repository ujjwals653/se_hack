import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:se_hack/features/timetable/data/timetable_repository.dart' as se_hack_timetable_repo;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se_hack/features/attendance/domain/attendance_service.dart';
import 'package:se_hack/features/attendance/data/models/attendance_stats.dart';
import 'package:se_hack/features/timetable/presentation/screens/bunk_analytics_wrapper.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    final attService = context.watch<AttendanceService>();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && attService.stats.isEmpty) { // Optional safety
      WidgetsBinding.instance.addPostFrameCallback((_) {
        attService.initialize(user.uid);
      });
    }
    final statsList = attService.stats.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Attendance Dashboard', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.deepOrange),
            tooltip: 'Bunk Analytics',
            onPressed: () {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BunkAnalyticsWrapper(userId: uid),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: statsList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("No synced attendance data found.", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black)),
                  const SizedBox(height: 8),
                  Text("The database has 0 linked subjects.", style: GoogleFonts.inter(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          final repo = se_hack_timetable_repo.TimetableRepository();
                          final tt = await repo.getTimetable(uid);
                          if (tt != null) {
                            int totalEntries = 0;
                            final unique = <String>{};
                            for (final list in tt.days.values) {
                              totalEntries += list.length;
                              for (var e in list) {
                                if (!e.isFree && e.subject.isNotEmpty) {
                                  unique.add(e.subject);
                                }
                              }
                            }
                            
                            if (totalEntries == 0) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timetable is empty! Re-upload it.')));
                              return;
                            }
                            if (unique.isEmpty) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found $totalEntries entries but ALL are free/empty! None to sync.')));
                              return;
                            }
                            
                            await attService.seedSubjectsFromTimetable(tt);
                            await attService.refreshSubjectCounts();
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync successful! Linked ${unique.length} subjects.')));
                          } else {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No timetable found in the database. Please save one first.')));
                          }
                        }
                      } catch (e) {
                         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
                      }
                    },
                    icon: const Icon(Icons.sync, color: Colors.white),
                    label: const Text('Force Sync From Timetable', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B61FF)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: statsList.length,
              itemBuilder: (context, index) {
                final stat = statsList[index];
                return _SubjectCard(attService: attService, stat: stat);
              },
            ),
    );
  }
}

class _SubjectCard extends StatefulWidget {
  final AttendanceService attService;
  final AttendanceStats stat;

  const _SubjectCard({
    Key? key,
    required this.attService,
    required this.stat,
  }) : super(key: key);

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  late double _localSliderValue;

  @override
  void initState() {
    super.initState();
    _localSliderValue = widget.stat.compulsoryPct;
  }

  @override
  void didUpdateWidget(covariant _SubjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stat.compulsoryPct != widget.stat.compulsoryPct) {
      _localSliderValue = widget.stat.compulsoryPct;
    }
  }

  Future<void> _markAndShowError(String status) async {
    final err = await widget.attService.markAttendance(widget.stat.subjectId, status);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Opens a dialog to manually enter a numeric value.
  Future<int?> _showNumberDialog({
    required String title,
    required String hint,
    required int initialValue,
    int? maxValue,
  }) async {
    final controller = TextEditingController(text: initialValue.toString());
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixText: maxValue != null ? 'max $maxValue' : null,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTotalPlanned() async {
    final val = await _showNumberDialog(
      title: 'Total Planned Lectures',
      hint: 'Enter total lectures for the semester',
      initialValue: widget.stat.totalPlanned,
    );
    if (val == null || !mounted) return;
    final err = await widget.attService.setManualValues(
      widget.stat.subjectId,
      totalPlanned: val,
    );
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _editAttended() async {
    final val = await _showNumberDialog(
      title: 'Attended Lectures',
      hint: 'Enter number attended',
      initialValue: widget.stat.attended,
      maxValue: widget.stat.totalPlanned - widget.stat.absent,
    );
    if (val == null || !mounted) return;
    final err = await widget.attService.setManualValues(
      widget.stat.subjectId,
      attended: val,
    );
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _editAbsent() async {
    final val = await _showNumberDialog(
      title: 'Absent Lectures',
      hint: 'Enter number absent',
      initialValue: widget.stat.absent,
      maxValue: widget.stat.totalPlanned - widget.stat.attended,
    );
    if (val == null || !mounted) return;
    final err = await widget.attService.setManualValues(
      widget.stat.subjectId,
      absent: val,
    );
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (widget.stat.riskStatus == 'safe') statusColor = const Color(0xFF43E0A3);
    else if (widget.stat.riskStatus == 'warning') statusColor = const Color(0xFFFFAB61);
    else statusColor = const Color(0xFFFF527A);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.stat.subjectName,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.grey),
                    tooltip: 'Reset Attendance',
                    onPressed: () => widget.attService.resetAttendance(widget.stat.subjectId),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.stat.currentPercentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: widget.stat.conducted > 0 ? widget.stat.currentPercentage / 100 : 0,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTappableStat('Attended', widget.stat.attended.toString(), onTap: _editAttended),
                  _buildTappableStat('Absent', widget.stat.absent.toString(), onTap: _editAbsent),
                  _buildMiniStat('Can Bunk', widget.stat.canBunk.toString(), color: widget.stat.canBunk > 0 ? const Color(0xFF43E0A3) : const Color(0xFFFF527A)),
                  _buildMiniStat('Still Needed', widget.stat.classesStillNeeded.toString()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _markAndShowError('present'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43E0A3).withOpacity(0.15),
                        foregroundColor: const Color(0xFF28B47C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Present', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _markAndShowError('absent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF527A).withOpacity(0.15),
                        foregroundColor: const Color(0xFFD43156),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Absent', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32, color: Color(0xFFEAEAEE)),
                  Text('Compulsory Percentage', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF7B61FF),
                            inactiveTrackColor: const Color(0xFF7B61FF).withOpacity(0.2),
                            thumbColor: const Color(0xFF7B61FF),
                            overlayColor: const Color(0xFF7B61FF).withOpacity(0.1),
                          ),
                          child: Slider(
                            value: _localSliderValue,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '${_localSliderValue.toInt()}%',
                            onChanged: (val) {
                              setState(() => _localSliderValue = val);
                            },
                            onChangeEnd: (val) {
                              widget.attService.setCompulsoryPercentage(widget.stat.subjectId, val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Quick Setup', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [60, 70, 75, 80, 85].map((preset) => ActionChip(
                      label: Text('$preset%', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF7B61FF))),
                      backgroundColor: const Color(0xFF7B61FF).withOpacity(0.1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onPressed: () {
                        setState(() => _localSliderValue = preset.toDouble());
                        widget.attService.setCompulsoryPercentage(widget.stat.subjectId, preset.toDouble());
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Detailed Breakdown', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade500)),
                      Text(
                        'Tap value to edit',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEditableRow(
                    'Total Planned (Semester)',
                    widget.stat.totalPlanned.toString(),
                    onTap: _editTotalPlanned,
                    icon: Icons.edit_outlined,
                  ),
                  _buildDetailRow('Conducted So Far', widget.stat.conducted.toString()),
                  _buildEditableRow(
                    'Attended',
                    widget.stat.attended.toString(),
                    onTap: _editAttended,
                    color: const Color(0xFF28B47C),
                    icon: Icons.edit_outlined,
                  ),
                  _buildEditableRow(
                    'Absent (Bunked)',
                    widget.stat.absent.toString(),
                    onTap: _editAbsent,
                    color: const Color(0xFFD43156),
                    icon: Icons.edit_outlined,
                  ),
                  _buildDetailRow('Remaining Classes', widget.stat.remaining.toString()),
                  _buildDetailRow('Total Bunk Budget', widget.stat.totalBunkBudget.toString()),
                  _buildDetailRow('Can Still Bunk', widget.stat.canBunk.toString(), color: widget.stat.canBunk > 0 ? const Color(0xFF28B47C) : const Color(0xFFD43156), isBold: true),
                  _buildDetailRow('Must Still Attend', widget.stat.classesStillNeeded.toString(), color: const Color(0xFFFFAB61), isBold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String val, {Color? color}) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTappableStat(String label, String val, {required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
              const SizedBox(width: 2),
              Icon(Icons.edit, size: 12, color: Colors.grey.shade400),
            ],
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade800, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: color ?? Colors.black, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildEditableRow(String label, String value, {required VoidCallback onTap, Color? color, bool isBold = false, IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade800, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
            Row(
              children: [
                Text(value, style: TextStyle(color: color ?? Colors.black, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
                const SizedBox(width: 4),
                Icon(icon ?? Icons.edit_outlined, size: 14, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
