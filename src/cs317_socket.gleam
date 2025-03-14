import gleam/bit_array
import gleam/erlang.{get_line}
import gleam/erlang/atom
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/result
import mug

const port = 12_000

const host = "localhost"

/// Listens passively for a message from the client
fn server(main_subject) -> Result(String, Nil) {
  io.println("Listening for a message from the client...")
  let assert Ok(socket) =
    mug.new(host, port: port)
    |> mug.timeout(milliseconds: 500)
    |> mug.connect()
  let assert Ok(response) = mug.receive(socket, 30_000)
  let assert Ok(msg) = bit_array.to_string(response)
  process.send(main_subject, msg)
  // send back to main process
  Ok(msg)
}

/// Sends a message to the server
fn client(to_add: Int) {
  let assert Ok(socket) =
    mug.new(host, port: port)
    |> mug.timeout(milliseconds: 500)
    |> mug.connect()
  let msg =
    to_add
    |> int.to_string
    |> bit_array.from_string
  mug.send(socket, msg)
}

pub fn main() {
  // Get user input
  let sentence =
    get_line("Input amount to add by:")
    |> result.unwrap("Error getting user input")
  let main_subject = process.new_subject()
  // Send data to server
  let server_pid = process.start(fn() { server(main_subject) }, True)
  let _ = process.register(server_pid, atom.create_from_string("server"))
  let parsed_amount = int.parse(sentence) |> result.unwrap(0)
  process.start(fn() { client(parsed_amount) }, True)
  // now that the client server is spawned, we can wait for the response from the server
  let assert Ok(response) = process.receive(main_subject, 30_000)
  io.println("Response from server: " <> response)
  Ok(Nil)
}
