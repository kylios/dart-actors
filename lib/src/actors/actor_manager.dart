part of actors;


/// Defines an interface for the management of actors.
abstract class ActorManager {

  // Lookup actor by path, could include forwarding that lookup to other actors
  Map<String, ActorRef> _actors = new Map<String, ActorRef>();

  ActorSystem get _system;
  String get _path;

  ActorStats get stats;


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


  ActorRef _lookup(String path) {
    ActorRef ref = this._actors[path];
    if (ref == null) {
      return null;
    }
    if (path == this._path) {
      return this._ref;
    } else {
      return ref._actor._lookup(
        path.relative(this._ref.path, from: this._path));
    }
  }


  // Add actor
  Future<ActorRef> _addActor(Actor a, String actorName, ActorProps props) {
    print("System: _addActor(name=$actorName)");
    this.stats.increment('actors.begin_add');

    String pth = path.join(this._path, actorName);
    return a._setUp(this._system, actorName, pth, props)
      .then((_) {
          print("System: adding ${a.ref}");
          this._actors[pth] = a.ref;
          this.stats.increment('actors.end_add');
          return a.ref;
        });
  }


  // Remove actor
  Future _removeActor(Actor a) async {
    this.stats.increment('actors.begin_remove');

    await a._tearDown();

    this._actors.remove(a.ref.path);
    this.stats.increment('actors.end_remove');

    return new Future.value(null);
  }


  // Kill all actors
  void _killAllActors() => this.broadcast(DefaultMessages.KILL);


  // Wait for actors
  Future get _actorsDone => Future.wait(this._actors.values.map((v) => v.done));

  // Broadcast to actors
  void broadcast(String message) => 
    this._actors.forEach((String path, ActorRef ref) => 
      this._system.sendMessage(ref, message));
}