part of actors;

enum DefaultMessages {
  KILL
}


/// This exception is thrown when a property access is attemted and that 
/// property does not exist.
class PropertyNotSetException extends Exception {
  final ActorProps props;
  final String name;
  PropertyNotSetException(this.props, this.name) :
    super("No property '${this.name}' found in props: ${this.props}");
}


/// This class stores properties for an actor.  These properties are static and
/// cannot be changed.  They must be known before the actor is initialized.
/// The actor will keep its ActorProps throughout its lifetime and use this 
/// object to access the properties.
class ActorProps {
  Map<String, dynamic> _inner = new Map<String, dynamic>();

  /// Creates a new ActorPreps from a map of key/value pairs
  factory ActorProps.fromMap(Map<String, dynamic> m) {
    ActorProps p = new ActorProps();
    m.forEach((k, v) => p._inner[k] = v);
    return p;
  }

  /// Creates an empty ActorProps
  ActorProps.empty();

  /// The default constructor
  ActorProps();

  /// Allows ActorProps to be called like a function.  The key name is the 
  /// only argument, and it returns the value of that key.
  call(String name) {
    var value = this._inner[name];
    if (value == null) {
      throw PropertyNotSetException(this, name);
    }
    return this._inner[name];
  }

  /// Returns a string representation of this object
  String toString() {
    return this._inner.toString();
  }
}


/// The ActorRef is the main handle for an actor.  No class deals with an actor
/// directly except for the ActorSystem, so ActorRef's are passed around.  The
/// actor system can convert an actor ref into an actor, but only does so 
/// internally.
class ActorRef {
  final Actor _actor;

  String get name => this._actor._name;
  String get path => this._actor._path;

  /// The default constructor
  ActorRef(this._actor);

  /// Returns a string representation of this actor ref
  String toString() => "ActorRef(path=${this.path})";

  /// Allows this object to be called like a function.  This aliases to the 
  /// actor's ActorProps call method.
  call(String name) => this._actor(name);

  /// Returns true if the backing actor is active
  bool get active => this._actor._active;

  /// This future will complete when the backing actor has died
  Future get done => this._actor._onDone.future;

}


class _MessagePair {
  final ActorRef sender;
  final dynamic message;
  _MessagePair(this.sender, this.message);
}


/// This class allows actors to maintain basic statistics about themselves.
class ActorStats {
  final Map<String, int> _counts = new Map<String, int>();

  // NOTE: For testing only
  Map<String, int> get counts => this._counts;

  /// Increments a stat by amount.  If the stat was not previously set, it sets
  /// it to amount.  amount defaults to 1.
  void increment(stat, [amount = 1]) {
    if (this._counts[stat] == null) {
      this._counts[stat] = amount;
    } else {
      this._counts[stat] = amount + this._counts[stat];
    }
  }

  /// Decrements a stat by amount.  amount defaults to 1
  void decrement(stat, [amount = 1]) {
    if (this._counts[stat] != null) {
      this._counts[stat] = this._counts[stat] - amount;
    }
  }
}


/// Messages should be registered within the Actor with a callback of this 
/// format.  When the actor receives a message of the registered type, the
/// associated handler will be called.
typedef void MessageHandler(ActorRef sender, dynamic message);


/// The main actor class.  This class should be subclassed.  It handles the full
/// lifecycle of an actor.  
/// 
/// An actor is a lightweight entity that responds to messages by performing 
/// various actions.  It is subclassed so it may implement this behavior.  Actors
/// are managed by an actor system, which handles the marshalling of messages
/// into and out of the system and between actors.  Actors may spawn child
/// actors, which are then managed by the actor itself.  
abstract class Actor extends ActorManager {

	ActorSystem _system;
  ActorProps _props;
  // TODO: replace this with a mailbox at some point
  StreamController<_MessagePair> _messageQueue;
  StreamSubscription<_MessagePair> _subscription;

  // The ActorRef that proxies this Actor
  ActorRef _ref;

  // The actor's name and path
  String _name;
  String _path;

  // This maps message types to handler functions
  final Map<Type, MessageHandler> _handlers = new Map<Type, MessageHandler>();
  // If set, this will handle message not handled by a specific handler
  MessageHandler _umbrella = null;

  // This completer completes when the actor has been killed
  final Completer _onDone = new Completer();

  // Indicates whether the actor is still handling messages
  bool get _active => ! this._onDone.isCompleted;

  final ActorStats stats = new ActorStats();

  ActorRef get ref => this._ref;
  ActorSystem get system => this._system;

  /// Calling this actor using a property name as an argument returns that
  /// property's value
  call(String name) => this._props(name);

  void registerHandler(Type messageType, MessageHandler handler) =>
    this._handlers[messageType] = handler;
  void unregisterHandler(Type messageType) => 
    this._handlers[messageType] = null;
  void registerUmbrella(MessageHandler umbrella) => this._umbrella = umbrella;
  void unregisterUmbrella() => this._umbrella = null;

	/// This method is called when the actor is spawned.
	/// The actor is not ready to accept messages until the
	/// future returned by it completes.
	void setUp();

  /// This method is called when the actor dies.  The cause
  /// of the actor's death does not matter; this method will
  /// always be called.
  void tearDown();

  /// Send a message to another actor.
  void sendMessage(ActorRef receiver, dynamic message) {
    this._system._sendMessage(this._ref, receiver, message);
    this.stats.increment("messages.sent");
  }

  void _setUp(ActorSystem system, String name, String path, ActorProps props)
      async {
    this._system = system;
    this._props = props;
    this._name = name;
    this._path = path;
    this._ref = new ActorRef(this);
    this._messageQueue = new StreamController<_MessagePair>();
    this._subscription = this._messageQueue.stream.listen(this._handle);
    print("${this.ref} _setUp()");

    await this.setUp();
  }

  void _tearDown() async {
    // wait for all child actors to die
    await this._actorsDone;
    // TODO: this behavior may need to be configured
    await this._subscription.cancel();
    await this.tearDown();
    this._messageQueue.close();
  }

  Future _handle(_MessagePair pair) async {

    this.stats.increment("messages.handled");

    // handle default messages first
    if (pair.message == DefaultMessages.KILL) {
      print("${this.ref} is dying");
      print("${this.ref} is killing all children");
      await this._killAllActors();
      await this._system._removeActor(this);
      this._onDone.complete();
      return;
    }

    Type t = pair.message.runtimeType;
    print("Type: $t");
    if (this._handlers[t] == null) {
      // TODO: error?
      print("INFO: ${this.ref} received a message ${pair.message} from ${pair.sender} but no handler is registered.");

      if (this._umbrella != null) {
        this._umbrella(pair.sender, pair.message);
      } else {
        print("WARNING: no umbrella registered");
      }
    } else {
      this._handlers[t](pair.sender, pair.message);
    }
  }
}


/// A blackhole
class DeadLetters extends Actor {

  void setUp() {}
  void tearDown() {}
  void handle(ActorRef sender, dynamic message) {}
}
