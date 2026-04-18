import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:se_hack/features/attendance/domain/attendance_service.dart';
import 'package:se_hack/features/attendance/data/models/attendance_stats.dart';
import 'package:se_hack/features/timetable/presentation/screens/bunk_analytics_wrapper.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  /// Returns true only for real lecture subjects that should appear in attendance.
  /// Filters out: Compulsory Lab, Free Period, old semicolon-joined names (bad OCR).
  static bool _isValidLecture(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.toLowerCase() == 'compulsory lab') return false;
    if (trimmed.toLowerCase() == 'free period') return false;
    if (trimmed.contains(';')) return false; // old combined-subject format
    if (trimmed.contains('/')) return false; // raw OCR batch codes like "OS/B/AGN"
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final attService = context.watch<AttendanceService>();
    final allStats = attService.stats.values.toList();

    // Only show valid lecture subjects
    final statsList = allStats.where((s) => _isValidLecture(s.subjectName)).toList();

    // Check if there is stale combined-name data needing a re-upload
    final hasStaleData = allStats.any((s) => !_isValidLecture(s.subjectName));

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
      body: Column(
        children: [
          if (hasStaleData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Old timetable data detected. Re-upload your timetable to fix subject names.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: statsList.isEmpty
                ? const Center(child: Text("No attendance data found. Please set up your Timetable."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: statsList.length,
                    itemBuilder: (context, index) {
                      final stat = statsList[index];
                      return _SubjectCard(attService: attService, stat: stat);
                    },
                  ),
          ),
        ],
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
    if (widget.stat.riskStatus == 'safe') statusColor = Colors.green;
    else if (widget.stat.riskStatus == 'warning') statusColor = Colors.orange;
    else statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.stat.subjectName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: Colors.grey),
                    tooltip: 'Reset Attendance',
                    onPressed: () => widget.attService.resetAttendance(widget.stat.subjectId),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.stat.currentPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: widget.stat.conducted > 0 ? widget.stat.currentPercentage / 100 : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTappableStat('Attended', widget.stat.attended.toString(), onTap: _editAttended),
                  _buildTappableStat('Absent', widget.stat.absent.toString(), onTap: _editAbsent),
                  _buildMiniStat('Can Bunk', widget.stat.canBunk.toString(), color: widget.stat.canBunk > 0 ? Colors.green : Colors.red),
                  _buildMiniStat('Still Needed', widget.stat.classesStillNeeded.toString()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _markAndShowError('present'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade700,
                        elevation: 0,
                      ),
                      child: const Text('Present'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _markAndShowError('absent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                      ),
                      child: const Text('Absent'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Required Percentage Target', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('${_localSliderValue.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Expanded(
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
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [60, 70, 75, 80, 85, 90].map((preset) => ActionChip(
                      label: Text('$preset%'),
                      onPressed: () {
                        setState(() => _localSliderValue = preset.toDouble());
                        widget.attService.setCompulsoryPercentage(widget.stat.subjectId, preset.toDouble());
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Detailed Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a value to edit manually',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
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
                    color: Colors.green,
                    icon: Icons.edit_outlined,
                  ),
                  _buildEditableRow(
                    'Absent (Bunked)',
                    widget.stat.absent.toString(),
                    onTap: _editAbsent,
                    color: Colors.red,
                    icon: Icons.edit_outlined,
                  ),
                  _buildDetailRow('Remaining Classes', widget.stat.remaining.toString()),
                  _buildDetailRow('Total Bunk Budget', widget.stat.totalBunkBudget.toString()),
                  _buildDetailRow('Can Still Bunk', widget.stat.canBunk.toString(), color: widget.stat.canBunk > 0 ? Colors.green : Colors.red, isBold: true),
                  _buildDetailRow('Must Still Attend', widget.stat.classesStillNeeded.toString(), color: Colors.deepOrange, isBold: true),
                  const SizedBox(height: 16),
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
