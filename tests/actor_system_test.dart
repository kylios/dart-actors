#!/usr/bin/env dart

import 'dart:async';
import 'dart:mirrors';

import 'package:test/test.dart';
import 'package:actors/actors.dart';
import 'package:actors/test_utils.dart';

void main() {
  group("Actor System", () {

      test("initializes", () {
          String name = "test_system";
          ActorSystem system = new ActorSystem(name);
          expect(system.name, equals(name));
        });

      test("can create actors", () async {
          String actor_name = "test_actor";
          String system_name = "test_system";
          ActorSystem system = new ActorSystem(system_name);
          Map<String, dynamic> props_map = {
            "test": 1,
            "test2": "thing"
          };
          ActorProps props = new ActorProps.fromMap(props_map);
          ActorRef ref = 
            (await system.createActor(reflectClass(TestActor), actor_name, props));

          expect(ref.path, equals("$system_name/$actor_name"));

          props_map.forEach((String name, dynamic value) =>
            expect(ref(name), equals(value)));
        });
    });

  group("Actors", () {
      test("can send and receive messages", () async {

          ActorSystem system = new ActorSystem("pingpong");
          ActorRef pong = 
            await system.createActor(reflectClass(PongActor), 'pong');
          expect(pong, isNot(equals(null)));
          ActorRef ping = 
            await system.createActor(reflectClass(PingActor), 'ping', 
              new ActorProps.fromMap({"receiver": pong}));
        });
    });
}
