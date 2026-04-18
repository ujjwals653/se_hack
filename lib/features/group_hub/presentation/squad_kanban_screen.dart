import 'package:flutter/material.dart';
import '../data/squad_repository.dart';
import '../models/kanban_task_model.dart';

class SquadKanbanScreen extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;

  const SquadKanbanScreen({
    super.key,
    required this.squadId,
    required this.uid,
    required this.repo,
  });

  @override
  State<SquadKanbanScreen> createState() => _SquadKanbanScreenState();
}

class _SquadKanbanScreenState extends State<SquadKanbanScreen> {
  static const Color _primary = Color(0xFF4C4D7B);

  bool _myTasksOnly = false;

  final _columns = KanbanColumn.values;

  final _columnMeta = {
    KanbanColumn.backlog: _ColumnMeta('📦 Backlog', Color(0xFF78909C)),
    KanbanColumn.todo: _ColumnMeta('📋 To Do', Color(0xFF5C6BC0)),
    KanbanColumn.doing: _ColumnMeta('🔥 In Progress', Color(0xFFEF6C00)),
    KanbanColumn.review: _ColumnMeta('🔍 In Review', Color(0xFF8E24AA)),
    KanbanColumn.done: _ColumnMeta('✅ Done', Color(0xFF2E7D32)),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Team Kanban Board',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              // My tasks toggle
              GestureDetector(
                onTap: () => setState(() => _myTasksOnly = !_myTasksOnly),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _myTasksOnly
                        ? _primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _myTasksOnly ? '👤 My Tasks' : '👥 All Tasks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _myTasksOnly
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Add task
              GestureDetector(
                onTap: () => _showAddTaskSheet(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Kanban board — horizontal scrollable columns
        Expanded(
          child: StreamBuilder<List<KanbanTask>>(
            stream: widget.repo.watchKanban(widget.squadId),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF7B61FF)));
              }
              var allTasks = snap.data!;
              if (_myTasksOnly) {
                allTasks = allTasks
                    .where((t) => t.assignees.contains(widget.uid))
                    .toList();
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: _columns.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, colIdx) {
                  final col = _columns[colIdx];
                  final meta = _columnMeta[col]!;
                  final tasks =
                      allTasks.where((t) => t.column == col).toList();

                  return _KanbanColumn(
                    meta: meta,
                    tasks: tasks,
                    col: col,
                    uid: widget.uid,
                    onMove: (task, newCol) async {
                      await widget.repo
                          .moveKanbanTask(widget.squadId, task.id, newCol);
                      // Award trophies on sprint complete
                      if (newCol == KanbanColumn.done) {
                        final done = allTasks
                            .where(
                                (t) => t.column == KanbanColumn.done)
                            .length;
                        if (done + 1 >= 5) {
                          await widget.repo.awardTrophies(
                              widget.squadId, 15, 'Sprint Cleared! 🎉');
                        }
                      }
                    },
                    onDelete: (task) async {
                      await widget.repo.deleteKanbanTask(
                          widget.squadId, task.id);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddTaskSheet(
        squadId: widget.squadId,
        uid: widget.uid,
        repo: widget.repo,
      ),
    );
  }
}

class _ColumnMeta {
  final String label;
  final Color color;
  const _ColumnMeta(this.label, this.color);
}

// ─── Kanban Column ───────────────────────────────────────────────────────────
class _KanbanColumn extends StatelessWidget {
  final _ColumnMeta meta;
  final List<KanbanTask> tasks;
  final KanbanColumn col;
  final String uid;
  final Future<void> Function(KanbanTask, KanbanColumn) onMove;
  final Future<void> Function(KanbanTask) onDelete;

  const _KanbanColumn({
    required this.meta,
    required this.tasks,
    required this.col,
    required this.uid,
    required this.onMove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: meta.color.withOpacity(0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    meta.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: meta.color,
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: meta.color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${tasks.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Task cards
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No tasks',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _KanbanCard(
                      task: tasks[i],
                      uid: uid,
                      onMove: onMove,
                      onDelete: onDelete,
                      colColor: meta.color,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Kanban Card ─────────────────────────────────────────────────────────────
class _KanbanCard extends StatelessWidget {
  final KanbanTask task;
  final String uid;
  final Future<void> Function(KanbanTask, KanbanColumn) onMove;
  final Future<void> Function(KanbanTask) onDelete;
  final Color colColor;

  const _KanbanCard({
    required this.task,
    required this.uid,
    required this.onMove,
    required this.onDelete,
    required this.colColor,
  });

  static const _priorityColors = {
    TaskPriority.high: Color(0xFFE53935),
    TaskPriority.medium: Color(0xFFEF6C00),
    TaskPriority.low: Color(0xFF2E7D32),
  };

  static const _priorityLabels = {
    TaskPriority.high: 'HIGH',
    TaskPriority.medium: 'MED',
    TaskPriority.low: 'LOW',
  };

  @override
  Widget build(BuildContext context) {
    final isAssigned = task.assignees.contains(uid);
    return GestureDetector(
      onTap: () => _showCardActions(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isAssigned
              ? Border.all(
                  color: const Color(0xFF4C4D7B).withOpacity(0.4),
                  width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _priorityColors[task.priority]!
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _priorityLabels[task.priority]!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _priorityColors[task.priority],
                    ),
                  ),
                ),
                if (isAssigned) ...[
                  const Spacer(),
                  const Text('👤',
                      style: TextStyle(fontSize: 10)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (task.dueDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(
                    'Due ${_formatDate(task.dueDate!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: task.dueDate!.isBefore(DateTime.now())
                          ? Colors.red
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCardActions(BuildContext context) {
    final allCols = KanbanColumn.values;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Move to column:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            ...allCols.where((c) => c != task.column).map((c) {
              final meta = {
                KanbanColumn.backlog: '📦 Backlog',
                KanbanColumn.todo: '📋 To Do',
                KanbanColumn.doing: '🔥 In Progress',
                KanbanColumn.review: '🔍 In Review',
                KanbanColumn.done: '✅ Done',
              };
              return ListTile(
                title: Text(meta[c] ?? c.name),
                onTap: () {
                  Navigator.pop(context);
                  onMove(task, c);
                },
              );
            }),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Delete Task',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                onDelete(task);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ─── Add Task Sheet ──────────────────────────────────────────────────────────
class _AddTaskSheet extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  const _AddTaskSheet(
      {required this.squadId,
      required this.uid,
      required this.repo});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  static const Color _primary = Color(0xFF4C4D7B);
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  KanbanColumn _col = KanbanColumn.todo;
  TaskPriority _priority = TaskPriority.medium;
  bool _assignedToMe = true;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final task = KanbanTask(
      id: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      column: _col,
      assignees: _assignedToMe ? [widget.uid] : [],
      priority: _priority,
      createdBy: widget.uid,
      createdAt: DateTime.now(),
    );
    await widget.repo.addKanbanTask(widget.squadId, task);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Task',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleCtrl,
                decoration: _dec('Task title *'),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descCtrl,
                decoration: _dec('Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),

              // Priority & Column row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      initialValue: _priority,
                      decoration: _dec('Priority'),
                      items: TaskPriority.values
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _priority = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<KanbanColumn>(
                      initialValue: _col,
                      decoration: _dec('Column'),
                      items: KanbanColumn.values
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _col = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              CheckboxListTile(
                value: _assignedToMe,
                onChanged: (v) =>
                    setState(() => _assignedToMe = v!),
                title: const Text('Assign to me',
                    style: TextStyle(fontSize: 13)),
                activeColor: _primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Add Task',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF4C4D7B), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      );
}
