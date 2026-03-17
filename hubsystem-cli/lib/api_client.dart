import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final String token;

  ApiClient({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Hub-Token': token,
  };

  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: _headers);
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getList(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: _headers);
    _checkStatus(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'API error $statusCode: $body';
}
