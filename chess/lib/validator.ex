defmodule Chess.Validator do
  @moduledoc "Handles all chess move validation."
  alias Chess.GameState

  @doc "The main validation function."
  def is_legal_move?(%GameState{} = state, from, to) do
    with {:ok, {color, piece_type}} <- Map.fetch(state.board, from) do
      is_your_turn?(state, color) &&
      is_not_capturing_own_piece?(state, {color, piece_type}, to) &&
      is_valid_for_piece?(state, {color, piece_type}, from, to)
    else
      :error -> false
    end
  end

  defp is_your_turn?(%GameState{to_move: to_move}, color), do: to_move == color

  defp is_not_capturing_own_piece?(%GameState{board: board}, {my_color, _}, to) do
    case Map.get(board, to) do
      nil -> true # 'to' square is empty, this is fine
      {opponent_color, _} -> opponent_color != my_color # Fine as long as it's not my color
    end
  end


  defp is_valid_for_piece?(state, {color, :pawn}, from, to) do
    is_legal_pawn_move?(state, color, from, to)
  end

  defp is_valid_for_piece?(state, {color, :rook}, from, to) do
    is_legal_rook_move?(state, from, to)
  end

  defp is_valid_for_piece?(_state, {_color, :knight}, _from, _to) do
    true
  end

  defp is_valid_for_piece?(_state, _piece, _from, _to), do: true



  defp is_legal_pawn_move?(%GameState{} = state, color, from, to) do
      {from_file, from_rank} = to_coords(from)
      {to_file, to_rank} = to_coords(to)

      direction = if color == :white, do: 1, else: -1
      rank_diff = to_rank - from_rank
      file_diff = abs(to_file - from_file)

      cond do
        # --- Rule 1: Diagonal Move ---
        file_diff == 1 && rank_diff == direction ->
          is_normal_capture = not is_square_empty?(state.board, to)
          is_en_passant = is_square_empty?(state.board, to) &&
                          to == state.en_passant_target

          is_normal_capture || is_en_passant

        # --- Rule 2: Single-Square Forward Move ---
        file_diff == 0 && rank_diff == direction ->
          is_square_empty?(state.board, to)

        # --- Rule 3: Double-Square First Move ---
        file_diff == 0 && rank_diff == (direction * 2) ->
          is_on_starting_rank?(color, from_rank) &&
            is_square_empty?(state.board, to) &&
            is_square_empty?(state.board, get_in_between_square(from, to))

        # --- Not a valid pawn move ---
        true ->
          false
      end
    end

  defp is_legal_rook_move?(%GameState{board: board}, from, to) do
    {from_file, from_rank} = to_coords(from)
    {to_file, to_rank} = to_coords(to)

    is_horizontal = (from_rank == to_rank && from_file != to_file)
    is_vertical = (from_file == to_file && from_rank != to_rank)

    if is_horizontal or is_vertical do
      true
    else
      false
    end
  end


  def to_coords(atom) do
      <<file, rank>> = Atom.to_string(atom)
      {file - ?a + 1, rank - ?0}
    end

  @doc "Checks if a square is empty (nil)."
  defp is_square_empty?(board, square_atom) do
    Map.get(board, square_atom) == nil
  end

  @doc "Checks if a pawn is on its starting rank."
  defp is_on_starting_rank?(:white, 2), do: true
  defp is_on_starting_rank?(:black, 7), do: true
  defp is_on_starting_rank?(_color, _rank), do: false

@doc "Calculates the single square between a 2-square pawn move."
  def get_in_between_square(from, to) do
    {_from_file_num, from_rank_num} = to_coords(from)
    {_to_file_num, to_rank_num} = to_coords(to)


    file_letter_string = Atom.to_string(from) |> String.at(0)

    in_between_rank = (from_rank_num + to_rank_num) |> div(2) |> Integer.to_string()

    String.to_atom(file_letter_string <> in_between_rank)
  end
end
