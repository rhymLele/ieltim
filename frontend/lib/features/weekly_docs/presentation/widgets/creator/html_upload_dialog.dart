// html_upload_dialog.dart — Popup "Tải lên file HTML" (file 9 mục 3).
// Kéo thả hoặc "Chọn file từ máy" → kiểm tra ngay → trả HtmlFile khi bấm "Dùng file này", null khi Huỷ.

import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/rules/html_file.dart';

Future<HtmlFile?> showHtmlUploadDialog(BuildContext context) => showDialog<HtmlFile>(context: context, builder: (_) => const HtmlUploadDialog());

class HtmlUploadDialog extends StatefulWidget {
  const HtmlUploadDialog({super.key});

  @override
  State<HtmlUploadDialog> createState() => _HtmlUploadDialogState();
}

class _HtmlUploadDialogState extends State<HtmlUploadDialog> {
  bool _dragging = false;
  bool _reading = false;
  HtmlFile? _file;
  String? _error;

  void _fail(String message) => setState(() {
        _error = message;
        _file = null;
        _reading = false;
      });

  Future<void> _pick() async {
    if (_reading) return;
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['html', 'htm']);
    if (f == null || !mounted) return;
    await _read(f.name, f.length, f.readAsBytes);
  }

  void _onDrop(DropDoneDetails d) {
    setState(() => _dragging = false);
    if (_reading || d.files.isEmpty) return;
    if (d.files.length > 1) return _fail(HtmlFileErrors.multiple);
    final f = d.files.single;
    if (f is DropItemDirectory) return _fail(HtmlFileErrors.extension);
    _read(f.name, f.length, f.readAsBytes);
  }

  Future<void> _read(String name, Future<int?> Function() length, Future<Uint8List> Function() readBytes) async {
    // Sai đuôi / quá 5 MB thì báo ngay, không đọc nội dung.
    int? size;
    try {
      size = await length();
    } catch (_) {}
    final metaError = htmlFileMetaError(name, size);
    if (metaError != null) return _fail(metaError);
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      final file = parseHtmlFile(name, await readBytes());
      if (!mounted) return;
      setState(() {
        _file = file;
        _reading = false;
      });
    } on HtmlFileException catch (e) {
      if (mounted) _fail(e.message);
    } catch (_) {
      if (mounted) _fail('Không đọc được file. Hãy thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      surfaceTintColor: AppColors.transparent,
      insetPadding: const EdgeInsets.all(AppSpace.lg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tải lên file HTML', style: AppText.heading),
              const SizedBox(height: 6),
              const Text('File .html đã có sẵn CSS và JS, tự lo trình chiếu. App chỉ hiển thị nguyên file.', style: AppText.caption),
              const SizedBox(height: AppSpace.lg),
              DropTarget(
                onDragEntered: (_) => setState(() => _dragging = true),
                onDragExited: (_) => setState(() => _dragging = false),
                onDragDone: _onDrop,
                child: Material(
                  color: _dragging ? AppColors.primary.withAlpha(18) : AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    side: BorderSide(color: _dragging ? AppColors.primary : AppColors.borderStrong, width: _dragging ? 2 : 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _reading ? null : _pick,
                    hoverColor: AppColors.hover,
                    child: SizedBox(
                      height: 220,
                      child: Padding(padding: const EdgeInsets.all(AppSpace.lg), child: Center(child: _DropZoneContent(isDragging: _dragging, isReading: _reading, file: file, onPick: _pick))),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!, style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ],
              const SizedBox(height: AppSpace.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
                  const SizedBox(width: AppSpace.sm),
                  FilledButton(key: const Key('weekly_docs_html_upload_use_button'), onPressed: file == null || _reading ? null : () => Navigator.pop(context, file), child: const Text('Dùng file này')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nội dung vùng thả theo trạng thái: đang kéo vào · đang đọc · đã chọn · trống.
class _DropZoneContent extends StatelessWidget {
  const _DropZoneContent({required this.isDragging, required this.isReading, required this.file, required this.onPick});

  final bool isDragging;
  final bool isReading;
  final HtmlFile? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final file = this.file;
    if (isDragging) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.file_download_outlined, size: 40, color: AppColors.primary),
          SizedBox(height: AppSpace.sm),
          Text('Thả file vào đây', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ],
      );
    }
    if (isReading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
          SizedBox(height: AppSpace.md),
          Text('Đang đọc file…', style: AppText.caption),
        ],
      );
    }
    if (file != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 40, color: AppColors.success),
          const SizedBox(height: AppSpace.sm),
          Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppText.label.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(formatFileSize(file.sizeBytes), style: AppText.caption),
          if (file.title != null) ...[
            const SizedBox(height: 2),
            Text('Tiêu đề: ${file.title}', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppText.caption.copyWith(color: AppColors.textInk)),
          ],
          const SizedBox(height: AppSpace.md),
          const Text('Bấm hoặc kéo file khác vào để đổi', style: AppText.caption),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.upload_file_rounded, size: 40, color: AppColors.textMuted),
        const SizedBox(height: AppSpace.sm),
        const Text('Kéo thả file .html vào đây', style: AppText.label),
        const SizedBox(height: 4),
        const Text('hoặc', style: AppText.caption),
        const SizedBox(height: 6),
        OutlinedButton(key: const Key('weekly_docs_html_upload_pick_button'), onPressed: onPick, child: const Text('Chọn file từ máy')),
        const SizedBox(height: 6),
        const Text('Tối đa 5 MB', style: AppText.caption),
      ],
    );
  }
}
