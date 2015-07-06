#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:actors/server.dart' as server;

void main() {
  group("Server messages", () {
      test("initialize properly", () {
          server.Method methGet = server.Method.GET;
          server.Method methPost = server.Method.POST;
          expect(methGet, equals(server.Method.GET));
          expect(methPost, equals(server.Method.POST));
        });
    });
  group("Websocket Server", () {
    test("initializes", () async {

        var s = new server.HttpServer('0.0.0.0', 6789);

        expect(s.started, equals(false));

        await s.startServer();

        expect(s.started, equals(true));

        await s.stopServer();

        expect(s.started, equals(false));
      });

    test("listens", () async {

        var postString = "Hello World!";

        var s = new server.HttpServer('0.0.0.0', 6789);
        Stream<String> str = await s.startServer();

        var client = new HttpClient();

        HttpClientRequest req = await (client.post('127.0.0.1', 6789, '/'));
        req.write(postString);
        var response = await req.close();
        int statusCode = response.statusCode;
        expect(statusCode, equals(201));

        print("stopping server");
        await s.stopServer();
      });
  });
}
