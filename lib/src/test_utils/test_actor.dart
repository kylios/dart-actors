part of test_utils;

class TestActor extends Actor {

  void setUp() async {
    print("${this.ref} setUp");
    this.registerUmbrella((ActorRef sender, dynamic message) =>
      print("Received $message from $sender"));
  }

  void tearDown() async {
    print("${this.ref} tearDown()");
  }
}

class PingMessage {}
class PongMessage {}

class PingActor extends Actor {

  void setUp() async {
    this.registerHandler(PongMessage, this._handlePong);
    this.sendMessage(this('receiver'), new PingMessage());
  }

  void tearDown() async {}

  void _handlePong(ActorRef sender, dynamic message) {
    print("${this.ref} received $message from $sender");
    this('completer').complete(message);
  }
}

class PongActor extends Actor {

  void setUp() async {
    this.registerHandler(PingMessage, this._handlePing);
  }

  void tearDown() async {}

  void _handlePing(ActorRef sender, dynamic message) {
    print("${this.ref} received $message from $sender");
    this.sendMessage(sender, new PongMessage());
  }
}

class GetChildCounts {
  final int child;
  GetChildCounts(this.child);
}
class ChildCounts {
  final Map counts;
  ChildCounts(this.counts);
}

class TestParentActor extends Actor {

  ActorRef child1;
  ActorRef child2;
  ActorRef child3;

  void setUp() async {

    this.registerHandler(GetChildCounts, this._handleGetChildCounts);

    this.child1 = await this.createActor(TestChildActor, 'child1');
    this.child2 = await this.createActor(TestChildActor, 'child2');
    this.child3 = await this.createActor(TestChildActor, 'child3');
  }

  void tearDown() async {

  }

  void _handleGetChildCounts(ActorRef sender, dynamic message) {
    print("${this.ref} received message $message from $sender"); 

    var response = null;
    if (message.child == 1) {
      response = this.system.statCounts(this.child1);
    } else if (message.child == 2) {
      response = this.system.statCounts(this.child2);
    } else if (message.child == 3) {
      response = this.system.statCounts(this.child3);
    }

    if (response != null) {
      this.sendMessage(sender, new ChildCounts(response));
    }
  }
}

class TestChildActor extends TestActor {

  void setUp() async {
    await super.setUp();
    this.stats.increment("setup");
  }
  void tearDown() async {
    await super.tearDown();
    this.stats.increment("teardown");
  }
}