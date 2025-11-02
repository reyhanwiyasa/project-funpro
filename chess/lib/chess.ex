defmodule Chess do
  @moduledoc """
  The main entry point for the application.
  """

  # We need both of your modules
  alias Chess.GameState
  alias Chess.Render

  # We can comment out the alias for Person B's code
  # alias Chess.Game

  @doc """
  Starts the game and renders the initial board.
  """
  def run() do
    IO.puts("Welcome to Elixir Chess!")

    # --- 1. Choose Time ---
    minutes = choose_time_control()

    # --- 2. Create the State ---
    game_state = GameState.new(minutes)

    # --- 3. Render the Board (Your Code) ---
    # Instead of calling Game.run, we just call Render.board
    IO.puts("Rendering initial board...")
    Render.board(game_state)

    # The program will now exit, which is perfect for testing.
  end

  defp choose_time_control() do
    IO.puts("Choose time control:")
    IO.puts("  1. 1 Minute")
    IO.puts("  2. 3 Minutes")
    IO.puts("  3. 5 Minutes")

    case IO.gets("Enter (1, 2, or 3): ") |> String.trim() do
      "1" -> 1
      "2" -> 3
      "3" -> 5
      _ ->
        IO.puts("Invalid choice, defaulting to 3 minutes.")
        3
    end
  end
end
