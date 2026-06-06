import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';

class ReceiptOcrPage extends StatefulWidget {
  const ReceiptOcrPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<ReceiptOcrPage> createState() => _ReceiptOcrPageState();
}

class _ReceiptOcrPageState extends State<ReceiptOcrPage> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String _ocrText = '';
  List<Map<String, dynamic>> _ocrLines = [];

  Map<String, dynamic>? _analysisResult;
  List<Map<String, dynamic>> _editableItems = [];

  bool _isRecognizing = false;
  bool _isSending = false;
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image == null) {
      return;
    }

    setState(() {
      _selectedImage = File(image.path);
      _ocrText = '';
      _ocrLines = [];
      _analysisResult = null;
      _editableItems = [];
    });
  }

  Future<void> _recognizeText() async {
    if (_selectedImage == null) {
      _showMessage('먼저 영수증 이미지를 선택해 주세요.');
      return;
    }

    setState(() {
      _isRecognizing = true;
      _ocrText = '';
      _ocrLines = [];
      _analysisResult = null;
      _editableItems = [];
    });

    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );

    try {
      final inputImage = InputImage.fromFilePath(_selectedImage!.path);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final extractedLines = <Map<String, dynamic>>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final box = line.boundingBox;

          extractedLines.add({
            'text': line.text,
            'x': box.left,
            'y': box.top,
            'width': box.width,
            'height': box.height,
          });
        }
      }

      extractedLines.sort((a, b) {
        final yCompare = (a['y'] as num).compareTo(b['y'] as num);
        if (yCompare != 0) {
          return yCompare;
        }

        return (a['x'] as num).compareTo(b['x'] as num);
      });

      setState(() {
        _ocrText = recognizedText.text;
        _ocrLines = extractedLines;
      });

      if (_ocrText.trim().isEmpty) {
        _showMessage('인식된 텍스트가 없습니다. 더 선명한 이미지를 사용해 주세요.');
      }
    } catch (e) {
      _showMessage('OCR 처리 오류: $e');
    } finally {
      await textRecognizer.close();

      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    }
  }

  Future<void> _sendToBackend() async {
    if (_ocrText.trim().isEmpty) {
      _showMessage('먼저 OCR 텍스트를 추출해 주세요.');
      return;
    }

    setState(() {
      _isSending = true;
      _analysisResult = null;
      _editableItems = [];
    });

    try {
      final response = await http.post(
        Uri.parse(receiptOcrTextUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'ocrText': _ocrText,
          'ocrLines': _ocrLines,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(decodedBody) as Map<String, dynamic>;
        final items = result['items'];

        setState(() {
          _analysisResult = result;
          _editableItems = items is List
              ? items.map((item) {
                  final map = item as Map<String, dynamic>;

                  return {
                    'originalName': map['originalName'] ?? map['name'] ?? '',
                    'price': map['price'] ?? 0,
                  };
                }).toList()
              : [];
        });

        _showMessage('품목 후보 추출이 완료되었습니다. 내용을 확인해 주세요.');
      } else {
        _showMessage('백엔드 오류 ${response.statusCode}: $decodedBody');
      }
    } catch (e) {
      _showMessage('백엔드 요청 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _saveFinalReceipt() async {
    final finalItems = _editableItems
        .map((item) {
          final name = '${item['originalName'] ?? ''}'.trim();
          final price = _parsePrice(item['price']);

          return {
            'name': name,
            'price': price,
          };
        })
        .where((item) {
          final name = '${item['name']}'.trim();
          final price = item['price'] as int;

          return name.isNotEmpty && price > 0;
        })
        .toList();

    if (finalItems.isEmpty) {
      _showMessage('저장할 품목이 없습니다. 품목명과 가격을 확인해 주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse(receiptSaveUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'ocrText': _ocrText,
          'ocrLines': _ocrLines,
          'items': finalItems,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(decodedBody) as Map<String, dynamic>;

        setState(() {
          _analysisResult = result;
        });

        _showMessage('영수증이 최종 저장되었습니다.');
      } else {
        _showMessage('저장 오류 ${response.statusCode}: $decodedBody');
      }
    } catch (e) {
      _showMessage('저장 요청 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addItem() {
    setState(() {
      _editableItems.add({
        'originalName': '',
        'price': 0,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
    });
  }

  int _parsePrice(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final text = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(text) ?? 0;
  }

  Map<String, dynamic>? get _summary {
    final summary = _analysisResult?['summary'];
    return summary is Map<String, dynamic> ? summary : null;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 OCR 분석'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 12),
            _buildImageButtons(),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isRecognizing ? null : _recognizeText,
              child: Text(_isRecognizing ? 'OCR 처리 중...' : 'OCR 텍스트 추출'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _isSending ? null : _sendToBackend,
              child: Text(_isSending ? '분석 요청 중...' : '품목 후보 추출'),
            ),
            const SizedBox(height: 20),
            _buildOcrTextCard(),
            const SizedBox(height: 20),
            if (_editableItems.isNotEmpty) ...[
              _buildEditableItemList(),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isSaving ? null : _saveFinalReceipt,
                child: Text(_isSaving ? '저장 중...' : '최종 저장'),
              ),
            ],
            if (_analysisResult != null && summary != null) ...[
              const SizedBox(height: 20),
              _buildReceiptIdCard(),
              const SizedBox(height: 12),
              _buildSummaryCard(summary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('선택된 영수증 이미지가 없습니다.'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        _selectedImage!,
        height: 240,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildImageButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo),
            label: const Text('갤러리 선택'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('카메라 촬영'),
          ),
        ),
      ],
    );
  }

  Widget _buildOcrTextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OCR 텍스트 / 라인 ${_ocrLines.length}개',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _ocrText.isEmpty ? '아직 추출된 텍스트가 없습니다.' : _ocrText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableItemList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '품목 후보 확인',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'OCR 결과가 틀릴 수 있으니 품목명과 가격을 확인한 뒤 최종 저장해 주세요.',
            ),
            const SizedBox(height: 12),
            ...List.generate(_editableItems.length, (index) {
              final item = _editableItems[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: '${item['originalName'] ?? ''}',
                        decoration: const InputDecoration(
                          labelText: '품목명',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          item['originalName'] = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: '${item['price'] ?? 0}',
                        decoration: const InputDecoration(
                          labelText: '가격',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          item['price'] = _parsePrice(value);
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeItem(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptIdCard() {
    return Card(
      child: ListTile(
        title: const Text('저장 정보'),
        subtitle: Text(
          'receiptId: ${_analysisResult?['receiptId'] ?? '-'}\n'
          'userId: ${_analysisResult?['userId'] ?? '-'}',
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('영수증 요약', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('총 금액: ${summary['totalPrice']}원'),
            Text('총 추정 탄소량: ${summary['totalEstimatedCarbonGram']}g CO₂-eq'),
            Text('총 추정 탄소량: ${summary['totalEstimatedCarbonKg']}kg CO₂-eq'),
            Text('평균 탄소 점수: ${summary['averageCarbonScore']}'),
            Text('품목 수: ${summary['itemCount']}개'),
            Text('주요 카테고리: ${summary['topCategory']}'),
            Text('주요 세부 카테고리: ${summary['topSubCategory']}'),
          ],
        ),
      ),
    );
  }
}