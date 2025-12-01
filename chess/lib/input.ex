defmodule Chess.Input do
  @moduledoc """
  Handles player input, including move selection and commands.
  """

  @doc """
  Gets a single square from the user (e.g., "e4").
  Also handles special commands like 'quit' or 'undo'.
  Returns:
  - `{:ok, :a1}` for a valid square
  - `:quit`, `:undo`, etc. for commands
  - `:invalid` for anything else
  """
  def get_square(prompt) do
    input = IO.gets(prompt) |> String.trim()

    cond do
      input == "q" or input == "quit" ->
        :quit
      input == "undo" ->
        :undo
      input == "save" ->
        :save
      input == "load" ->
        :load
      input == "replay" ->
        :replay
      # Special command to cancel selection
      input == "cancel" ->
        :cancel
      Regex.match?(~r/^[a-h][1-8]$/, input) ->
        {:ok, String.to_atom(input)}
      true ->
        :invalid
    end
  end
end
