import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:JoDija_tamplites/JoDija_tamplites.dart';

/// Medical image gallery widget for managing pre-op, intra-op, post-op, and radiology scans.
/// Built using JoDija_tamplites tools with direct Camera capture and Gallery selection.
class MedicalImageGalleryWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<String> initialImages;
  final ValueChanged<List<String>> onImagesChanged;
  final String emptyPlaceholderMessage;

  const MedicalImageGalleryWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.initialImages,
    required this.onImagesChanged,
    this.emptyPlaceholderMessage =
        'No images attached yet. Capture from Camera or choose from Gallery.',
  });

  @override
  State<MedicalImageGalleryWidget> createState() =>
      _MedicalImageGalleryWidgetState();
}

class _MedicalImageGalleryWidgetState extends State<MedicalImageGalleryWidget> {
  late List<String> _images;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _images = List<String>.from(widget.initialImages);
  }

  @override
  void didUpdateWidget(covariant MedicalImageGalleryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImages != widget.initialImages) {
      _images = List<String>.from(widget.initialImages);
    }
  }

  void _addImage(String path) {
    if (path.trim().isEmpty) return;
    setState(() {
      _images.add(path.trim());
    });
    widget.onImagesChanged(_images);
  }

  void _addImages(List<String> paths) {
    final validPaths = paths.where((p) => p.trim().isNotEmpty).toList();
    if (validPaths.isEmpty) return;
    setState(() {
      _images.addAll(validPaths);
    });
    widget.onImagesChanged(_images);
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _images.length) return;
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesChanged(_images);
  }

  /// Capture a new photo with the camera
  Future<void> _pickFromCamera() async {
    setState(() => _isLoading = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (photo != null) {
        _addImage(photo.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Photo captured and attached successfully'),
                ],
              ),
              backgroundColor: Colors.teal,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open camera: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Pick one or multiple photos from the gallery
  Future<void> _pickFromGallery() async {
    setState(() => _isLoading = true);
    try {
      final List<XFile> photos = await _picker.pickMultiImage(
        imageQuality: 88,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (photos.isNotEmpty) {
        _addImages(photos.map((p) => p.path).toList());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Attached ${photos.length} image(s) from gallery'),
                ],
              ),
              backgroundColor: Colors.teal,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open gallery: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Simple source picker bottom sheet (Camera or Gallery only)
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, color: Colors.teal, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Attach Image - ${widget.title}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.teal),
                  ),
                  title: const Text(
                    'Camera',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Take a new photo using device camera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromCamera();
                  },
                ),
                const Divider(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                  ),
                  title: const Text(
                    'Gallery',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Choose one or multiple photos from gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Fullscreen zoomable interactive image viewer
  void _viewFullImage(String path, int index) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black.withValues(alpha: 0.95),
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Zoomable image viewer
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: _renderImageWidget(path, fit: BoxFit.contain),
                ),
              ),

              // Top action bar
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${index + 1} / ${_images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Delete Image',
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                        ),
                        onPressed: () {
                          _removeImage(index);
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Close',
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom path caption
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      path,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Renders local files, network URLs, or assets
  Widget _renderImageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              color: Colors.teal,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(path),
      );
    }

    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(path),
        );
      }
    }

    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(path),
    );
  }

  Widget _buildPlaceholder(String path) {
    final fileName = path.split('/').last.split(r'\').last;
    return Container(
      color: Colors.teal.shade900.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, color: Colors.teal, size: 28),
            const SizedBox(height: 4),
            Text(
              fileName,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsive header using Wrap (Zero overflow)
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Title and count badge
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 20,
                  color: Colors.teal,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: widget.subtitle != null && widget.subtitle!.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _images.isNotEmpty
                        ? Colors.teal.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_images.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _images.isNotEmpty ? Colors.teal : Colors.grey,
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                  ),
                ],
              ],
            ),

            // Strictly 2 buttons: Camera and Gallery
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Camera Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _pickFromCamera,
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: const Text('Camera'),
                ),

                // Gallery Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Empty state or thumbnail list
        if (_images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.teal.shade400,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.emptyPlaceholderMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _pickFromCamera,
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Take Photo'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library_rounded, size: 16),
                      label: const Text('Choose from Gallery'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, index) {
                // Last item is an "Add Image" card
                if (index == _images.length) {
                  return InkWell(
                    onTap: _isLoading ? null : _showImageSourceOptions,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 90,
                      height: 116,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: Colors.teal.shade600, size: 26),
                          const SizedBox(height: 6),
                          const Text(
                            'Add Image',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final item = _images[index];
                return Stack(
                  children: [
                    InkWell(
                      onTap: () => _viewFullImage(item, index),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 110,
                        height: 116,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.teal.withValues(alpha: 0.4),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _renderImageWidget(item),
                      ),
                    ),

                    // Delete button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),

                    // Zoom icon badge
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
