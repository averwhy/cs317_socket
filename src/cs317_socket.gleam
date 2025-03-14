import gleam/erlang/process
import gleam/erlang/atom
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
fn server(main_subject) -> Result(String, socket.SocketReason) {
  io.println("Listening for a message from the client...")
  use listener <- result.then(tcp.listen(port, [options.ActiveMode(options.Passive)]))
  use socket <- result.then(tcp.accept(listener))
  use msg <- result.then(tcp.receive(socket, 0))
  let assert Ok(msg) = bit_array.to_string(msg)
  process.send(main_subject, msg) // send back to main process
  Ok(msg)
}

/// Sends a message to the server
fn client(to_add: Int) {
  use listener <- result.then(tcp.listen(port, [options.ActiveMode(options.Passive)]))
  use socket <- result.then(tcp.accept(listener))
  tcp.send(socket, bytes_tree.from_string(int.to_string(to_add)))
}

pub fn main() {
  // Get user input
  let sentence = get_line("Input amount to add by:")
    |> result.unwrap("Error getting user input")
  let main_subject = process.new_subject()
  // Send data to server
  let server_pid = process.start(fn () { server(main_subject) }, True)
  let _ = process.register(server_pid, atom.create_from_string("server"))
  let parsed_amount = int.parse(sentence) |> result.unwrap(0)
  process.start(fn() { client(parsed_amount) }, True)
  // now that the client server is spawned, we can wait for the response from the server
  let assert Ok(response) = process.receive(main_subject, 30000)
  io.println("Response from server: " <> response)
  Ok(Nil)
}