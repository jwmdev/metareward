import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:metareward/api/network_exceptions.dart';

class NetworkService {
  static const headers = {'Content-type': 'application/json'};
  //Singleton class
  static final NetworkService _instance = NetworkService.internal();
  NetworkService.internal();
  factory NetworkService() => _instance;

  Future<dynamic> get(Uri uri, {Map header = NetworkService.headers}) async {
    dynamic responseJson;
    //Uri uri = Uri(path: url);
    try {
      final response = await http.get(uri, headers: headers);
      //print(response.body);
      responseJson = _returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
    return responseJson;
  }

  Future<dynamic> post(Uri uri,
      {Map headers = NetworkService.headers, body, encoding}) async {
    dynamic responseJson;
    try {
      final http.Response response = await http.post(
        uri,
        headers: headers as Map<String, String>,
        body: json.encode(body),
        // encoding: encoding as Encoding,
      );
      responseJson = _returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
    return responseJson;
  }

  Future<dynamic> put(Uri uri, {required Map body, headers}) async {
    dynamic responseJson;
    try {
      // Uri uri = Uri(path: url);

      final response = await http.put(uri, body: body, headers: headers);
      responseJson = _returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
    return responseJson;
  }

  Future<dynamic> delete(Uri uri, {required Map body, headers}) async {
    var apiResponse;
    try {
      //Uri uri = Uri(path: url);

      final response = await http.delete(uri, headers: headers);
      apiResponse = _returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
    return apiResponse;
  }
}

dynamic _returnResponse(http.Response response) {
  switch (response.statusCode) {
    case 200:
    case 201:
      var responseJson;
      try {
        responseJson = json.decode(response.body.toString());
      } catch (e) {
        throw InvalidInputException(response.body.toString());
      }
      /*//handle node data
      if (responseJson["nodes"] != null) {
        return responseJson["nodes"];
      }
      //the rest of metahash api
      return responseJson["result"];
      */
      return responseJson;

    case 400:
      throw BadRequestException(response.body.toString());
    case 401:
    case 403:
      throw UnauthorisedException(response.body.toString());
    case 500:
    default:
      throw FetchDataException(
          'Error occured while Communication with Server with StatusCode : ${response.statusCode}');
  }
}
