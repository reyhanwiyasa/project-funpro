defmodule Chess.Evaluator do
  @moduledoc """
  The 'Analyst' module.
  Calculates a static score for a given board state.
  """

  # --- 1. MATERIAL VALUES (Make sure these are included!) ---
  @pawn_value 10
  @knight_value 30
  @bishop_value 30
  @rook_value 50
  @queen_value 90
  @king_value 900

  @doc """
  Calculates the total score of the board.
  """
  def evaluate(%Chess.GameState{board: board}) do
    # We start with a score of 0
    Enum.reduce(board, 0, fn {_square, {color, type}}, current_score ->

      # 1. Calculate material value (Safe check)
      material_score = get_piece_value(type)

      # 2. Calculate positional bonus
      position_score = get_positional_bonus(type, _square, color)

      total_piece_value = material_score + position_score

      # 3. Update the running score
      # IMPORTANT: This block MUST return an integer, never nil
      if color == :white do
        current_score + total_piece_value
      else
        current_score - total_piece_value
      end
    end)
  end

  # --- HELPER: Material Score ---
  # Ensure every single piece type is listed here
  defp get_piece_value(:pawn), do: @pawn_value
  defp get_piece_value(:knight), do: @knight_value
  defp get_piece_value(:bishop), do: @bishop_value
  defp get_piece_value(:rook), do: @rook_value
  defp get_piece_value(:queen), do: @queen_value
  defp get_piece_value(:king), do: @king_value

  # CATCH-ALL: If the type is unknown, return 0 (Prevents 'nil' errors)
  defp get_piece_value(_), do: 0

  # --- HELPER: Positional Bonus ---
  # Simple center control bonus
  defp get_positional_bonus(_, square, _) when square in [:d4, :e4, :d5, :e5] do
    2
  end

  defp get_positional_bonus(_, square, _) when square in [:c3, :d3, :e3, :f3,
                                                          :c4, :f4, :c5, :f5,
                                                          :c6, :d6, :e6, :f6] do
    1
  end

  # Catch-all for any other square
  defp get_positional_bonus(_type, _square, _color) do
    0
  end
end
