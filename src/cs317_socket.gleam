import gleam/erlang/process
import gleam/io
import gleam/int
import gleam/string
import gleam/erlang.{get_line}
import gleam/bytes_tree
import gleam/bit_array
import gleam/result
import glisten/tcp
import glisten/socket
import glisten/socket/options

const port = 12000

/// Listens passively for a message from the client
fn server() -> Result(String, socket.SocketReason) {
  io.println("Listening for a message from the client...")
  use listener <- result.then(tcp.listen(port, [options.ActiveMode(options.Passive)]))
  use socket <- result.then(tcp.accept(listener))
  use msg <- result.then(tcp.receive(socket, 0))
  let assert Ok(msg) = bit_array.to_string(msg)
  Ok(msg)
}

/// Sends a message to the server
fn client(to_add: Int){
  use listener <- result.then(tcp.listen(port, [options.ActiveMode(options.Passive)]))
  use socket <- result.then(tcp.accept(listener))
  tcp.send(socket, bytes_tree.from_string(int.to_string(to_add)))
}

pub fn main() {
  
  // Get user input
  let sentence = get_line("Input amount to add by:")
    |> result.unwrap("Error getting user input")
  // Send data to server
  process.start(server, True)
  //process.start(client(int.parse(sentence)), True)

  Ok(Nil)
}