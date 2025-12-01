defmodule Chess.GameSaver do
  @moduledoc "Handles saving and loading the move history."

  @default_filename "my_game.save"

  @doc "Saves the move list to a file."
  def save(move_history) do
    # :erlang.term_to_binary converts any Elixir term into binary data
    data = :erlang.term_to_binary(move_history)
    
    case File.write(@default_filename, data) do
      :ok ->
        IO.puts("Game saved to #{@default_filename}")
      {:error, reason} ->
        IO.puts("Error saving game: #{reason}")
    end
  end

  @doc "Loads a move list from a file."
  def load() do
    case File.read(@default_filename) do
      {:ok, data} ->
        # :erlang.binary_to_term converts the binary data back into an Elixir list
        # We use a 'try' block in case the file is corrupted
        try do
          move_history = :erlang.binary_to_term(data)
          {:ok, move_history}
        rescue
          _ -> {:error, :corrupted_file}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end
end