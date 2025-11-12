defmodule Chess do
  @moduledoc """
  The main entry point for the application.
  """

  alias Chess.GameState
  alias Chess.Render
  alias Chess.Input
  alias Chess.Validator
  @doc """
  Starts the game.
  """
  def run() do
    IO.puts("Welcome to Elixir Chess!")

    minutes = choose_time_control()
    game_state = GameState.new(minutes)

    loop(game_state)
  end

  defp loop(game_state) do
    Render.board(game_state)
    IO.puts("It is #{game_state.to_move}'s turn.")
  case Input.get_move() do
        {:ok, {from, to}} ->

          if Validator.is_legal_move?(game_state, from, to) do
            promotion_piece =
              if Validator.pawn_promotion?(game_state, from, to) do
                choose_promotion_piece()
              else
                nil
              end 
            new_state = GameState.make_move(game_state, from, to, promotion_piece)
            if Validator.checkmate?(new_state, new_state.to_move) do
              Render.board(new_state)
              winner = if new_state.to_move == :white, do: :black, else: :white
              IO.puts("Checkmate! #{winner} wins!")
              :ok
            else
              loop(new_state)
            end
          else
            IO.puts("--- Illegal move. Try again. ---")
            loop(game_state)
          end

        :quit ->
          IO.puts("Game ended.")
          :ok

        :invalid ->
          IO.puts("Invalid input. Try again.")
          loop(game_state)
      end
    end

  defp choose_promotion_piece() do
    IO.puts("Pawn promotion! Choose a piece:")
    IO.puts("  1. Queen")
    IO.puts("  2. Rook")
    IO.puts("  3. Bishop")
    IO.puts("  4. Knight")

    case IO.gets("Enter (1-4): ") |> String.trim() do
      "1" -> :queen
      "2" -> :rook
      "3" -> :bishop
      "4" -> :knight
      _ ->
        IO.puts("Invalid choice, defaulting to Queen.")
        :queen
    end
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
