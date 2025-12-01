defmodule Chess.Evaluator do
  @moduledoc """
  The 'Analyst' module.
  Calculates a static score for a given board state.
  """

  # --- 1. MATERIAL VALUES ---
  @pawn_value 10
  @knight_value 30
  @bishop_value 30
  @rook_value 50
  @queen_value 90
  @king_value 900

  # --- 2. STRUCTURE PENALTIES/BONUSES ---
  @doubled_pawn_penalty -5
  @isolated_pawn_penalty -3
  @passed_pawn_bonus [0, 5, 10, 20, 35, 60, 100, 0] # Bonus by rank (1-8)
  @king_shield_bonus 4

  @doc """
  Calculates the total score of the board.
  """
  def evaluate(%Chess.GameState{board: board}) do
    # 0. Determine game phase
    game_phase = get_game_phase(board)

    # 1. Calculate base score from material and piece-square table bonuses
    base_score =
      Enum.reduce(board, 0, fn {square, {color, type}}, current_score ->
        material_score = get_piece_value(type)
        position_score = get_positional_bonus(type, square, color, game_phase)
        total_piece_value = material_score + position_score

        if color == :white do
          current_score + total_piece_value
        else
          current_score - total_piece_value
        end
      end)

    # 2. Add structural evaluations
    doubled_pawns_white = evaluate_doubled_pawns(board, :white)
    doubled_pawns_black = evaluate_doubled_pawns(board, :black)
    isolated_pawns_white = evaluate_isolated_pawns(board, :white)
    isolated_pawns_black = evaluate_isolated_pawns(board, :black)
    passed_pawns_white = evaluate_passed_pawns(board, :white)
    passed_pawns_black = evaluate_passed_pawns(board, :black)
    king_safety_white = evaluate_king_pawn_shield(board, :white)
    king_safety_black = evaluate_king_pawn_shield(board, :black)

    # 3. Final score is base + all bonuses/penalties
    base_score
    |> Kernel.+(doubled_pawns_white)
    |> Kernel.-(doubled_pawns_black)
    |> Kernel.+(isolated_pawns_white)
    |> Kernel.-(isolated_pawns_black)
    |> Kernel.+(passed_pawns_white)
    |> Kernel.-(passed_pawns_black)
    |> Kernel.+(king_safety_white)
    |> Kernel.-(king_safety_black)
  end

  # --- KING SAFETY HELPERS ---
  defp evaluate_king_pawn_shield(board, color) do
    case Enum.find(board, fn {_sq, {c, t}} -> c == color and t == :king end) do
      nil ->
        0 # Should not happen in a valid game
      {king_square, _} ->
        {king_file, king_rank} = parse_square(king_square)
        shield_rank = if color == :white, do: king_rank + 1, else: king_rank - 1
        return_early = if color == :white, do: king_rank > 2, else: king_rank < 7

        if return_early do
          0
        else
          [-1, 0, 1]
          |> Enum.reduce(0, fn file_offset, acc ->
            shield_file = king_file + file_offset
            if shield_file >= 0 and shield_file <= 7 do
              shield_square = to_square_atom({shield_file, shield_rank})
              if board[shield_square] == {color, :pawn}, do: acc + @king_shield_bonus, else: acc
            else
              acc
            end
          end)
        end
    end
  end

  # --- PAWN STRUCTURE HELPERS ---
  defp evaluate_doubled_pawns(board, color) do
    board
    |> Enum.filter(fn {_sq, {c, type}} -> c == color and type == :pawn end)
    |> Enum.map(fn {square, _} -> to_string(square) |> String.first() end)
    |> Enum.frequencies()
    |> Enum.reduce(0, fn {_file, count}, acc ->
      if count > 1, do: acc + @doubled_pawn_penalty * (count - 1), else: acc
    end)
  end

  defp evaluate_isolated_pawns(board, color) do
    pawn_locations =
      board
      |> Enum.filter(fn {_sq, {c, type}} -> c == color and type == :pawn end)
      |> Enum.map(fn {square, _} -> to_string(square) |> String.first() end)

    pawn_files_with_counts = Enum.frequencies(pawn_locations)
    pawn_files_set = MapSet.new(Map.keys(pawn_files_with_counts))

    pawn_files_set
    |> Enum.reduce(0, fn file, acc ->
      file_char = String.to_charlist(file) |> List.first()
      prev_file = to_string([file_char - 1])
      next_file = to_string([file_char + 1])
      is_isolated = not (MapSet.member?(pawn_files_set, prev_file) or MapSet.member?(pawn_files_set, next_file))
      if is_isolated, do: acc + (@isolated_pawn_penalty * pawn_files_with_counts[file]), else: acc
    end)
  end

  defp evaluate_passed_pawns(board, color) do
    friendly_pawns = Enum.filter(board, fn {_sq, {c, t}} -> c == color and t == :pawn end)
    opponent_color = if color == :white, do: :black, else: :white
    opponent_pawns = Enum.filter(board, fn {_sq, {c, t}} -> c == opponent_color and t == :pawn end)
    opponent_pawn_positions = Enum.map(opponent_pawns, fn {sq, _} -> parse_square(sq) end)

    Enum.reduce(friendly_pawns, 0, fn {square, _}, acc ->
      {file, rank} = parse_square(square)
      is_passed =
        not Enum.any?(opponent_pawn_positions, fn {opp_file, opp_rank} ->
          is_on_threatening_file = abs(opp_file - file) <= 1
          is_in_front = if color == :white, do: opp_rank > rank, else: opp_rank < rank
          is_on_threatening_file and is_in_front
        end)

      if is_passed do
        bonus_rank = if color == :white, do: rank, else: 9 - rank
        acc + (Enum.at(@passed_pawn_bonus, bonus_rank - 1) || 0)
      else
        acc
      end
    end)
  end

  # --- GENERAL HELPERS ---
  defp parse_square(square_atom) do
    [file_char, rank_char] = to_string(square_atom) |> String.to_charlist()
    file_index = file_char - ?a
    rank_index = rank_char - ?1 + 1
    {file_index, rank_index}
  end

  defp to_square_atom({file_index, rank_index}) do
    file_char = ?a + file_index
    rank_char = ?1 + rank_index - 1
    String.to_atom("#{<<file_char>>}#{<<rank_char>>}")
  end

  defp get_game_phase(board) do
    has_queens = Enum.any?(board, fn {_, {_, type}} -> type == :queen end)
    if has_queens, do: :middlegame, else: :endgame
  end

  # --- GET VALUE HELPERS ---
  defp get_piece_value(:pawn), do: @pawn_value
  defp get_piece_value(:knight), do: @knight_value
  defp get_piece_value(:bishop), do: @bishop_value
  defp get_piece_value(:rook), do: @rook_value
  defp get_piece_value(:queen), do: @queen_value
  defp get_piece_value(:king), do: @king_value
  defp get_piece_value(_), do: 0 # Fallback

  # --- Piece-Square Tables (Maps) ---
  @pawn_pst_white %{a8: 0, b8: 0, c8: 0, d8: 0, e8: 0, f8: 0, g8: 0, h8: 0, a7: 10, b7: 10, c7: 10, d7: 10, e7: 10, f7: 10, g7: 10, h7: 10, a6: 2, b6: 2, c6: 4, d6: 6, e6: 6, f6: 4, g6: 2, h6: 2, a5: 1, b5: 1, c5: 2, d5: 5, e5: 5, f5: 2, g5: 1, h5: 1, a4: 0, b4: 0, c4: 0, d4: 4, e4: 4, f4: 0, g4: 0, h4: 0, a3: 1, b3: -1, c3: -2, d3: 0, e3: 0, f3: -2, g3: -1, h3: 1, a2: 1, b2: 2, c2: 2, d2: -5, e2: -5, f2: 2, g2: 2, h2: 1, a1: 0, b1: 0, c1: 0, d1: 0, e1: 0, f1: 0, g1: 0, h1: 0}
  @pawn_pst_black %{a1: 0, b1: 0, c1: 0, d1: 0, e1: 0, f1: 0, g1: 0, h1: 0, a2: 10, b2: 10, c2: 10, d2: 10, e2: 10, f2: 10, g2: 10, h2: 10, a3: 2, b3: 2, c3: 4, d3: 6, e3: 6, f3: 4, g3: 2, h3: 2, a4: 1, b4: 1, c4: 2, d4: 5, e4: 5, f4: 2, g4: 1, h4: 1, a5: 0, b5: 0, c5: 0, d5: 4, e5: 4, f5: 0, g5: 0, h5: 0, a6: 1, b6: -1, c6: -2, d6: 0, e6: 0, f6: -2, g6: -1, h6: 1, a7: 1, b7: 2, c7: 2, d7: -5, e7: -5, f7: 2, g7: 2, h7: 1, a8: 0, b8: 0, c8: 0, d8: 0, e8: 0, f8: 0, g8: 0, h8: 0}
  @knight_pst_white %{a8: -5, b8: -4, c8: -3, d8: -3, e8: -3, f8: -3, g8: -4, h8: -5, a7: -4, b7: -2, c7: 0, d7: 0, e7: 0, f7: 0, g7: -2, h7: -4, a6: -3, b6: 0, c6: 1, d6: 2, e6: 2, f6: 1, g6: 0, h6: -3, a5: -3, b5: 1, c5: 2, d5: 2, e5: 2, f5: 2, g5: 1, h5: -3, a4: -3, b4: 0, c4: 2, d4: 2, e4: 2, f4: 2, g4: 0, h4: -3, a3: -3, b3: 1, c3: 1, d3: 2, e3: 2, f3: 1, g3: 1, h3: -3, a2: -4, b2: -2, c2: 0, d2: 1, e2: 1, f2: 0, g2: -2, h2: -4, a1: -5, b1: -4, c1: -3, d1: -3, e1: -3, f1: -3, g1: -4, h1: -5}
  @knight_pst_black %{a1: -5, b1: -4, c1: -3, d1: -3, e1: -3, f1: -3, g1: -4, h1: -5, a2: -4, b2: -2, c2: 0, d2: 0, e2: 0, f2: 0, g2: -2, h2: -4, a3: -3, b3: 0, c3: 1, d3: 2, e3: 2, f3: 1, g3: 0, h3: -3, a4: -3, b4: 1, c4: 2, d4: 2, e4: 2, f4: 2, g4: 1, h4: -3, a5: -3, b5: 0, c5: 2, d5: 2, e5: 2, f5: 2, g5: 0, h5: -3, a6: -3, b6: 1, c6: 1, d6: 2, e6: 2, f6: 1, g6: 1, h6: -3, a7: -4, b7: -2, c7: 0, d7: 1, e7: 1, f7: 0, g7: -2, h7: -4, a8: -5, b8: -4, c8: -3, d8: -3, e8: -3, f8: -3, g8: -4, h8: -5}
  @bishop_pst_white %{a8: -4, b8: -2, c8: -2, d8: -2, e8: -2, f8: -2, g8: -2, h8: -4, a7: -2, b7: 0, c7: 0, d7: 0, e7: 0, f7: 0, g7: 0, h7: -2, a6: -2, b6: 0, c6: 1, d6: 2, e6: 2, f6: 1, g6: 0, h6: -2, a5: -2, b5: 1, c5: 1, d5: 2, e5: 2, f5: 1, g5: 1, h5: -2, a4: -2, b4: 0, c4: 2, d4: 2, e4: 2, f4: 2, g4: 0, h4: -2, a3: -2, b3: 2, c3: 2, d3: 2, e3: 2, f3: 2, g3: 2, h3: -2, a2: -2, b2: 1, c2: 0, d2: 0, e2: 0, f2: 0, g2: 1, h2: -2, a1: -4, b1: -2, c1: -2, d1: -2, e1: -2, f1: -2, g1: -2, h1: -4}
  @bishop_pst_black %{a1: -4, b1: -2, c1: -2, d1: -2, e1: -2, f1: -2, g1: -2, h1: -4, a2: -2, b2: 0, c2: 0, d2: 0, e2: 0, f2: 0, g2: 0, h2: -2, a3: -2, b3: 0, c3: 1, d3: 2, e3: 2, f3: 1, g3: 0, h3: -2, a4: -2, b4: 1, c4: 1, d4: 2, e4: 2, f4: 1, g4: 1, h4: -2, a5: -2, b5: 0, c5: 2, d5: 2, e5: 2, f5: 2, g5: 0, h5: -2, a6: -2, b6: 2, c6: 2, d6: 2, e6: 2, f6: 2, g6: 2, h6: -2, a7: -2, b7: 1, c7: 0, d7: 0, e7: 0, f7: 0, g7: 1, h7: -2, a8: -4, b8: -2, c8: -2, d8: -2, e8: -2, f8: -2, g8: -2, h8: -4}
  @rook_pst_white %{a8: 0, b8: 0, c8: 0, d8: 0, e8: 0, f8: 0, g8: 0, h8: 0, a7: 1, b7: 2, c7: 2, d7: 2, e7: 2, f7: 2, g7: 2, h7: 1, a6: -1, b6: 0, c6: 0, d6: 0, e6: 0, f6: 0, g6: 0, h6: -1, a5: -1, b5: 0, c5: 0, d5: 0, e5: 0, f5: 0, g5: 0, h5: -1, a4: -1, b4: 0, c4: 0, d4: 0, e4: 0, f4: 0, g4: 0, h4: -1, a3: -1, b3: 0, c3: 0, d3: 0, e3: 0, f3: 0, g3: 0, h3: -1, a2: -1, b2: 0, c2: 0, d2: 0, e2: 0, f2: 0, g2: 0, h2: -1, a1: 0, b1: 0, c1: 0, d1: 1, e1: 1, f1: 0, g1: 0, h1: 0}
  @rook_pst_black %{a1: 0, b1: 0, c1: 0, d1: 0, e1: 0, f1: 0, g1: 0, h1: 0, a2: 1, b2: 2, c2: 2, d2: 2, e2: 2, f2: 2, g2: 2, h2: 1, a3: -1, b3: 0, c3: 0, d3: 0, e3: 0, f3: 0, g3: 0, h3: -1, a4: -1, b4: 0, c4: 0, d4: 0, e4: 0, f4: 0, g4: 0, h4: -1, a5: -1, b5: 0, c5: 0, d5: 0, e5: 0, f5: 0, g5: 0, h5: -1, a6: -1, b6: 0, c6: 0, d6: 0, e6: 0, f6: 0, g6: 0, h6: -1, a7: -1, b7: 0, c7: 0, d7: 0, e7: 0, f7: 0, g7: 0, h7: -1, a8: 0, b8: 0, c8: 0, d8: 1, e8: 1, f8: 0, g8: 0, h8: 0}
  @queen_pst_white %{a8: -4, b8: -2, c8: -2, d8: -1, e8: -1, f8: -2, g8: -2, h8: -4, a7: -2, b7: 0, c7: 0, d7: 0, e7: 0, f7: 0, g7: 0, h7: -2, a6: -2, b6: 0, c6: 1, d6: 1, e6: 1, f6: 1, g6: 0, h6: -2, a5: -1, b5: 0, c5: 1, d5: 1, e5: 1, f5: 1, g5: 0, h5: -1, a4: 0, b4: 0, c4: 1, d4: 1, e4: 1, f4: 1, g4: 0, h4: -1, a3: -2, b3: 1, c3: 1, d3: 1, e3: 1, f3: 1, g3: 0, h3: -2, a2: -2, b2: 0, c2: 1, d2: 0, e2: 0, f2: 0, g2: 0, h2: -2, a1: -4, b1: -2, c1: -2, d1: -1, e1: -1, f1: -2, g1: -2, h1: -4}
  @queen_pst_black %{a1: -4, b1: -2, c1: -2, d1: -1, e1: -1, f1: -2, g1: -2, h1: -4, a2: -2, b2: 0, c2: 0, d2: 0, e2: 0, f2: 0, g2: 0, h2: -2, a3: -2, b3: 0, c3: 1, d3: 1, e3: 1, f3: 1, g3: 0, h3: -2, a4: -1, b4: 0, c4: 1, d4: 1, e4: 1, f4: 1, g4: 0, h4: -1, a5: 0, b5: 0, c5: 1, d5: 1, e5: 1, f5: 1, g5: 0, h5: -1, a6: -2, b6: 1, c6: 1, d6: 1, e6: 1, f6: 1, g6: 0, h6: -2, a7: -2, b7: 0, c7: 1, d7: 0, e7: 0, f7: 0, g7: 0, h7: -2, a8: -4, b8: -2, c8: -2, d8: -1, e8: -1, f8: -2, g8: -2, h8: -4}
  @king_pst_white_middlegame %{a8: -3, b8: -4, c8: -4, d8: -5, e8: -5, f8: -4, g8: -4, h8: -3, a7: -3, b7: -4, c7: -4, d7: -5, e7: -5, f7: -4, g7: -4, h7: -3, a6: -3, b6: -4, c6: -4, d6: -5, e6: -5, f6: -4, g6: -4, h6: -3, a5: -3, b5: -4, c5: -4, d5: -5, e5: -5, f5: -4, g5: -4, h5: -3, a4: -2, b4: -3, c4: -3, d4: -4, e4: -4, f4: -3, g4: -3, h4: -2, a3: -1, b3: -2, c3: -2, d3: -2, e3: -2, f3: -2, g3: -2, h3: -1, a2: 2, b2: 2, c2: 0, d2: 0, e2: 0, f2: 0, g2: 2, h2: 2, a1: 2, b1: 3, c1: 1, d1: 0, e1: 0, f1: 1, g1: 3, h1: 2}
  @king_pst_black_middlegame %{a1: -3, b1: -4, c1: -4, d1: -5, e1: -5, f1: -4, g1: -4, h1: -3, a2: -3, b2: -4, c2: -4, d2: -5, e2: -5, f2: -4, g2: -4, h2: -3, a3: -3, b3: -4, c3: -4, d3: -5, e3: -5, f3: -4, g3: -4, h3: -3, a4: -3, b4: -4, c4: -4, d4: -5, e4: -5, f4: -4, g4: -4, h4: -3, a5: -2, b5: -3, c5: -3, d5: -4, e5: -4, f5: -3, g5: -3, h5: -2, a6: -1, b6: -2, c6: -2, d6: -2, e6: -2, f6: -2, g6: -2, h6: -1, a7: 2, b7: 2, c7: 0, d7: 0, e7: 0, f7: 0, g7: 2, h7: 2, a8: 2, b8: 3, c8: 1, d8: 0, e8: 0, f8: 1, g8: 3, h8: 2}
  @king_pst_white_endgame %{a8: -5, b8: -3, c8: -2, d8: -1, e8: -1, f8: -2, g8: -3, h8: -5, a7: -3, b7: -1, c7: 1, d7: 2, e7: 2, f7: 1, g7: -1, h7: -3, a6: -2, b6: 1, c6: 2, d6: 3, e6: 3, f6: 2, g6: 1, h6: -2, a5: -1, b5: 2, c5: 3, d5: 4, e5: 4, f5: 3, g5: 2, h5: -1, a4: -1, b4: 2, c4: 3, d4: 4, e4: 4, f4: 3, g4: 2, h4: -1, a3: -2, b3: 1, c3: 2, d3: 3, e3: 3, f3: 2, g3: 1, h3: -2, a2: -3, b2: -1, c2: 1, d2: 2, e2: 2, f2: 1, g2: -1, h2: -3, a1: -5, b1: -3, c1: -2, d1: -1, e1: -1, f1: -2, g1: -3, h1: -5}
  @king_pst_black_endgame %{a1: -5, b1: -3, c1: -2, d1: -1, e1: -1, f1: -2, g1: -3, h1: -5, a2: -3, b2: -1, c2: 1, d2: 2, e2: 2, f2: 1, g2: -1, h2: -3, a3: -2, b3: 1, c3: 2, d3: 3, e3: 3, f3: 2, g3: 1, h3: -2, a4: -1, b4: 2, c4: 3, d4: 4, e4: 4, f4: 3, g4: 2, h4: -1, a5: -1, b5: 2, c5: 3, d5: 4, e5: 4, f5: 3, g5: 2, h5: -1, a6: -2, b6: 1, c6: 2, d6: 3, e6: 3, f6: 2, g6: 1, h6: -2, a7: -3, b7: -1, c7: 1, d7: 2, e7: 2, f7: 1, g7: -1, h7: -3, a8: -5, b8: -3, c8: -2, d8: -1, e8: -1, f8: -2, g8: -3, h8: -5}

  defp get_positional_bonus(:pawn, square, :white, _), do: @pawn_pst_white[square] || 0
  defp get_positional_bonus(:pawn, square, :black, _), do: @pawn_pst_black[square] || 0
  defp get_positional_bonus(:knight, square, :white, _), do: @knight_pst_white[square] || 0
  defp get_positional_bonus(:knight, square, :black, _), do: @knight_pst_black[square] || 0
  defp get_positional_bonus(:bishop, square, :white, _), do: @bishop_pst_white[square] || 0
  defp get_positional_bonus(:bishop, square, :black, _), do: @bishop_pst_black[square] || 0
  defp get_positional_bonus(:rook, square, :white, _), do: @rook_pst_white[square] || 0
  defp get_positional_bonus(:rook, square, :black, _), do: @rook_pst_black[square] || 0
  defp get_positional_bonus(:queen, square, :white, _), do: @queen_pst_white[square] || 0
  defp get_positional_bonus(:queen, square, :black, _), do: @queen_pst_black[square] || 0
  defp get_positional_bonus(:king, square, :white, :middlegame), do: @king_pst_white_middlegame[square] || 0
  defp get_positional_bonus(:king, square, :black, :middlegame), do: @king_pst_black_middlegame[square] || 0
  defp get_positional_bonus(:king, square, :white, :endgame), do: @king_pst_white_endgame[square] || 0
  defp get_positional_bonus(:king, square, :black, :endgame), do: @king_pst_black_endgame[square] || 0
  defp get_positional_bonus(_, _, _, _), do: 0
end
