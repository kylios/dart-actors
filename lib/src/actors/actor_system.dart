part of actors;


class _MessageSendActor extends Actor {

  void setUp() {
    this.registerUmbrella(this._handleMessage);
  }
  void tearDown() {}
  void _handleMessage(ActorRef sender, dynamic message) {
    this._props("completer").complete(message);
    this.system.sendMessage(this.ref, DefaultMessages.KILL);
  }
}


class ActorSystem extends ActorManager {

	final String _path;
  final ActorStats stats = new ActorStats();

  final Actor _deadLetters = new DeadLetters();

  ActorSystem get _system => this;
  String get name => this._path;
	
	ActorSystem(this._path);	

  /*
	Future<ActorRef> _addActor(Actor a, String actorName, ActorProps props) async {
    print("System: _addActor(name=$actorName)");
    await a._setUp(this, actorName, props);
    print("System: adding ${a.ref}");
		this._actors.add(a);
    return a.ref;
	}

  Future _removeActor(Actor a) async {
    await a._tearDown();
    this._actors.remove(a.ref.path);
  }
  */

	void _sendMessage(ActorRef sender, ActorRef receiver, dynamic message) {

    Actor receiverActor = receiver._actor;
    if (receiverActor == null) {
      this._sendMessage(sender, this._deadLetters, message);
      // TODO: log a notice (configurable)
      return;
    }

    receiverActor._messageQueue.add(new _MessagePair(sender, message));
	}

  void sendMessage(ActorRef receiver, dynamic message) {
    this._sendMessage(this._deadLetters, receiver, message);
  }

  Future sendMessageSync(ActorRef receiver, dynamic message) {
    print("sendMessageSync(receiver=$receiver)");
    Completer c = new Completer();
    ActorProps props = new ActorProps.fromMap({
        "completer": c
      });
    this.createActor(_MessageSendActor, "__ephemeral", props)
      .then((ref) => this._sendMessage(ref, receiver, message));
    return c.future;
  }

  Map<String, int> statCounts(ActorRef ref) => ref._actor.stats._counts;
}
