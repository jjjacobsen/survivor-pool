import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:survivor_pool/app/routes.dart';

class AuthHttpClient {
  AuthHttpClient._();

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await http.get(uri, headers: _prepareHeaders(headers));
    _captureToken(response);
    return response;
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await http.post(
      uri,
      headers: _prepareHeaders(headers),
      body: body,
    );
    _captureToken(response);
    return response;
  }

  static Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await http.patch(
      uri,
      headers: _prepareHeaders(headers),
      body: body,
    );
    _captureToken(response);
    return response;
  }

  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await http.delete(
      uri,
      headers: _prepareHeaders(headers),
      body: body,
    );
    _captureToken(response);
    return response;
  }

  static Map<String, String> _prepareHeaders(Map<String, String>? headers) {
    final prepared = <String, String>{};
    if (headers != null) {
      prepared.addAll(headers);
    }
    final token = AppSession.token;
    if (token != null && token.isNotEmpty) {
      prepared.putIfAbsent('Authorization', () => 'Bearer $token');
    }
    return prepared;
  }

  static void _captureToken(http.Response response) {
    final newToken =
        response.headers['x-new-token'] ??
        response.headers['X-New-Token'] ??
        response.headers['X-new-token'];
    if (newToken == null || newToken.isEmpty) {
      return;
    }
    unawaited(AppSession.updateToken(newToken));
  }
}
