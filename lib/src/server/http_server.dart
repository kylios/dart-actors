part of server;

class HttpServer {

  String _bindAddr;
  int _port;

  io.HttpServer _server = null;
  StreamController<io.HttpRequest> _stream = null;

  HttpServer(this._bindAddr, this._port);

  /// Returns true if the server is currently listening
  bool get started => this._stream != null;

  /// Start listening for messages
  Future<Message> startServer() async {

    this._stream = new StreamController<io.HttpRequest>(); 

    // Bind to our port, then start listening on the socket and transform 
    // requests into system messages
    this._server = await io.HttpServer.bind(this._bindAddr, this._port);
    this._server.listen(this._processHttpRequest);
  }

  /// Stops the server listening
  Future stopServer() {
    this._server.close();
    this._stream.close();
    this._server = null;
    this._stream = null;
  }

  // Decodes the request as utf8 and joins all the chunks together
  Future<Message> _convertHttpRequest(io.HttpRequest request) => request.join();

  void _processHttpRequest(io.HttpRequest request) async {
    Message msg = await this._convertHttpRequest(request);
    this._stream.add(msg);
    MessageResponse res = new MessageResponse(Status.QUEUED);

    request.response.statusCode = 201; // CREATED
    request.response.close();
  }
}