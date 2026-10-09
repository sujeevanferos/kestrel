import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../canvas/canvas_controller.dart';
import '../../notebook/models/notebook_models.dart';
import '../../notebook/notebook_service.dart';

class NotebookManagerDialog extends StatefulWidget {
  final CanvasController canvasController;

  const NotebookManagerDialog({super.key, required this.canvasController});

  @override
  State<NotebookManagerDialog> createState() => _NotebookManagerDialogState();
}

class _NotebookManagerDialogState extends State<NotebookManagerDialog> {
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    final svc = NotebookService.instance;
    _selectedSubjectId = svc.activeSubjectId ?? (svc.subjects.isNotEmpty ? svc.subjects.first.id : null);
  }

  void _showNewSubjectDialog() {
    final titleCtrl = TextEditingController();
    int selectedColor = 0xFF1E3A8A;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFFBF8F2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create Subject', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Thermodynamics & Statistical Physics',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final c in [0xFF1E3A8A, 0xFF2D6A4F, 0xFFB91C1C, 0xFFD97706, 0xFF7C3AED])
                    GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == c ? const Color(0xFF1B1C1E) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = titleCtrl.text.trim();
                if (name.isNotEmpty) {
                  await NotebookService.instance.addSubject(name, selectedColor);
                  setState(() {
                    _selectedSubjectId = NotebookService.instance.activeSubjectId;
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B1C1E), foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewBoardDialog() {
    if (_selectedSubjectId == null) return;
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFBF8F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Whiteboard Page', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Lecture 4: Conservation Laws',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty) {
                await NotebookService.instance.addPageToSubject(_selectedSubjectId!, title);
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B1C1E), foregroundColor: Colors.white),
            child: const Text('Add Page'),
          ),
        ],
      ),
    );
  }

  void _switchToPage(Subject subject, NotebookPage page) async {
    final svc = NotebookService.instance;

    // 1. Save current active page before switching
    if (svc.activeSubjectId != null && svc.activePageId != null) {
      await svc.savePageContent(svc.activeSubjectId!, svc.activePageId!, widget.canvasController.exportBoardJson());
    }

    // 2. Set new active page
    svc.setActivePage(subject.id, page.id);

    // 3. Load items into canvas
    widget.canvasController.importBoardJson(page.itemsJson);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to "${page.title}" in ${subject.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = NotebookService.instance;
    final subjects = svc.subjects;
    final selectedSubject = subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => subjects.isNotEmpty ? subjects.first : Subject(id: '', name: '', colorValue: 0),
    );

    return Dialog(
      backgroundColor: const Color(0xFFFBF8F2), // Warm Ivory
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2DCD0), width: 1.0),
      ),
      child: Container(
        width: 820,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(LucideIcons.bookOpen, size: 22, color: Color(0xFF1B1C1E)),
                const SizedBox(width: 12),
                const Text(
                  'Subjects & Notebooks Manager',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1C1E),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2DCD0), height: 24),

            // Content Split View
            Expanded(
              child: Row(
                children: [
                  // Left: Subjects List
                  Container(
                    width: 260,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Color(0xFFE2DCD0))),
                    ),
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'SUBJECTS',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(LucideIcons.plus, size: 16, color: Color(0xFF1B1C1E)),
                              tooltip: 'Add Subject',
                              onPressed: _showNewSubjectDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: subjects.length,
                            itemBuilder: (context, idx) {
                              final subj = subjects[idx];
                              final isSelected = subj.id == _selectedSubjectId;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFF0EAE1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(subj.colorValue),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  title: Text(
                                    subj.name,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: const Color(0xFF1B1C1E),
                                    ),
                                  ),
                                  trailing: Text(
                                    '${subj.pages.length}',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9CA3AF)),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedSubjectId = subj.id;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: Pages / Boards in Selected Subject
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedSubject.name.isNotEmpty ? selectedSubject.name : 'No Subject Selected',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B1C1E),
                                    ),
                                  ),
                                  Text(
                                    '${selectedSubject.pages.length} whiteboard boards in this curriculum',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: selectedSubject.id.isNotEmpty ? _showNewBoardDialog : null,
                                icon: const Icon(LucideIcons.filePlus, size: 14),
                                label: const Text('New Board', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B1C1E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: selectedSubject.pages.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No whiteboard boards in this subject yet.',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9CA3AF)),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.8,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: selectedSubject.pages.length,
                                    itemBuilder: (context, idx) {
                                      final page = selectedSubject.pages[idx];
                                      final isActive = svc.activePageId == page.id;
                                      return InkWell(
                                        onTap: () => _switchToPage(selectedSubject, page),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isActive ? const Color(0xFF1B1C1E) : const Color(0xFFE2DCD0),
                                              width: isActive ? 2 : 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(LucideIcons.layoutGrid, size: 14, color: Color(selectedSubject.colorValue)),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      page.title,
                                                      style: const TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF1B1C1E),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isActive)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFD1FAE5),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text('Active', style: TextStyle(fontSize: 10, color: Color(0xFF065F46))),
                                                    ),
                                                ],
                                              ),
                                              const Spacer(),
                                              Text(
                                                'Items: ${page.itemsJson.length}',
                                                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF6B7280)),
                                              ),
                                              Text(
                                                'Modified: ${page.updatedAt.month}/${page.updatedAt.day} ${page.updatedAt.hour.toString().padLeft(2, '0')}:${page.updatedAt.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: Color(0xFF9CA3AF)),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
