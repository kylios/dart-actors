library server;


import 'dart:io' as io;
import 'dart:async';

import 'package:actors/actors.dart';

part 'src/server/http_server.dart';

/// # Summary
/// 
/// The server component of an actor system receives commands and forwards them
/// to the actor system.  This layer abstracts the act of receiving and
/// forwarding commands.  The server can implement various interfaces such as
/// HTTP over TCP or unix fifo servers.  Commands will have several different 
/// properties, similar to HTTP requests, including a path, headers, and a
/// request method.
/// 
/// # Command Structure:
///
/// > enum Method {
/// >     GET,
/// >     POST
/// > };
/// >
/// > class Header {
/// >     String name,
/// >     String value
/// > };
/// >
/// > class Message {
/// >     enum Method method,
/// >     repeated Header headers,
/// >     repeated byte content
/// > };
/// 
/// Commands of this structure will be queued up and sent to the ActorSystem
/// asynchronously.  The server's response to the client will only indicate 
/// whether the message was successfully queued or not.

enum Method {
  GET,
  POST
}

class Header {
  String key;
  String value;
}

class Message {
  final Method method;
  final List<Header> headers;
  final String content;

  Message(this.method, this.headers, this.content);
}

enum Status {
  // A message was queued for the actor system
  QUEUED,
  // The request succeeded, check the response
  OK,
  // The request failed due to an error
  FAILED,
  // The request could not be fulfilled due to a client error
  REJECTED
}

class Error {
  final String message;

  Error(this.message);
}

class MessageResponse {
  final Status status;
  final Error error;
  final String content;
  
  MessageResponse(this.status, [this.content = null, this.error = null]);
}

abstract class Server {

  Future<Stream<Message>> startServer();
  Future stopServer();
  bool get started;
}
