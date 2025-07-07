import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RichTextEditor extends StatefulWidget {
  final String? initialText;
  final Function(String) onChanged;
  final String label;
  final String hint;
  final int minLines;
  final int maxLines;

  const RichTextEditor({
    super.key,
    this.initialText,
    required this.onChanged,
    required this.label,
    required this.hint,
    this.minLines = 5,
    this.maxLines = 15,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late TextEditingController _controller;
  bool _isBold = false;
  bool _isItalic = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertText(String text) {
    final currentSelection = _controller.selection;
    if (currentSelection.isValid) {
      final currentText = _controller.text;
      final beforeSelection = currentText.substring(0, currentSelection.start);
      final afterSelection = currentText.substring(currentSelection.end);
      
      _controller.text = beforeSelection + text + afterSelection;
      _controller.selection = TextSelection.collapsed(
        offset: currentSelection.start + text.length,
      );
    } else {
      _controller.text += text;
    }
  }

  void _wrapSelectedText(String startTag, String endTag) {
    final currentSelection = _controller.selection;
    if (currentSelection.isValid && !currentSelection.isCollapsed) {
      final currentText = _controller.text;
      final selectedText = currentText.substring(
        currentSelection.start,
        currentSelection.end,
      );
      final beforeSelection = currentText.substring(0, currentSelection.start);
      final afterSelection = currentText.substring(currentSelection.end);
      
      final newText = beforeSelection + startTag + selectedText + endTag + afterSelection;
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: currentSelection.end + startTag.length + endTag.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Formatting Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _buildToolbarButton(
                icon: Icons.format_bold,
                isActive: _isBold,
                onPressed: () {
                  setState(() => _isBold = !_isBold);
                  _wrapSelectedText('**', '**');
                },
                tooltip: 'Bold',
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: Icons.format_italic,
                isActive: _isItalic,
                onPressed: () {
                  setState(() => _isItalic = !_isItalic);
                  _wrapSelectedText('*', '*');
                },
                tooltip: 'Italic',
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: Icons.format_list_bulleted,
                onPressed: () => _insertText('\n• '),
                tooltip: 'Bullet List',
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: Icons.format_list_numbered,
                onPressed: () => _insertText('\n1. '),
                tooltip: 'Numbered List',
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: Icons.format_quote,
                onPressed: () => _insertText('\n> '),
                tooltip: 'Quote',
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: Icons.link,
                onPressed: () => _wrapSelectedText('[', '](url)'),
                tooltip: 'Link',
              ),
              const Spacer(),
              Text(
                '${_controller.text.length} characters',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Text Editor
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _controller,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              hintStyle: const TextStyle(color: AppColors.textSecondary),
            ),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Help Text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use **bold**, *italic*, • for bullets, and [text](url) for links',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
} 