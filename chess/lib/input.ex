defmodule Chess.Input do
  @moduledoc "Handles player input."

  def get_move() do
    # 1. Update the prompt to show new commands
    input =
      IO.gets("Move (e.g. e2e4), 'q' (quit), 'undo', 'save', 'load', 'replay': ")
      |> String.trim()

    # 2. Add new command clauses
    cond do
      input == "q" ->
        :quit

      input == "undo" ->
        :undo

      input == "save" ->
        :save

      input == "load" ->
        :load

      input == "replay" ->
        :replay

      Regex.match?(~r/^[a-h][1-8][a-h][1-8]$/, input) ->
        <<f1, r1, f2, r2>> = input
        {:ok, {String.to_atom(<<f1, r1>>), String.to_atom(<<f2, r2>>)}}

      true ->
        :invalid
    end
  end
end