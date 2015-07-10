#!/usr/bin/env dart

import 'dart:async';

import 'package:test/test.dart';
import 'package:actors/actors.dart';
import 'package:actors/test_utils.dart';

void main() {
  group("Actor stats", () {
      test("can increment", () {

          ActorStats stats = new ActorStats();

          stats.increment("test0");
          expect(stats.counts["test0"], equals(1));

          stats.decrement("test0");
          expect(stats.counts["test0"], equals(0));

          expect(stats.counts["test1"], equals(null));

          List<int> range = new List<int>.generate(10, (index) => index);
          range.forEach((el) {
              stats.increment("test1");
              expect(stats.counts["test1"], equals(el + 1));
              return true;
            });
        });
    });
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
            (await system.createActor(TestActor, actor_name, props));

          expect(ref.path, equals("$system_name/$actor_name"));

          props_map.forEach((String name, dynamic value) =>
            expect(ref(name), equals(value)));
        });

      test("can return messages", () async {

          String systemName = "system";
          ActorSystem system = new ActorSystem(systemName);

          ActorRef ref = await system.createActor(PongActor, 'PONG');
          expect(ref, isNot(equals(null)));
          var message = await system.sendMessageSync(ref, "PING");

          expect(system.statCounts(ref)['messages.handled'], equals(1));
          expect(message, equals("PONG"));
        });
    });

  group("Actors", () {
      test("can send and receive messages", () async {

          // Create two actors
          ActorSystem system = new ActorSystem("pingpong");

          Future<ActorRef> pongFuture = 
            system.createActor(PongActor, 'pong');
          ActorRef pong = await pongFuture;

          expect(pong, isNot(equals(null)));
          expect(pong.path, equals("${system.name}/${pong.name}"));
          expect(pong.active, equals(true));

          ActorRef ping = 
            await system.createActor(PingActor, 'ping', 
              new ActorProps.fromMap({"receiver": pong}));

          expect(ping, isNot(equals(null)));
          expect(ping.path, equals("${system.name}/${ping.name}"));
          expect(ping.active, equals(true));

          print("Actors created");

          // send some messages
          for (var i = 0; i < 10; i++) {
            system.sendMessage(ping, i);
          }

          // Kill both of them
          system.sendMessage(pong, DefaultMessages.KILL);
          system.sendMessage(ping, DefaultMessages.KILL);

          expect(pong.active, equals(true));
          expect(ping.active, equals(true));

          // wait for them to die
          await pong.done;
          await ping.done;

          expect(pong.active, equals(false));
          expect(ping.active, equals(false));

          // check stats
          var pingCounts = system.statCounts(ping);
          var pongCounts = system.statCounts(pong);
          expect(pingCounts['messages.sent'], equals(1));
          expect(pingCounts['messages.handled'], equals(12));
          expect(pongCounts['messages.sent'], equals(1));
          expect(pongCounts['messages.handled'], equals(2));
        });

      test("can manage children", () async {

          ActorSystem system = new ActorSystem("system");

          ActorRef parent1 = await system.createActor(TestParentActor, 'parent',
            new ActorProps.empty());

          expect(system.statCounts(parent1)['actors.begin_add'], equals(3));
          expect(system.statCounts(parent1)['actors.end_add'], equals(3));

          Map<String, int> child1Counts = await system.sendMessageSync(parent1, 'get_child1_counts');
          Map<String, int> child2Counts = await system.sendMessageSync(parent1, 'get_child2_counts');
          Map<String, int> child3Counts = await system.sendMessageSync(parent1, 'get_child3_counts');

          expect(child1Counts['setup'], equals(1));
          expect(child2Counts['setup'], equals(1));
          expect(child3Counts['setup'], equals(1));

        });
    });
}
