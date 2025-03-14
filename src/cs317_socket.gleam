import glisten/socket
import gleam/bit_array
import gleam/erlang.{get_line}
import gleam/erlang/atom
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/result
import glisten/tcp
import glisten/socket/options.{ActiveMode, Passive}
import mug

const port = 12_000

const host = "localhost"

/// Listens passively for a message from the client
fn server(main_subject) -> Result(String, socket.SocketReason) {
  io.println("Listening for a message from the client...")
  use listener <- result.then(tcp.listen(port, [ActiveMode(Passive)]))
  use socket <- result.then(tcp.accept(listener))
  use msg <- result.then(tcp.receive(socket, 0))
  let assert Ok(msg) = bit_array.to_string(msg)
  // send back to main process
  process.send(main_subject, msg)
  Ok(msg)
}

/// Sends a message to the server
fn client(to_add: String) {
  let assert Ok(socket) =
    mug.new(host, port: port)
    |> mug.timeout(milliseconds: 500)
    |> mug.connect()
  // Send a packet to the server
  let assert Ok(Nil) = mug.send(socket, <<to_add:utf8>>)
}

pub fn main() {
  // Get user input
  let sentence =
    get_line("Input message:")
    |> result.unwrap("Error getting user input")
  let main_subject = process.new_subject()
  // Send data to server
  let server_pid = process.start(fn() { server(main_subject) }, True)
  let _ = process.register(server_pid, atom.create_from_string("server"))
  process.start(fn() { client(sentence) }, True)
  // now that the client server is spawned, we can wait for the response from the server
  let assert Ok(response) = process.receive(main_subject, 30_000)
  io.println("Response from server: " <> response)
  Ok(Nil)
}
