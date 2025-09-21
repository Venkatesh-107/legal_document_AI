import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//summary_card.dart

class SummaryCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;

  SummaryCard({required this.title, required this.content, this.icon});

  void copyToClipboard(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon, color: Colors.indigo),
                if (icon != null) SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                if (content.trim().isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.grey[700]),
                    tooltip: "Copy $title",
                    onPressed: () => copyToClipboard(context, content),
                  ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              content.isNotEmpty ? content : "No content available.",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
