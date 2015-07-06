part of test_utils;

class TestActor extends Actor {

  Future setUp() async {
    print("${this.ref} setUp");
  }

  Future tearDown() async {
    print("${this.ref} tearDown()");
  }

  void handle(ActorRef sender, dynamic message) {
    print("Received $message from $sender");
  }
}

class PingActor extends Actor {

  Future setUp() async {
    this.sendMessage(this('receiver'), "PING");
  }

  Future tearDown() async {}

  void handle(ActorRef sender, dynamic message) {
    if (message == "PONG") {
      print("${this.ref} received $message from $sender");
    }
  }
}

class PongActor extends Actor {

  Future setUp() async {}

  Future tearDown() async {}

  void handle(ActorRef sender, dynamic message) {
    if (message == "PING") {
      print("${this.ref} received $message from $sender");
      this.sendMessage(sender, "PONG");
    }
  }
}