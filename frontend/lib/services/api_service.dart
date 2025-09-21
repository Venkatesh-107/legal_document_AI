import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
//api_service.dart

class ApiService {
  static const String baseUrl = "http://127.0.0.1:5000";

  static Future<String> uploadDocument(String filePath) async {
    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/upload"));
    request.files.add(await http.MultipartFile.fromPath("file", filePath));
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var data = json.decode(responseBody);
    return data["extracted_text"] ?? "";
  }

  static Future<String> uploadDocumentWeb(Uint8List fileBytes, String fileName) async {
    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/upload"));
    request.files.add(http.MultipartFile.fromBytes("file", fileBytes, filename: fileName));
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var data = json.decode(responseBody);
    return data["extracted_text"] ?? "";
  }

  static Future<Map<String, String>> summarizeTextStructured(String text) async {
    var response = await http.post(
      Uri.parse("$baseUrl/summarize"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"text": text}),
    );
    var data = json.decode(response.body);
    if (data.containsKey("summary")) {
      return {
        "key_points": data["summary"],
        "risks": "",
        "recommendations": ""
      };
    }
    return {
      "key_points": data["key_points"] ?? "",
      "risks": data["risks"] ?? "",
      "recommendations": data["recommendations"] ?? "",
    };
  }
}
