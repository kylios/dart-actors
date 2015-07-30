part of tictactoe;

abstract class Player extends Actor {

  final String _symbol;
  final ActorRef _gameController;
  final ActorRef _board;

  Player(self._symbol, self._gameController, self._board);

  void setUp() {
    // nuthin
  }

  void tearDown() {
    // nuthin
  }

  void handle(ActorRef sender, dynamic message) {

    if (message is TakeTurn) {
      this.sendMessage(this._board, new GetBoard());

    } else if (message is BoardLayout) {
      var move = this._findMove(message.board);
      self.sendMessage(self._board, 
        new PlaceMark(this._symbol, move.row, move.col));
    } else if (message is MarkPlaced) {

    }
  }
}