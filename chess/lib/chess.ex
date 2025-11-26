defmodule Chess do
  @moduledoc """
  The main entry point for the application.
  """

  alias Chess.GameState
  alias Chess.Render
  alias Chess.Input
  alias Chess.Validator
  alias Chess.GameSaver
  alias Chess.Bot

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
    move_result =
      if game_state.to_move == :white do
        Input.get_move()
      else
        Process.sleep(1000)
        Chess.Bot.choose_move(game_state)
      end

  case move_result do
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

        :undo ->
          IO.puts("Undoing last move...")
          # 1. Get history and remove the last move
          new_history = List.delete_at(game_state.move_history, -1)
          # 2. Call Person A's "engine"
          new_state = GameState.build_state_from_history(new_history)
          # 3. Loop with the previous state
          loop(new_state)

        :save ->
          # 1. Get the history from the state
          history = game_state.move_history
          # 2. Call your new GameSaver
          GameSaver.save(history)
          # 3. Continue the game
          loop(game_state)

        :load ->
          IO.puts("Loading game...")
          # 1. Call your GameSaver to read the file
          case GameSaver.load() do
            {:ok, history} ->
              # 2. Call Person A's "engine" to build the state
              new_state = GameState.build_state_from_history(history)
              IO.puts("Load successful.")
              # 3. Loop with the loaded state
              loop(new_state)
            {:error, reason} ->
              IO.puts("Failed to load: #{reason}. Resuming game.")
              loop(game_state)
          end

        :replay ->
          IO.puts("Starting replay...")
          # Call the new replay helper function
          replay_game(game_state.move_history)
          IO.puts("Replay finished. Resuming game.")
          # Loop with the original state to continue playing
          loop(game_state)

        :invalid ->
          IO.puts("Invalid input. Try again.")
          loop(game_state)
      end
    end

  @doc "Loops through a move history and displays each step."
  defp replay_game(move_history) do
    # Start with a new game
    initial_state = GameState.new(3) # 3-min default

    # Use Enum.reduce to "play" the game, but we also render
    # `acc_state` is the "accumulated" state (the game board)
    Enum.reduce(move_history, initial_state, fn {from, to, promotion}, acc_state ->
      # Render the current state
      Render.board(acc_state)
      IO.puts("Move: #{from} to #{to}")
      # Wait for 1 second
      Process.sleep(1000)

      # Call make_move to get the *next* state for the next loop
      GameState.make_move(acc_state, from, to, promotion)
    end)

    # After the loop, render the final board
    final_state = GameState.build_state_from_history(move_history)
    Render.board(final_state)
    Process.sleep(1000)
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
