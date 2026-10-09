import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../notebook/models/document_model.dart';
import '../../services/document_service.dart';

class DocumentsLibraryDialog extends StatefulWidget {
  final String? initialDocumentId;

  const DocumentsLibraryDialog({super.key, this.initialDocumentId});

  @override
  State<DocumentsLibraryDialog> createState() => _DocumentsLibraryDialogState();
}

class _DocumentsLibraryDialogState extends State<DocumentsLibraryDialog> {
  String? _selectedDocId;
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    final docs = DocumentService.instance.documents;
    _selectedDocId = widget.initialDocumentId ?? (docs.isNotEmpty ? docs.first.id : null);
  }

  @override
  Widget build(BuildContext context) {
    final docService = DocumentService.instance;
    final docs = docService.documents.where((d) {
      if (_searchFilter.isEmpty) return true;
      return d.title.toLowerCase().contains(_searchFilter) ||
          d.summary.toLowerCase().contains(_searchFilter);
    }).toList();

    final selectedDoc = docService.documents.firstWhere(
      (d) => d.id == _selectedDocId,
      orElse: () => docs.isNotEmpty ? docs.first : AcademicDocument(id: '', title: '', pdfPath: '', createdAt: DateTime.now()),
    );

    return Dialog(
      backgroundColor: const Color(0xFFFBF8F2), // Warm Ivory
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2DCD0), width: 1.0),
      ),
      child: Container(
        width: 880,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.fileText, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documents Library',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1C1E),
                      ),
                    ),
                    Text(
                      'Publication-grade LaTeX documents compiled from whiteboard notes',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const Spacer(),
                // Search box
                SizedBox(
                  width: 220,
                  height: 36,
                  child: TextField(
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search documents...',
                      prefixIcon: const Icon(LucideIcons.search, size: 14, color: Color(0xFF9CA3AF)),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchFilter = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
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
                  // Left List
                  Container(
                    width: 300,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Color(0xFFE2DCD0))),
                    ),
                    padding: const EdgeInsets.only(right: 14),
                    child: docs.isEmpty
                        ? const Center(
                            child: Text(
                              'No documents found.',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF9CA3AF)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, idx) {
                              final doc = docs[idx];
                              final isSelected = doc.id == _selectedDocId;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFF0EAE1) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1B1C1E) : const Color(0xFFE5E7EB),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  title: Text(
                                    doc.title,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: const Color(0xFF1B1C1E),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${doc.pageCount} pages',
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF6B7280)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${doc.createdAt.month}/${doc.createdAt.day}',
                                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: Color(0xFF9CA3AF)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedDocId = doc.id;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),

                  // Right Document Preview Sheet
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: selectedDoc.id.isEmpty
                          ? const Center(
                              child: Text('Select a document to preview.', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF9CA3AF))),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedDoc.title,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B1C1E),
                                            ),
                                          ),
                                          Text(
                                            selectedDoc.summary,
                                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF6B7280)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Action buttons
                                    IconButton(
                                      icon: const Icon(LucideIcons.copy, size: 16, color: Color(0xFF4B5563)),
                                      tooltip: 'Copy LaTeX Source',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: selectedDoc.latexSource));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('LaTeX source code copied to clipboard')),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFDC2626)),
                                      tooltip: 'Delete Document',
                                      onPressed: () async {
                                        await docService.deleteDocument(selectedDoc.id);
                                        setState(() {
                                          _selectedDocId = docService.documents.isNotEmpty ? docService.documents.first.id : null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Simulated Academic Paper Page
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2DCD0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Text(
                                              selectedDoc.title,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B1C1E),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Center(
                                            child: Text(
                                              'Kestrel STEM Academic Engine',
                                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF6B7280)),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF9FAFB),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFE5E7EB)),
                                            ),
                                            child: Text(
                                              selectedDoc.summary,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                height: 1.4,
                                                color: Color(0xFF374151),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'LaTeX Source Representation',
                                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E242B),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: SelectableText(
                                              selectedDoc.latexSource.isNotEmpty
                                                  ? selectedDoc.latexSource
                                                  : r'% Compiling document...' ,
                                              style: const TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                fontSize: 11,
                                                height: 1.4,
                                                color: Color(0xFFE2E8F0),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
