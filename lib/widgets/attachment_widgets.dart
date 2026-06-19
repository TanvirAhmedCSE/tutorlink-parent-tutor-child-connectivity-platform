import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as pathLib;
import '../../utils/theme.dart';
import '../../models/models.dart';
import '../../services/cloudinary_service.dart';

//  Pending local attachment (before upload)
class PendingAttachment {
  final File file;
  final String type; // 'image', 'file'
  bool uploading;
  String? uploadedUrl;
  String? error;

  PendingAttachment({
    required this.file,
    required this.type,
    this.uploading = false,
    this.uploadedUrl,
    this.error,
  });

  String get filename => pathLib.basename(file.path);
  bool get isImage => type == 'image';
  bool get isUploaded => uploadedUrl != null;
}

// AttachmentPickerSection
// Used in: CreateAssignmentSheet, SubmitSheet, ChatInputBar
class AttachmentPickerSection extends StatefulWidget {
  final List<PendingAttachment> attachments;
  final void Function(PendingAttachment) onAdded;
  final void Function(int) onRemoved;

  const AttachmentPickerSection({
    super.key,
    required this.attachments,
    required this.onAdded,
    required this.onRemoved,
  });

  @override
  State<AttachmentPickerSection> createState() =>
      _AttachmentPickerSectionState();
}

class _AttachmentPickerSectionState extends State<AttachmentPickerSection> {
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    widget.onAdded(PendingAttachment(file: File(picked.path), type: 'image'));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'zip'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.first.path!);
    widget.onAdded(PendingAttachment(file: file, type: 'file'));
  }

  List<PendingAttachment> get _images =>
      widget.attachments.where((a) => a.isImage).toList();
  List<PendingAttachment> get _files =>
      widget.attachments.where((a) => !a.isImage).toList();

  @override
  Widget build(BuildContext context) {
    final allImages = _images;
    final allFiles = _files;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //  Image section
        if (allImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final att = allImages[i];
                final globalIdx = widget.attachments.indexOf(att);
                return _LocalImageThumb(
                  file: att.file,
                  uploading: att.uploading,
                  error: att.error,
                  onRemove: () => widget.onRemoved(globalIdx),
                );
              },
            ),
          ),
        ],
        //  File section
        if (allFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...allFiles.map((att) {
            final globalIdx = widget.attachments.indexOf(att);
            return _LocalFileTile(
              att: att,
              onRemove: () => widget.onRemoved(globalIdx),
            );
          }),
        ],
        const SizedBox(height: 10),
        //  Picker buttons
        Row(
          children: [
            _PickerButton(
              icon: Icons.image_outlined,
              label: allImages.isEmpty ? 'Add Image' : 'Add Another Image',
              color: AppColors.primary,
              onTap: _pickImage,
            ),
            const SizedBox(width: 10),
            _PickerButton(
              icon: Icons.attach_file_rounded,
              label: allFiles.isEmpty ? 'Add File' : 'Add Another File',
              color: AppColors.secondary,
              onTap: _pickFile,
            ),
          ],
        ),
        const SizedBox(height: 9),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalImageThumb extends StatelessWidget {
  final File file;
  final bool uploading;
  final String? error;
  final VoidCallback onRemove;

  const _LocalImageThumb({
    required this.file,
    required this.uploading,
    required this.error,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            color: uploading ? Colors.black26 : null,
            colorBlendMode: BlendMode.darken,
          ),
        ),
        if (uploading)
          const Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        if (error != null)
          const Positioned.fill(
            child: Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 24),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocalFileTile extends StatelessWidget {
  final PendingAttachment att;
  final VoidCallback onRemove;

  const _LocalFileTile({required this.att, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _fileIcon(att.filename),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.filename,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (att.uploading)
                  const Text(
                    'Uploading…',
                    style: TextStyle(fontSize: 11, color: AppColors.textHint),
                  )
                else if (att.error != null)
                  Text(
                    'Upload failed',
                    style: TextStyle(fontSize: 11, color: AppColors.error),
                  )
                else if (att.isUploaded)
                  const Text(
                    'Uploaded ✓',
                    style: TextStyle(fontSize: 11, color: AppColors.success),
                  ),
              ],
            ),
          ),
          if (att.uploading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    );
  }
}

Widget _fileIcon(String filename) {
  final ext = pathLib.extension(filename).toLowerCase().replaceAll('.', '');
  IconData icon;
  Color color;
  switch (ext) {
    case 'pdf':
      icon = Icons.picture_as_pdf_rounded;
      color = Colors.red;
      break;
    case 'docx':
      icon = Icons.description_rounded;
      color = Colors.blue;
      break;
    case 'txt':
      icon = Icons.text_snippet_rounded;
      color = Colors.grey;
      break;
    case 'zip':
      icon = Icons.folder_zip_rounded;
      color = Colors.orange;
      break;
    default:
      icon = Icons.insert_drive_file_rounded;
      color = AppColors.textSecondary;
  }
  return Icon(icon, color: color, size: 28);
}

// AttachmentViewSection  — shows uploaded attachments (readonly display)
// Used in: AssignmentDetailScreen, MessageBubble
class AttachmentViewSection extends StatelessWidget {
  final List<AssignmentAttachment> attachments;

  const AttachmentViewSection({super.key, required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments.where((a) => a.isImage).toList();
    final files = attachments.where((a) => !a.isImage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ImageGrid(images: images),
        ],
        if (files.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...files.map((f) => _DownloadFileTile(attachment: f)),
        ],
      ],
    );
  }
}

// Same but for ChatAttachment
class ChatAttachmentViewSection extends StatelessWidget {
  final List<ChatAttachment> attachments;

  const ChatAttachmentViewSection({super.key, required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments.where((a) => a.isImage).toList();
    final files = attachments.where((a) => !a.isImage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) _ChatImageGrid(images: images),
        if (files.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...files.map((f) => _ChatDownloadFileTile(attachment: f)),
        ],
      ],
    );
  }
}

//  Image grid
class _ImageGrid extends StatelessWidget {
  final List<AssignmentAttachment> images;
  const _ImageGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return _NetworkImageThumb(
        url: images[0].url,
        width: double.infinity,
        height: 180,
        onTap: () => _openFullscreen(context, images, 0),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.asMap().entries.map((e) {
        return _NetworkImageThumb(
          url: e.value.url,
          width: 110,
          height: 110,
          onTap: () => _openFullscreen(context, images, e.key),
        );
      }).toList(),
    );
  }

  void _openFullscreen(
    BuildContext context,
    List<AssignmentAttachment> imgs,
    int idx,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          urls: imgs.map((i) => i.url).toList(),
          initialIndex: idx,
        ),
      ),
    );
  }
}

class _ChatImageGrid extends StatelessWidget {
  final List<ChatAttachment> images;
  const _ChatImageGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _NetworkImageThumb(
          url: images[0].url,
          width: 220,
          height: 160,
          onTap: () => _open(context, 0),
          borderRadius: 12,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: images.asMap().entries.map((e) {
          return _NetworkImageThumb(
            url: e.value.url,
            width: 106,
            height: 106,
            onTap: () => _open(context, e.key),
            borderRadius: 10,
          );
        }).toList(),
      ),
    );
  }

  void _open(BuildContext context, int idx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          urls: images.map((i) => i.url).toList(),
          initialIndex: idx,
        ),
      ),
    );
  }
}

class _NetworkImageThumb extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final VoidCallback onTap;
  final double borderRadius;

  const _NetworkImageThumb({
    required this.url,
    required this.width,
    required this.height,
    required this.onTap,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: AppColors.divider,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.divider,
            child: const Icon(
              Icons.broken_image_rounded,
              color: AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}

//  Download file tile
class _DownloadFileTile extends StatefulWidget {
  final AssignmentAttachment attachment;
  const _DownloadFileTile({required this.attachment});

  @override
  State<_DownloadFileTile> createState() => _DownloadFileTileState();
}

class _DownloadFileTileState extends State<_DownloadFileTile> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${widget.attachment.filename}';
      final response = await http.get(Uri.parse(widget.attachment.url));
      await File(filePath).writeAsBytes(response.bodyBytes);
      await OpenFilex.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download failed')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _fileIcon(widget.attachment.filename),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.attachment.filename,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _downloading ? null : _download,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _downloading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.download_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatDownloadFileTile extends StatefulWidget {
  final ChatAttachment attachment;
  const _ChatDownloadFileTile({required this.attachment});

  @override
  State<_ChatDownloadFileTile> createState() => _ChatDownloadFileTileState();
}

class _ChatDownloadFileTileState extends State<_ChatDownloadFileTile> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${widget.attachment.filename}';
      final response = await http.get(Uri.parse(widget.attachment.url));
      await File(filePath).writeAsBytes(response.bodyBytes);
      await OpenFilex.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download failed')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fileIcon(widget.attachment.filename),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.attachment.filename,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _downloading ? null : _download,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _downloading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.download_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// FullScreenImageViewer
class FullScreenImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: widget.urls.length > 1
            ? Text(
                '${_current + 1} / ${widget.urls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : null,
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.urls[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Upload helper — upload all pending attachments, update their state via callback
Future<List<T>> uploadPendingAttachments<T>({
  required List<PendingAttachment> pending,
  required CloudinaryFolder folder,
  required void Function() onProgress,
  required T Function(String url, String filename, String type) builder,
}) async {
  final results = <T>[];
  for (int i = 0; i < pending.length; i++) {
    final att = pending[i];
    att.uploading = true;
    att.error = null;
    onProgress();
    try {
      final result = await CloudinaryService.uploadFile(att.file, folder);
      att.uploadedUrl = result.url;
      att.uploading = false;
      results.add(builder(result.url, att.filename, att.type));
    } catch (e) {
      att.uploading = false;
      att.error = e.toString();
      onProgress();
      rethrow;
    }
    onProgress();
  }
  return results;
}

Future<File?> pickImageFile() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return File(picked.path);
}

Future<File?> pickDocFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'docx', 'txt', 'zip'],
  );
  if (result == null || result.files.isEmpty) return null;
  return File(result.files.first.path!);
}
