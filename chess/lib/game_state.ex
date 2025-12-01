defmodule Chess.GameState do
  @moduledoc "Holds the entire state of the game."
  alias Chess.Validator

  defstruct [
    :board,
    :to_move,
    :white_time_left_ms,
    :black_time_left_ms,
    :turn_started_at,
    :en_passant_target,
    white_can_castle_kingside: true,
    white_can_castle_queenside: true,
    black_can_castle_kingside: true,
    black_can_castle_queenside: true,
    move_history: [],
    game_mode: :pvp, # :pvp, :p_vs_bot_simple, :p_vs_bot_minimax
    bot_depth: 2,
    input_state: :awaiting_from # :awaiting_from | {:awaiting_to, from_square}
  ]

  def new(start_minutes) do
    total_ms = start_minutes * 60 * 1000

    %__MODULE__{
      board: initial_board(),
      to_move: :white,
      white_time_left_ms: total_ms,
      black_time_left_ms: total_ms,
      turn_started_at: System.monotonic_time(:millisecond),
      en_passant_target: nil,
      game_mode: :pvp,
      bot_depth: 2,
      input_state: :awaiting_from
    }
  end

  def make_move(%__MODULE__{} = state, from, to, promotion_piece \\ nil) do
      time_spent_ms = System.monotonic_time(:millisecond) - state.turn_started_at
      
      {new_white_time, new_black_time} = 
        case state.to_move do
          :white -> {state.white_time_left_ms - time_spent_ms, state.black_time_left_ms}
          :black -> {state.white_time_left_ms, state.black_time_left_ms - time_spent_ms}
        end

      piece = Map.get(state.board, from)

      new_board = execute_move_and_handle_en_passant(state, piece, from, to, promotion_piece)
      new_en_passant_target = get_new_en_passant_target(piece, from, to)

      state = update_castling_rights(state, from, piece)
      move_to_store = {from, to, promotion_piece}
      new_history = state.move_history ++ [move_to_store]

      %__MODULE__{
        state
        | board: new_board,
          to_move: toggle_turn(state.to_move),
          white_time_left_ms: new_white_time,
          black_time_left_ms: new_black_time,
          turn_started_at: System.monotonic_time(:millisecond),
          en_passant_target: new_en_passant_target,
          move_history: new_history
      }
    end

  @doc """
  Builds a complete game state by replaying a list of moves.
  Starts from a fresh board.
  """
  def build_state_from_history(moves_list, current_game_state) do
    # Create a new state, but preserve the game mode and bot settings from the current state.
    initial_state = %{new(3) | 
      game_mode: current_game_state.game_mode, 
      bot_depth: current_game_state.bot_depth
    }

    # Use Enum.reduce to "play" the game from the start
    # `acc_state` is the "accumulated" state (the game board)
    Enum.reduce(moves_list, initial_state, fn {from, to, promotion}, acc_state ->
      # Call make_move on the current state to get the next state
      make_move(acc_state, from, to, promotion)
    end)
  end

    defp update_castling_rights(state, from, {color, piece_type}) do
      case {color, piece_type, from} do
        {:white, :king, _} ->
          %{state | white_can_castle_kingside: false, white_can_castle_queenside: false}
        {:black, :king, _} ->
          %{state | black_can_castle_kingside: false, black_can_castle_queenside: false}
        {:white, :rook, :h1} ->
          %{state | white_can_castle_kingside: false}
        {:white, :rook, :a1} ->
          %{state | white_can_castle_queenside: false}
        {:black, :rook, :h8} ->
          %{state | black_can_castle_kingside: false}
        {:black, :rook, :a8} ->
          %{state | black_can_castle_queenside: false}
        _ ->
          state
      end
    end
    defp execute_move_and_handle_en_passant(state, piece, from, to, promotion_piece) do
      {_color, piece_type} = piece
      if piece_type == :king do
        {from_file, from_rank} = Chess.Validator.to_coords(from)
        {to_file, _to_rank} = Chess.Validator.to_coords(to)
        delta_file = abs(to_file - from_file)
        if delta_file == 2 do
          {rook_from, rook_to} =
            if to_file > from_file do
              {
                String.to_atom("h" <> Integer.to_string(from_rank)),  # rook from h1/h8
                String.to_atom("f" <> Integer.to_string(from_rank))   # rook to f1/f8
              }
            else
              {
                String.to_atom("a" <> Integer.to_string(from_rank)),  # rook from a1/a8
                String.to_atom("d" <> Integer.to_string(from_rank))   # rook to d1/d8
              }
            end
          rook_piece = Map.get(state.board, rook_from)

          state.board
          |> Map.delete(from)
          |> Map.delete(rook_from)
          |> Map.put(to, piece)
          |> Map.put(rook_to, rook_piece)
        else
          execute_standard_or_en_passant_move(state, piece, from, to, promotion_piece)
        end
      else
        execute_standard_or_en_passant_move(state, piece, from, to, promotion_piece)
      end
    end


    defp execute_standard_or_en_passant_move(state, piece, from, to, promotion_piece) do
      is_en_passant = (elem(piece, 1) == :pawn) &&
                      (to == state.en_passant_target) &&
                      (Map.get(state.board, to) == nil)
      new_board =
        if is_en_passant do
          {_to_file_num, to_rank_num} = Chess.Validator.to_coords(to)
          to_file_str = to |> Atom.to_string() |> String.at(0)

          captured_pawn_rank = if state.to_move == :white, do: to_rank_num - 1, else: to_rank_num + 1
          captured_pawn_square = String.to_atom(to_file_str <> Integer.to_string(captured_pawn_rank))

          state.board
          |> Map.delete(from)
          |> Map.delete(captured_pawn_square)
          |> Map.put(to, piece)
        else
          state.board
          |> Map.delete(from)
          |> Map.put(to, piece)
        end
      {_color, piece_type} = piece
      {_to_file, to_rank} = Chess.Validator.to_coords(to)
      cond do
        piece_type == :pawn and state.to_move == :white and to_rank == 8 ->
          promoted = promotion_piece || :queen
          Map.put(new_board, to, {:white, promoted })

        piece_type == :pawn and state.to_move == :black and to_rank == 1 ->
          promoted = promotion_piece || :queen
          Map.put(new_board, to, {:black, promoted})

        true ->
          new_board
      end
    end



    defp get_new_en_passant_target(piece, from, to) do
      {_piece_color, piece_type} = piece
      {_from_file, from_rank} = Validator.to_coords(from)
      {_to_file, to_rank} = Validator.to_coords(to)

      rank_diff = abs(to_rank - from_rank)

      if piece_type == :pawn && rank_diff == 2 do
        Validator.get_in_between_square(from, to)
      else
        nil
      end
    end
  defp toggle_turn(:white), do: :black
  defp toggle_turn(:black), do: :white

  defp initial_board() do
    %{
      a1: {:white, :rook},
      b1: {:white, :knight},
      c1: {:white, :bishop},
      d1: {:white, :queen},
      e1: {:white, :king},
      f1: {:white, :bishop},
      g1: {:white, :knight},
      h1: {:white, :rook},
      a2: {:white, :pawn},
      b2: {:white, :pawn},
      c2: {:white, :pawn},
      d2: {:white, :pawn},
      e2: {:white, :pawn},
      f2: {:white, :pawn},
      g2: {:white, :pawn},
      h2: {:white, :pawn},

      a8: {:black, :rook},
      b8: {:black, :knight},
      c8: {:black, :bishop},
      d8: {:black, :queen},
      e8: {:black, :king},
      f8: {:black, :bishop},
      g8: {:black, :knight},
      h8: {:black, :rook},
      a7: {:black, :pawn},
      b7: {:black, :pawn},
      c7: {:black, :pawn},
      d7: {:black, :pawn},
      e7: {:black, :pawn},
      f7: {:black, :pawn},
      g7: {:black, :pawn},
      h7: {:black, :pawn}
    }
  end
end
