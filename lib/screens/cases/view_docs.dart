import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ViewDocs extends StatefulWidget {
  final String caseId;

  const ViewDocs({super.key, required this.caseId});

  @override
  State<ViewDocs> createState() => _ViewDocsState();
}

class _ViewDocsState extends State<ViewDocs> {
  final List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _documents.clear(); // Clear documents to avoid duplicates
    });

    try {
      final caseDocumentsUrl = Uri.parse(
          'https://pragmanxt.com/case_sync/services/intern/v1/index.php/case_history_documents');
      final caseDocumentsResponse = await http.post(
        caseDocumentsUrl,
        body: {'case_id': widget.caseId},
      );

      if (caseDocumentsResponse.statusCode == 200) {
        final caseDocumentsData = jsonDecode(caseDocumentsResponse.body);
        if (caseDocumentsData['success'] == true &&
            caseDocumentsData['data'].isNotEmpty) {
          final documents = caseDocumentsData['data'] as List<dynamic>;
          setState(() {
            _documents.addAll(documents.cast<Map<String, dynamic>>());
          });
        } else {
          setState(() {
            _errorMessage = 'No documents available.';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch documents. Status code: ${caseDocumentsResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(String url, String filePath) async {
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    final file = File(filePath);
    final totalBytes = response.contentLength;
    var bytesDownloaded = 0;

    final sink = file.openWrite();
    await for (var chunk in response) {
      bytesDownloaded += chunk.length;
      sink.add(chunk);
      setState(() {
        _downloadProgress = bytesDownloaded / totalBytes!;
      });
    }
    await sink.close();
  }

  Future<void> _showOptions(String url) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open With'),
              onTap: () async {
                try {
                  final tempDir = await getTemporaryDirectory();
                  final filePath = '${tempDir.path}/${url.split('/').last}';
                  await _downloadFile(url, filePath);
                  Navigator.pop(context);

                  // Use Share to prompt app chooser
                  await Share.shareXFiles(
                    [XFile(filePath)],
                    text: 'Open this document with your preferred app',
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to open document.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save Document'),
              onTap: () async {
                try {
                  final tempDir = await getTemporaryDirectory();
                  final filePath = '${tempDir.path}/${url.split('/').last}';
                  await _downloadFile(url, filePath);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Document saved successfully.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save document.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () async {
                try {
                  final tempDir = await getTemporaryDirectory();
                  final filePath = '${tempDir.path}/${url.split('/').last}';
                  await _downloadFile(url, filePath);
                  Navigator.pop(context);
                  await Share.shareXFiles(
                    [XFile(filePath)],
                    text: 'Here is the document!',
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to share document.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _getFileExtension(String url) {
    return url.split('.').last.toLowerCase();
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.article;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildFileThumbnail(String url, String extension) {
    if (extension == 'pdf') {
      return Container(
        color: Colors.grey[200],
        height: 150,
        child: const Center(
          child: Icon(
            Icons.picture_as_pdf,
            size: 80,
            color: Colors.red,
          ),
        ),
      );
    } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return Image.network(
        url,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            height: 150,
            child: const Center(
              child: Icon(
                Icons.image,
                size: 50,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey[200],
        height: 150,
        child: Center(
          child: Icon(
            _getFileIcon(extension),
            size: 80,
            color: Colors.blue,
          ),
        ),
      );
    }
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final docUrl = doc['docs'];
    final fileName = docUrl.split('/').last;
    final extension = docUrl.split('.').last.toLowerCase();

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: SizedBox(
          height: 50, // Set a fixed height for the leading widget
          width: 50, // Set a fixed width for the leading widget
          child: _buildFileThumbnail(docUrl, extension),
        ),
        title:
            Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
            Text('Added By: ${doc['handled_by']}\nDate: ${doc['date_time']}'),
        onTap: () => _showOptions(docUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'View Documents',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDocuments,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.black))
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchDocuments,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _documents.length,
              itemBuilder: (context, index) =>
                  _buildDocumentCard(_documents[index]),
            ),
          if (_downloadProgress > 0 && _downloadProgress < 1)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Downloading...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _downloadProgress),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
