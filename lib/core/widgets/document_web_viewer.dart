import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';

class DocumentWebViewer extends StatelessWidget {
  final String filePath;
  final VoidCallback? onRemove; // Callback to remove attachment

  const DocumentWebViewer({super.key, required this.filePath, this.onRemove});

  String get fileName => filePath.split('/').last;

  bool get isPdf => filePath.toLowerCase().endsWith('.pdf');
  bool get isPublicUrl => filePath.startsWith('http');
  bool get isAsset => filePath.startsWith('assets/');
  bool get isImage => filePath.toLowerCase().endsWith('.jpg') ||
      filePath.toLowerCase().endsWith('.jpeg') ||
      filePath.toLowerCase().endsWith('.png') ||
      filePath.toLowerCase().endsWith('.gif');

  Future<String> _prepareFile(BuildContext context) async {
    if (isAsset) {
      final byteData = await rootBundle.load(filePath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      return tempFile.path;
    } else if (isPublicUrl) {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(filePath));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } else {
      return filePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdfFile = filePath.toLowerCase().endsWith('.pdf');
    final iconColor = Colors.green.shade700;
    final fileType = isPdfFile ? 'PDF' : (isImage ? 'IMG' : 'DOC');
    final bgColor = Colors.white;
    final borderColor = Colors.green.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _openBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 1.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.attach_file, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          fileType,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.green, size: 22),
                  onPressed: () => _openBottomSheet(context),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                    onPressed: onRemove,
                    tooltip: 'Remove attachment',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            margin: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 16, right: 8, bottom: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _prepareFile(context),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final localPath = snapshot.data!;
                      if (isPdf) {
                        return SfPdfViewer.file(File(localPath));
                      } else if (isImage) {
                        return Center(
                          child: Image.file(
                            File(localPath),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 80),
                          ),
                        );
                      } else {
                        return WebViewWidget(
                          controller: WebViewController()
                            ..setJavaScriptMode(JavaScriptMode.unrestricted)
                            ..loadFile(localPath),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
