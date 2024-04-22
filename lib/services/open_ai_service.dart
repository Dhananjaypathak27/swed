import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swed/secrets.dart';
import 'package:swed/models/user_model.dart';

class OpenAIService {

  Future<http.Response> isArtPromptAPI2(String prompt) async{
    final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $OpenAIAPIKey'
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "user",
              "content":
              "Does this message want to generate an AI picture, image, Art or anything similar? $prompt. Simply answer with yes or no."
            }
          ]
        })).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        // Time has run out, do what you wanted to do.
        return http.Response('Network time out', 408); // Request Timeout response status code
      },
    );

    return res;
  }

  Future<http.Response> chatGPTAPI(List<UserModel> list) async {

      final res = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $OpenAIAPIKey'
          },
          body: jsonEncode({
            "model": "gpt-3.5-turbo",
            "messages": list
          }))
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          // Time has run out, do what you wanted to do.
          return http.Response('Network time out', 408); // Request Timeout response status code
        },
      );

      return res;
  }

  Future<http.Response> dallAPI2(String promot)async{
    final res = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $OpenAIAPIKey'
        },
        body: jsonEncode({
          "model": "dall-e-3",
          "prompt": promot,
          "n": 1,
          "size": "1024x1024"
        })).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        // Time has run out, do what you wanted to do.
        return http.Response('Network time out', 408); // Request Timeout response status code
      },
    );

    return res;
  }
}
