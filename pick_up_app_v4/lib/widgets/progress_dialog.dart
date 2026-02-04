import 'package:flutter/material.dart';

class DownloadProgressDialog extends StatefulWidget {
  final Future<String?> downloadFuture;
  final String fileName;

  const DownloadProgressDialog({
    Key? key,
    required this.downloadFuture,
    required this.fileName,
  }) : super(key: key);

  @override
  _DownloadProgressDialogState createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  bool _isDownloading = true;
  bool _isComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() async {
    try {
      // Wait for the download to complete
      await widget.downloadFuture;

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isComplete = true;
        });

        // Wait a moment to show completion
        await Future.delayed(Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pop(true); // Return success
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _updateProgress(double progress) {
    if (mounted) {
      setState(() {
        _progress = progress;
      });
    }
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 10,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'File:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  widget.fileName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            SizedBox(height: 16),
            Icon(
              Icons.error,
              color: Colors.red,
              size: 40,
            ),
            SizedBox(height: 16),
            Text(
              'Download Failed',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (_isComplete) ...[
            SizedBox(height: 16),
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
            SizedBox(height: 16),
            Text(
              'Download complete!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ready to install',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
      actions: _isDownloading
          ? [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false); // Return cancelled
          },
          child: Text('Cancel'),
        ),
      ]
          : _error != null
          ? [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Close'),
        ),
      ]
          : [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Close'),
        ),
      ],
    );
  }
}