part of tictactoe;


class TakeTurn {}
class TurnOver {}

class GetBoard {}
class BoardLayout {
  final List<List<String>> board;
  BoardLayout(this.board);
}

class PlaceMark {
  final String symbol;
  final int row;
  final int col;
  PlaceMark(this.symbol, this.row, this.col);
}
class MarkPlaced {}
