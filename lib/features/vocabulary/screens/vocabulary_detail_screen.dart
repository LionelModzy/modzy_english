import 'package:flutter/material.dart';
import '../../../models/vocab_model.dart';

class VocabularyDetailScreen extends StatelessWidget {
  final VocabularyModel vocabulary;
  const VocabularyDetailScreen({Key? key, required this.vocabulary}) : super(key: key);

  static void open(BuildContext context, VocabularyModel vocab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VocabularyDetailScreen(vocabulary: vocab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết từ: ${vocabulary.word}'),
        backgroundColor: Colors.teal,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // IMAGE & AUDIO
                    if (vocabulary.imageUrl != null && vocabulary.imageUrl!.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            vocabulary.imageUrl!,
                            width: isWide ? 220 : 160,
                            height: isWide ? 220 : 160,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: isWide ? 220 : 160,
                              height: isWide ? 220 : 160,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    if (vocabulary.audioUrl != null && vocabulary.audioUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volume_up, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                vocabulary.audioUrl!,
                                style: const TextStyle(fontSize: 13, color: Colors.blue),
                                maxLines: 1,
                                minLines: 1,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // MAIN INFO CARD
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(context, Icons.label_important, 'ID', vocabulary.id),
                            _infoRow(context, Icons.text_fields, 'Từ vựng', vocabulary.word, big: true),
                            _infoRow(context, Icons.record_voice_over, 'Phát âm', vocabulary.pronunciation),
                            _infoRow(context, Icons.translate, 'Nghĩa', vocabulary.meaning, big: true),
                            _infoRow(context, Icons.description, 'Định nghĩa', vocabulary.definition ?? ''),
                            _infoRow(context, Icons.category, 'Danh mục', vocabulary.category),
                            _infoRow(context, Icons.label, 'Từ loại', vocabulary.vietnamesePartOfSpeech),
                            _infoRow(context, Icons.star, 'Độ khó', '${vocabulary.difficultyLevel} (${vocabulary.vietnameseDifficultyName})'),
                            _infoRow(context, Icons.check_circle, 'Kích hoạt', vocabulary.isActive ? 'Có' : 'Không'),
                            _infoRow(context, Icons.bar_chart, 'Số lần sử dụng', vocabulary.usageCount.toString()),
                            _infoRow(context, Icons.calendar_today, 'Ngày tạo', _formatDate(vocabulary.createdAt)),
                            _infoRow(context, Icons.update, 'Ngày cập nhật', vocabulary.updatedAt != null ? _formatDate(vocabulary.updatedAt!) : ''),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // EXAMPLES, SYNONYMS, ANTONYMS, LESSONS
                    Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: [
                        _sectionCard(context, Icons.format_quote, 'Ví dụ', vocabulary.examples, isList: true),
                        _sectionCard(context, Icons.link, 'Từ đồng nghĩa', vocabulary.synonyms),
                        _sectionCard(context, Icons.block, 'Từ trái nghĩa', vocabulary.antonyms),
                        _sectionCard(context, Icons.menu_book, 'Thuộc bài học', vocabulary.lessonIds),
                        _sectionCard(context, Icons.info_outline, 'Metadata', [vocabulary.metadata.isNotEmpty ? vocabulary.metadata.toString() : '']),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // IMAGE URL (copyable)
                    if (vocabulary.imageUrl != null && vocabulary.imageUrl!.isNotEmpty)
                      Center(
                        child: SelectableText(
                          vocabulary.imageUrl!,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value, {bool big = false}) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal[700]),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(fontSize: big ? 17 : 15, color: Colors.black87, fontWeight: big ? FontWeight.w600 : FontWeight.normal),
              maxLines: big ? 3 : 2,
              minLines: 1,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, IconData icon, String label, List<dynamic> items, {bool isList = false}) {
    if (items.isEmpty || (items.length == 1 && (items[0] == null || items[0].toString().isEmpty))) return const SizedBox();
    return SizedBox(
      width: 320,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: Colors.teal[600]),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              if (isList)
                ...items.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('- $e', style: const TextStyle(fontSize: 14)),
                    ))
              else
                Text(items.join(', '), style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 