part of actors;

class ActorSystem {

	final String name;
	final Map<String, Actor> _actors = new Map<String, Actor>();
	
	ActorSystem(this.name);	

  Future<ActorRef> createActor(ClassMirror cls, 
      String actorName, [ActorProps props = null]) {

    if (props == null) {
      props = new ActorProps.empty();
    }

    Actor a = cls.newInstance(new Symbol(''), []).reflectee;

    // TODO: the system should have a mechanism that can create the actor
    // in an isolate 
    return this._addActor(a, actorName, props);
  }

	Future<ActorRef> _addActor(Actor a, String actorName, ActorProps props) async {
    await a._setUp(this, actorName, props);
		this._actors[a.ref.path] = a;
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

    receiverActor._receiveMessage(sender, message);
	}

}
