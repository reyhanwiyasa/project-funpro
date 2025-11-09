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
      nil -> true
      {opponent_color, _} -> opponent_color != my_color
    end
  end


  defp is_valid_for_piece?(state, {color, :pawn}, from, to) do
    is_legal_pawn_move?(state, color, from, to)
  end

  defp is_valid_for_piece?(state, {_color, :rook}, from, to) do
    is_legal_rook_move?(state, from, to)
  end

  defp is_valid_for_piece?(state, {_color, :knight}, from, to) do
    is_legal_knight_move?(state, from, to)
  end

  defp is_valid_for_piece?(state, {_color, :bishop}, from, to) do
    is_legal_bishop_move?(state, from, to)
  end

  defp is_valid_for_piece?(state, {_color, :queen}, from, to) do
    is_legal_queen_move?(state, from, to)
  end

  defp is_valid_for_piece?(state, {_color, :king}, from, to) do
    is_legal_king_move?(state, from, to)
  end

 # -- PAWN --
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


    # -- ROOK --
  defp is_legal_rook_move?(%GameState{board: board}, from, to) do
      {from_file, from_rank} = to_coords(from)
      {to_file, to_rank} = to_coords(to)

      is_horizontal = (from_rank == to_rank && from_file != to_file)
      is_vertical = (from_file == to_file && from_rank != to_rank)

      (is_horizontal || is_vertical) && is_path_clear?(board, from, to)
    end

    # -- KNIGHT --
  defp is_legal_knight_move?(_state, from, to) do
      {from_file, from_rank} = to_coords(from)
      {to_file, to_rank} = to_coords(to)

      delta_file = abs(to_file - from_file)
      delta_rank = abs(to_rank - from_rank)

      (delta_file == 2 && delta_rank == 1) || (delta_file == 1 && delta_rank == 2)
    end

    # -- BISHOP --
    defp is_legal_bishop_move?(%GameState{board: board}, from, to) do
    {from_file, from_rank} = to_coords(from)
    {to_file, to_rank} = to_coords(to)
    is_diagonal = abs(to_file - from_file) == abs(to_rank - from_rank)
    is_diagonal && is_path_clear?(board, from, to)
  end

  # -- QUEEN --
  defp is_legal_queen_move?(%GameState{} = state, from, to) do
    is_legal_rook_move?(state, from, to) ||
    is_legal_bishop_move?(state, from, to)
  end


  # -- KING --
  defp is_legal_king_move?(_state, from, to) do
    {from_file, from_rank} = to_coords(from)
    {to_file, to_rank} = to_coords(to)

    delta_file = abs(to_file - from_file)
    delta_rank = abs(to_rank - from_rank)

    max(delta_file, delta_rank) == 1
  end



    # -- HELPER --
  def to_coords(atom) do
      <<file, rank>> = Atom.to_string(atom)
      {file - ?a + 1, rank - ?0}
    end

  defp is_square_empty?(board, square_atom) do
    Map.get(board, square_atom) == nil
  end

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

  defp is_path_clear?(board, from, to) do
    squares_between = get_squares_between(from, to)

    Enum.all?(squares_between, fn square ->
      is_square_empty?(board, square)
    end)
  end

    defp get_squares_between(from, to) do


      {from_file, from_rank} = to_coords(from)
      {to_file, to_rank} = to_coords(to)

      delta_file = to_file - from_file
      delta_rank = to_rank - from_rank

      cond do
        delta_rank == 0 && delta_file != 0 ->
          file_start = min(from_file, to_file) + 1
          file_end = max(from_file, to_file) - 1

          if file_start > file_end do
            []
          else
            for f <- file_start..file_end, do: coords_to_atom({f, from_rank})
          end

        delta_file == 0 && delta_rank != 0 ->
          rank_start = min(from_rank, to_rank) + 1
          rank_end = max(from_rank, to_rank) - 1

          if rank_start > rank_end do
            []
          else
            for r <- rank_start..rank_end, do: coords_to_atom({from_file, r})
          end

        abs(delta_file) == abs(delta_rank) && delta_file != 0 ->
          file_step = div(delta_file, abs(delta_file))
          rank_step = div(delta_rank, abs(delta_rank))

          num_steps_between = abs(delta_file) - 1

          if num_steps_between > 0 do
            for i <- 1..num_steps_between do
              file = from_file + (i * file_step)
              rank = from_rank + (i * rank_step)
              coords_to_atom({file, rank})
            end
          else
            []
          end

        true ->
          []
      end
    end
@doc "Converts coordinates like {1, 1} into an atom :a1"
  defp coords_to_atom({file_num, rank_num}) do
    file_char = ?a + file_num - 1
    rank_char = ?0 + rank_num

    String.to_atom(<<file_char, rank_char>>)
  end
end
