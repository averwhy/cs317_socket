import gleam/io
import gleam/erlang.{get_line}
import gleam/bytes_tree
import gleam/bit_array
import gleam/result
import glisten/tcp

pub fn main() {
  let _server_name = "WhatTheSigma"
  let server_port = 12000
  
  // Connect to the server
  let assert Ok(connection) = tcp.listen(server_port, [])
  
  // Get user input
  io.print("")
  let sentence = get_line("Input lowercase sentence: ")
    |> result.unwrap("Error getting user input")  
  // Send data to server
  let data = bit_array.from_string(sentence)
  let bytes = bytes_tree.from_bit_array(data)
  let assert Ok(accepted_socket) = tcp.accept(connection)
  let assert Ok(_) = tcp.send(accepted_socket, bytes)
  
  // Receive data from server
  let assert Ok(response) = tcp.receive(accepted_socket, 1024)
  let assert Ok(modified_sentence) = bit_array.to_string(response)
  
  // Display the response
  io.println("From Server: " <> modified_sentence)
  
  // Close the connection
  let assert Ok(_) = tcp.close(connection)
}