import 'dart:async';
import 'package:flutter/material.dart';

class DownloadProgressDialog extends StatefulWidget {
  final Future<String?> downloadFuture;
  final String fileName;
  final Stream<double> progressStream;

  const DownloadProgressDialog({
    Key? key,
    required this.downloadFuture,
    required this.fileName,
    required this.progressStream,
  }) : super(key: key);

  @override
  _DownloadProgressDialogState createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  bool _isDownloading = true;
  bool _isComplete = false;
  String? _error;
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.progressStream.listen((p) {
      if (mounted) setState(() => _progress = p.clamp(0.0, 1.0));
    }, onError: (e) {
      if (mounted) setState(() => _error = e.toString());
    });

    _startDownload();
  }

  void _startDownload() async {
    try {
      await widget.downloadFuture;

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isComplete = true;
          _progress = 1.0;
        });

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = e.toString();
        });
      }
    } finally {
      await _sub?.cancel();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isComplete ? 'Download Complete!' : 'Downloading...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 10,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress:', style: TextStyle(fontSize: 14)),
                Text('${(_progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('File:', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    widget.fileName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            const Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            const Text('Download Failed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
          if (_isComplete) ...[
            const SizedBox(height: 16),
            const Icon(Icons.check_circle, color: Colors.green, size: 40),
            const SizedBox(height: 16),
            const Text('Download complete!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ready to install', style: TextStyle(fontSize: 14)),
          ],
        ],
      ),
      actions: _isDownloading
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ]
          : _error != null
              ? [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  ),
                ],
    );
  }
}