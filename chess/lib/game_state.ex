defmodule Chess.GameState do
  @moduledoc "Holds the entire state of the game."
  alias Chess.Validator

  defstruct [
    :board,
    :to_move,
    :white_time_left_ms,
    :black_time_left_ms,
    :turn_started_at,
    :en_passant_target
  ]

  def new(start_minutes) do
    total_ms = start_minutes * 60 * 1000

    %__MODULE__{
      board: initial_board(),
      to_move: :white,
      white_time_left_ms: total_ms,
      black_time_left_ms: total_ms,
      turn_started_at: System.monotonic_time(:millisecond),
      en_passant_target: nil
    }
  end

  def make_move(%__MODULE__{} = state, from, to) do
      piece = Map.get(state.board, from)

      new_board = execute_move_and_handle_en_passant(state, piece, from, to)
      new_en_passant_target = get_new_en_passant_target(piece, from, to)

      %__MODULE__{
        state
        | board: new_board,
          to_move: toggle_turn(state.to_move),
          turn_started_at: System.monotonic_time(:millisecond),
          en_passant_target: new_en_passant_target
      }
    end
    defp execute_move_and_handle_en_passant(state, piece, from, to) do
      is_en_passant = (elem(piece, 1) == :pawn) &&
                      (to == state.en_passant_target) &&
                      (Map.get(state.board, to) == nil)

      if is_en_passant do
        {_to_file_num, to_rank_num} = Validator.to_coords(to)
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
