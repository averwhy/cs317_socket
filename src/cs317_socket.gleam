import gleam/bit_array
import gleam/erlang.{get_line}
import gleam/erlang/process
import gleam/io
import gleam/result
import gleam/string
import glisten/socket
import glisten/socket/options.{ActiveMode, Passive}
import glisten/tcp
import mug

const port = 12_000
const host = "localhost"

/// Listens passively for a message from the client
fn server(main_subject) -> Result(String, socket.SocketReason) {
  use listener <- result.then(tcp.listen(port, [ActiveMode(Passive)]))
  use socket <- result.then(tcp.accept(listener))
  use msg <- result.then(tcp.receive(socket, 0))
  let assert Ok(msg) = bit_array.to_string(msg)
  // send back the modified message to main process
  let new_msg = string.reverse(msg)
  process.send(main_subject, new_msg)
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

  // By making a subject in the main process, and passing it 
  // to the server, it can send stuff back to the main thread
  let main_subject = process.new_subject()

  // Start the server and client processes
  process.start(fn() { server(main_subject) }, True)
  process.start(fn() { client(sentence) }, True)
  
  // Wait 30s for the server to return its modified message
  let assert Ok(response) = process.receive(main_subject, 30_000)
  io.println("Response from server: " <> response)
  Ok(Nil)
}
