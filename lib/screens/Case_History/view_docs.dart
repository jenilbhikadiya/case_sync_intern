import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intern_side/components/list_app_bar.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../components/basicUIcomponent.dart';
import '../../utils/constants.dart';
import '../../utils/file_already_exists.dart';

class ViewDocs extends StatefulWidget {
  final String caseNo;
  final String caseId;

  const ViewDocs({super.key, required this.caseId, required this.caseNo});

  @override
  State<ViewDocs> createState() => ViewDocsState();
}

class ViewDocsState extends State<ViewDocs> {
  final List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    _documents.clear();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/case_history_documents'),
        body: {'case_id': widget.caseId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'].isNotEmpty) {
          if (!mounted) return;
          setState(() {
            // Parse the fetched data
            final fetchedDocuments =
                List<Map<String, dynamic>>.from(data['data']);

            // Remove duplicates by ensuring unique `file_id`
            final existingFileIds =
                _documents.map((doc) => doc['file_id']).toSet();
            final filteredDocuments = fetchedDocuments.where((doc) {
              return !existingFileIds.contains(doc['file_id']);
            }).toList();

            // Add only unique documents
            _documents.addAll(filteredDocuments);
            // print("Filtered unique documents: $_documents");
          });
        } else {
          if (!mounted) return;
          setState(() => _errorMessage = 'No documents available.');
        }
      } else {
        if (!mounted) return;
        setState(() => _errorMessage =
            'Failed to fetch documents. Status code: ${response.statusCode}');
        // print('Request body: ${{'case_id': widget.caseId}}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'An error occurred: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ListAppBar(title: 'case: ${widget.caseNo}'),
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
                      onPressed: _fetchDocuments, child: const Text('Retry')),
                ],
              ),
            )
          else
            RefreshIndicator(
              color: AppTheme.getRefreshIndicatorColor(
                  Theme.of(context).brightness),
              backgroundColor: AppTheme.getRefreshIndicatorBackgroundColor(),
              onRefresh: () async {
                setState(() {
                  _fetchDocuments();
                });
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _documents.length,
                itemBuilder: (context, index) =>
                    DocumentCard(doc: _documents[index], caseNo: widget.caseNo),
              ),
            )
        ],
      ),
    );
  }
}

class DocumentCard extends StatefulWidget {
  final Map<String, dynamic> doc;
  final String caseNo;

  const DocumentCard({super.key, required this.doc, required this.caseNo});

  @override
  DocumentCardState createState() => DocumentCardState();
}

class DocumentCardState extends State<DocumentCard> {
  double _progress = 0.0;

  Future<String?> _downloadFile(
      String url, String directoryPath, String fileName, bool isSharing,
      [bool isPersistent = false]) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final directory = Directory(directoryPath);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (file.existsSync()) {
        if (isPersistent) {
          final result = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => FileAlreadyExistsDialog(
              title: 'File Already Exists',
              message:
                  'The file "$fileName" already exists. Do you want to open it or download again?',
              cancelButtonText: 'Open',
              confirmButtonText: 'Rewrite',
              onConfirm: () async {
                Navigator.of(context).pop(true);
              },
            ),
          );

          if (result == true) {
            // User chose to rewrite (download again)
            final response = await HttpClient()
                .getUrl(Uri.parse(url))
                .then((req) => req.close());
            final totalBytes = response.contentLength;
            int bytesDownloaded = 0;

            final sink = file.openWrite();
            await for (var chunk in response) {
              bytesDownloaded += chunk.length;
              sink.add(chunk);
              setState(() {
                _progress = bytesDownloaded / totalBytes;
              });
            }
            await sink.close();
          } else {
            // User chose to open the existing file
            if (!isSharing) {
              await OpenFile.open(filePath);
            }
            return filePath;
          }
        } else {
          if (!isSharing) {
            await OpenFile.open(filePath);
          }
          return filePath;
        }
      } else {
        // File does not exist, proceed with download
        final response = await HttpClient()
            .getUrl(Uri.parse(url))
            .then((req) => req.close());
        final totalBytes = response.contentLength;
        int bytesDownloaded = 0;

        final sink = file.openWrite();
        await for (var chunk in response) {
          bytesDownloaded += chunk.length;
          sink.add(chunk);
          setState(() {
            _progress = bytesDownloaded / totalBytes;
          });
        }
        await sink.close();
      }

      setState(() {
        _progress = 1.0;
      });

      if (!isSharing) {
        await OpenFile.open(filePath);
      }
      return filePath;
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to save document.')),
      );
    }

    return null;
  }

  void _showOptions(String url) async {
    final fileName = url.split('/').last;
    final tempDir = (await getTemporaryDirectory()).path;

    if (!mounted) return;
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
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                await _downloadFile(url, tempDir, fileName, false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save Document'),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                final manageStorageStatus =
                    await Permission.manageExternalStorage.request();
                final storageStatus = await Permission.storage.request();
                if (manageStorageStatus.isGranted || storageStatus.isGranted) {
                  final saveDir = Platform.isAndroid
                      ? '/storage/emulated/0/Download/Case Sync/${widget.caseNo}'
                      : (await getApplicationDocumentsDirectory()).path;
                  final _ =
                      await _downloadFile(url, saveDir, fileName, false, true);
                } else {
                  await openAppSettings();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                final filePath =
                    await _downloadFile(url, tempDir, fileName, true);
                if (filePath != null) {
                  await Share.shareXFiles([XFile(filePath)],
                      text: 'Here is the document!');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () async {
                HapticFeedback.mediumImpact();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: url));
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final docUrl = widget.doc['docs'];
    final fileName = docUrl.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showOptions(docUrl);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        child: InkWell(
          // Use InkWell for tap effect
          onTap: () {
            HapticFeedback.mediumImpact();
            _showOptions(
                docUrl); // Assuming _showOptions is defined in the state
          },
          onLongPress: () {
            HapticFeedback.lightImpact();
            // You can add a different action on long press if desired
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Long Pressed')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _buildFileThumbnail(docUrl, extension),
                const SizedBox(
                    width: 12), // Increased spacing for better visual
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600, // Slightly bolder
                          fontSize: 16.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8), // Increased spacing
                      Text(
                        'Added By: ${widget.doc['handled_by']}',
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[700]), // More subtle color
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${widget.doc['date_time']}',
                        style:
                            TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                      ),
                      if (_progress > 0.0 && _progress < 1.0)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0), // Added top padding
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileThumbnail(String url, String extension) {
    if (extension == 'pdf') {
      return const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red);
    } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return Image.network(url, height: 50, width: 50, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
        return const Icon(Icons.image, size: 50, color: Colors.grey);
      });
    } else {
      return const Icon(Icons.insert_drive_file, size: 50, color: Colors.blue);
    }
  }
}
