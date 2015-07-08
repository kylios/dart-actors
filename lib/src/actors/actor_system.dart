part of actors;

class ActorSystem {

	final String name;
	final List<Actor> _actors = new List<Actor>();

  final Actor _deadLetters = new DeadLetters();
	
	ActorSystem(this.name);	

  Future<ActorRef> createActor(Type actorCls, 
      String actorName, [ActorProps props = null]) {

    ClassMirror cls = reflectClass(actorCls);

    if (props == null) {
      props = new ActorProps.empty();
    }

    Actor a = cls.newInstance(new Symbol(''), []).reflectee;

    // TODO: the system should have a mechanism that can create the actor
    // in an isolate 
    return this._addActor(a, actorName, props);
  }

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

  Map<String, int> statCounts(ActorRef ref) => ref._actor._stats._counts;
}
