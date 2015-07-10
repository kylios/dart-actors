part of test_utils;

class TestActor extends Actor {

  void setUp() async {
    print("${this.ref} setUp");
  }

  void tearDown() async {
    print("${this.ref} tearDown()");
  }

  void handle(ActorRef sender, dynamic message) {
    print("Received $message from $sender");
  }
}

class PingActor extends Actor {

  void setUp() async {
    this.sendMessage(this('receiver'), "PING");
  }

  void tearDown() async {}

  void handle(ActorRef sender, dynamic message) {
    if (message == "PONG") {
      print("${this.ref} received $message from $sender");
    }
  }
}

class PongActor extends Actor {

  void setUp() async {}

  void tearDown() async {}

  void handle(ActorRef sender, dynamic message) {
    if (message == "PING") {
      print("${this.ref} received $message from $sender");
      this.sendMessage(sender, "PONG");
    }
  }
}

class TestParentActor extends Actor {

  ActorRef child1;
  ActorRef child2;
  ActorRef child3;

  void setUp() async {

    this.child1 = await this.createActor(TestChildActor, 'child1');
    this.child2 = await this.createActor(TestChildActor, 'child2');
    this.child3 = await this.createActor(TestChildActor, 'child3');
  }

  void tearDown() async {

  }

  void handle(ActorRef sender, dynamic message) {
    print("${this.ref} received message $message from $sender"); 

    var response = null;
    if (message == "get_child1_counts") {
      response = this.system.statCounts(this.child1);
    } else if (message == "get_child2_counts") {
      response = this.system.statCounts(this.child2);
    } else if (message == "get_child3_counts") {
      response = this.system.statCounts(this.child3);
    }

    if (response != null) {
      this.sendMessage(sender, response);
    }
  }
}

class TestChildActor extends TestActor {

  void setUp() async {
    await super.setUp();
    this.incrementStat("setup");
  }
  void tearDown() async {
    await super.tearDown();
    this.decrementStat("teardown");
  }
}