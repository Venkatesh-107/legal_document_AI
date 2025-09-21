import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../widgets/summary_card.dart';
//summarizer_page.dart

class SummarizerPage extends StatefulWidget {
  @override
  _SummarizerPageState createState() => _SummarizerPageState();
}

class _SummarizerPageState extends State<SummarizerPage> with SingleTickerProviderStateMixin {
  String extractedText = "";
  Map<String, String> summary = {};
  bool loading = false;
  late TabController _tabController;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> processInput({bool isUrl = false}) async {
    String input = _inputController.text.trim();
    if (input.isEmpty) return;

    setState(() => loading = true);
    extractedText = input;

    summary = await ApiService.summarizeTextStructured(input);

    // AI Disclaimer for short text
    if ((summary["key_points"] ?? "").length < 50) {
      summary = {
        "key_points": "Input too short. AI-generated summary may be unreliable.",
        "risks": "⚠️ Verify content manually.",
        "recommendations": "Paste full text, URL, or upload a document."
      };
    }

    setState(() => loading = false);
  }

  Future<void> pickAndProcessFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      setState(() => loading = true);
      String text = "";
      if (kIsWeb) {
        Uint8List? fileBytes = result.files.single.bytes;
        String fileName = result.files.single.name;
        if (fileBytes != null) text = await ApiService.uploadDocumentWeb(fileBytes, fileName);
      } else {
        String? filePath = result.files.single.path;
        if (filePath != null) text = await ApiService.uploadDocument(filePath);
      }
      extractedText = text;
      summary = await ApiService.summarizeTextStructured(extractedText);
      setState(() => loading = false);
    }
  }

  Widget buildTabContent(String title, String content, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(child: SummaryCard(title: title, content: content, icon: icon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("⚖️ Legal Doc Scanner"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Extracted Text"),
            Tab(text: "Key Points"),
            Tab(text: "Risks"),
            Tab(text: "Recommendations"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Input Box & Buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _inputController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Paste text or enter URL...",
                    labelText: "Text / URL Input",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => processInput(),
                        icon: Icon(Icons.summarize),
                        label: Text("Summarize"),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: pickAndProcessFile,
                        icon: Icon(Icons.upload_file),
                        label: Text("Upload Document"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // Tabs for results
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildTabContent("Extracted Text", extractedText, icon: Icons.text_snippet),
                buildTabContent("Key Points", summary["key_points"] ?? "", icon: Icons.star),
                buildTabContent("Risks", summary["risks"] ?? "", icon: Icons.warning),
                buildTabContent("Recommendations", summary["recommendations"] ?? "", icon: Icons.thumb_up),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
