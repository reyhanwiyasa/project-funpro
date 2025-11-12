defmodule Chess.Input do
  @moduledoc "Handles player input."

  def get_move() do
    input =
      IO.gets("Your move (e.g. e2e4, or 'q' to quit): ")
      |> String.trim()

    cond do
      input == "q" ->
        :quit

      Regex.match?(~r/^[a-h][1-8][a-h][1-8]$/, input) ->
        <<f1, r1, f2, r2>> = input
        {:ok, {String.to_atom(<<f1, r1>>), String.to_atom(<<f2, r2>>)}}

      true ->
        :invalid
    end
  end
end
