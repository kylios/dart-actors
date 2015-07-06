part of actors;

enum DefaultMessages {
  KILL
}

class PropertyNotSetException extends Exception {
  final ActorProps props;
  final String name;
  PropertyNotSetException(this.props, this.name) :
    super("No property '${this.name}' found in props: ${this.props}");
}

class ActorProps {
  Map<String, dynamic> _inner = new Map<String, dynamic>();

  factory ActorProps.fromMap(Map<String, dynamic> m) {
    ActorProps p = new ActorProps();
    m.forEach((k, v) => p._inner[k] = v);
    return p;
  }

  ActorProps.empty();

  ActorProps();

  call(String name) {
    var value = this._inner[name];
    if (value == null) {
      throw PropertyNotSetException(this, name);
    }
    return this._inner[name];
  }

  String toString() {
    return this._inner.toString();
  }
}

class ActorRef {
  final String path;
  final Actor _actor;
  ActorRef(this.path, this._actor);
  String toString() => "ActorRef(path=$path)";
  call(String name) => this._actor(name);
}

class _MessagePair {
  final ActorRef sender;
  final dynamic message;
  _MessagePair(this.sender, this.message);
}

abstract class Actor {

	ActorSystem _system;
  ActorProps _props;
  // TODO: replace this with a mailbox at some point
  StreamController<_MessagePair> _messageQueue;
  StreamSubscription<_MessagePair> _subscription;

  ActorRef _ref;

  ActorRef get ref => this._ref;

  call(String name) => this._props(name);

	/// This method is called when the actor is spawned.
	/// The actor is not ready to accept messages until the
	/// future returned by it completes.
	Future setUp();

  Future _setUp(ActorSystem system, String name, ActorProps props) async {
    this._system = system;
    this._props = props;
    this._ref = new ActorRef(this._system.name + '/' + name, this);
    this._messageQueue = new StreamController<_MessagePair>();

    await this.setUp();
    this._subscription = this._messageQueue.stream.listen(this._handle);
  }

	/// This method is called when the actor dies.  The cause
	/// of the actor's death does not matter; this method will
	/// always be called.
	Future tearDown();

  Future _tearDown() async {
    // TODO: this behavior may need to be configured
    await this._subscription.cancel();
    await this.tearDown();
  }

	/// Handle a message incoming to this actor.  Messages
	/// may come in any type; it is up to the implementation 
	/// to check the type and handle the contents appropriately.
	void handle(ActorRef sender, dynamic message);

  void _handle(_MessagePair pair) => 
    this.handle(pair.sender, pair.message);

	/// Send a message to another actor.
	void sendMessage(ActorRef receiver, dynamic message) {
		this._system._sendMessage(this._ref, receiver, message);
	}

  void _receiveMessage(ActorRef sender, dynamic message) {

    if (message == DefaultMessages.KILL) {
      this._system._removeActor(this);
      return;
    }

    this._messageQueue.add(new _MessagePair(sender, message));
  }
}

abstract class ActorFactory {

	/// Given a set of props, creates and returns a new actor instance.
	/// This method is abstract.  Extending classes should implement this
	/// method.
	Actor createActor(ActorProps props);
}