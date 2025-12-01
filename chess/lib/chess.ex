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

  def run() do
    IO.puts("Welcome to Elixir Chess!")
    minutes = choose_time_control()
    {game_mode, bot_depth} = choose_game_mode()
    game_state = %GameState{GameState.new(minutes) | game_mode: game_mode, bot_depth: bot_depth}
    loop(game_state)
  end

  defp loop(game_state) do
    case check_for_timeout(game_state) do
      {:game_over, :timeout, winner} ->
        Render.board(game_state)
        IO.puts("Time's up! #{winner} wins by timeout!")
        :ok

      :ok ->
        Render.board(game_state)

        # Determine if it's a human's turn or a bot's turn
        is_human_turn =
          case {game_state.game_mode, game_state.to_move} do
            {:pvp, _} -> true
            {:p_vs_bot_simple, :white} -> true
            {:p_vs_bot_minimax, :white} -> true
            _ -> false
          end

        if is_human_turn do
          handle_human_turn(game_state)
        else
          handle_bot_turn(game_state)
        end
    end
  end

  defp check_for_timeout(game_state) do
    # Note: We check the time for the player whose turn it *was* before the state flipped.
    cond do
      game_state.to_move == :white and game_state.black_time_left_ms <= 0 ->
        {:game_over, :timeout, :white}
      game_state.to_move == :black and game_state.white_time_left_ms <= 0 ->
        {:game_over, :timeout, :black}
      true ->
        :ok
    end
  end

  # --- Turn Handlers ---

  defp handle_bot_turn(game_state) do
    move_result =
      case game_state.game_mode do
        :p_vs_bot_simple -> Bot.choose_greedy_move(game_state)
        :p_vs_bot_minimax -> Bot.find_best_move(game_state, game_state.bot_depth)
      end
    
    Process.sleep(1000)
    # Bots always produce a full move, so we pass it directly to the command handler
    handle_command(game_state, move_result)
  end

  defp handle_human_turn(game_state) do
    case game_state.input_state do
      :awaiting_from ->
        prompt = "[#{game_state.to_move}] Select piece to move (e.g. e2): "
        handle_awaiting_from(game_state, prompt)
      {:awaiting_to, from_square} ->
        prompt = "[#{game_state.to_move}] Select destination for #{from_square} (or 'cancel'): "
        handle_awaiting_to(game_state, prompt, from_square)
    end
  end

  # --- Input State Handlers ---

  defp handle_awaiting_from(game_state, prompt) do
    case Input.get_square(prompt) do
      {:ok, from_square} ->
        case Map.get(game_state.board, from_square) do
          {color, _} when color == game_state.to_move ->
            # Valid piece selected, transition to next state and re-render
            loop(%{game_state | input_state: {:awaiting_to, from_square}})
          _ ->
            IO.puts("Invalid selection. Not your piece, or empty square.")
            Process.sleep(1500)
            loop(game_state)
        end
      command ->
        handle_command(game_state, command)
    end
  end

  defp handle_awaiting_to(game_state, prompt, from_square) do
    case Input.get_square(prompt) do
      {:ok, to_square} ->
        # We now have a complete move to evaluate
        handle_command(game_state, {:ok, {from_square, to_square}})
      :cancel ->
        # Reset state to awaiting 'from' selection
        loop(%{game_state | input_state: :awaiting_from})
      command ->
        handle_command(game_state, command)
    end
  end

  # --- Command Handler ---

  defp handle_command(game_state, command) do
    case command do
      {:ok, {from, to}} ->
        if Validator.is_legal_move?(game_state, from, to) do
          promotion_piece = if Validator.pawn_promotion?(game_state, from, to), do: choose_promotion_piece(), else: nil
          new_state = GameState.make_move(game_state, from, to, promotion_piece)
          # Reset input state for the next turn
          final_state = %{new_state | input_state: :awaiting_from}

          if Validator.checkmate?(final_state, final_state.to_move) do
            Render.board(final_state)
            winner = if final_state.to_move == :white, do: :black, else: :white
            IO.puts("Checkmate! #{winner} wins!")
            :ok
          else
            loop(final_state)
          end
        else
          IO.puts("--- Illegal move. Try again. ---")
          Process.sleep(1500)
          # Reset to select a 'from' square again
          loop(%{game_state | input_state: :awaiting_from})
        end
      :quit ->
        IO.puts("Game ended.")
        :ok
      :undo ->
        IO.puts("Undoing last move(s)...")
        moves_to_undo = if game_state.game_mode in [:p_vs_bot_simple, :p_vs_bot_minimax], do: 2, else: 1
        history_count = Enum.count(game_state.move_history)
        actual_moves_to_undo = min(moves_to_undo, history_count)

        if actual_moves_to_undo > 0 do
          new_history = Enum.slice(game_state.move_history, 0, history_count - actual_moves_to_undo)
          new_state = GameState.build_state_from_history(new_history, game_state)
          loop(new_state)
        else
          IO.puts("Nothing to undo.")
          loop(game_state)
        end
      :save ->
        GameSaver.save(game_state.move_history)
        IO.puts("Game saved.")
        Process.sleep(1000)
        loop(game_state)
      :load ->
        case GameSaver.load() do
          {:ok, history} ->
            new_state = GameState.build_state_from_history(history, game_state)
            IO.puts("Load successful.")
            loop(new_state)
          {:error, reason} ->
            IO.puts("Failed to load: #{reason}. Resuming game.")
            loop(game_state)
        end
      :replay ->
        IO.puts("Starting replay...")
        replay_game(game_state.move_history, game_state)
        IO.puts("Replay finished. Resuming game.")
        loop(game_state)
      :invalid ->
        IO.puts("Invalid command or square.")
        Process.sleep(1500)
        loop(game_state)
      _ ->
        loop(game_state)
    end
  end

  # (Helper functions for choosing things and replaying remain the same)
  defp replay_game(move_history, game_state) do
    initial_state = %{GameState.new(3) | game_mode: game_state.game_mode, bot_depth: game_state.bot_depth}
    Enum.reduce(move_history, initial_state, fn {from, to, promotion}, acc_state ->
      Render.board(acc_state)
      IO.puts("Move: #{from} to #{to}")
      Process.sleep(1000)
      GameState.make_move(acc_state, from, to, promotion)
    end)
    final_state = GameState.build_state_from_history(move_history, game_state)
    Render.board(final_state)
    Process.sleep(1000)
  end

  defp choose_promotion_piece() do
    IO.puts("Pawn promotion! Choose a piece: (1. Queen, 2. Rook, 3. Bishop, 4. Knight)")
    case IO.gets("Enter (1-4): ") |> String.trim() do
      "1" -> :queen
      "2" -> :rook
      "3" -> :bishop
      "4" -> :knight
      _ -> IO.puts("Invalid choice, defaulting to Queen."); :queen
    end
  end

  defp choose_time_control() do
    IO.puts("Choose time control.")
    prompt = "Enter time in minutes (1-15): "
    case IO.gets(prompt) |> String.trim() |> Integer.parse() do
      {minutes, ""} when minutes in 1..15 ->
        IO.puts("Time control set to #{minutes} minutes.")
        minutes
      _ ->
        IO.puts("Invalid input. Defaulting to 3 minutes.")
        3
    end
  end

  defp choose_game_mode() do
    IO.puts("Choose game mode: (1. PvP, 2. Player vs Simple Bot, 3. Player vs Minimax Bot)")
    case IO.gets("Enter (1-3): ") |> String.trim() do
      "1" -> {:pvp, nil}
      "2" -> {:p_vs_bot_simple, nil}
      "3" -> depth = choose_bot_depth(); {:p_vs_bot_minimax, depth}
      _ -> IO.puts("Invalid choice, defaulting to PvP."); {:pvp, nil}
    end
  end

  defp choose_bot_depth() do
    IO.puts("Choose Minimax Bot difficulty.")
    prompt = "Enter a search depth between 1 and 4 (higher is harder): "
    case IO.gets(prompt) |> String.trim() |> Integer.parse() do
      {depth, ""} when depth in 1..4 ->
        IO.puts("Bot depth set to #{depth}.")
        depth
      _ ->
        IO.puts("Invalid input. Defaulting to depth 2.")
        2
    end
  end
end