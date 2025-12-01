defmodule Chess.Render do
  @moduledoc """
  Handles printing the game state to the console.
  """
  alias Chess.Validator

  # Define the files and ranks as STRING lists
  @files ~w(a b c d e f g h)
  @ranks ~w(8 7 6 5 4 3 2 1)
  @max_score_for_bar 500 # Approx. value of a rook

  @doc """
  The main public function. Renders the board, timers, and score bar.
  """
  def board(%Chess.GameState{} = game_state) do
    IO.write(:clear)
    IO.puts("   --- Elixir Chess ---")

    score = Chess.Evaluator.evaluate(game_state)
    score_bar_chars = render_score_bar(score)

    highlight_squares =
      case game_state.input_state do
        {:awaiting_to, from_square} ->
          # Get all legal moves for the selected piece
          dest_squares =
            Validator.generate_all_legal_moves(game_state, game_state.to_move)
            |> Enum.filter(fn {from, _to} -> from == from_square end)
            |> Enum.map(fn {_from, to} -> to end)

          # Combine the 'from' square with the destination squares and create the set
          MapSet.new([from_square | dest_squares])
        _ ->
          MapSet.new() # Empty set, nothing to highlight
      end

    display_timers(game_state)

    Enum.with_index(@ranks)
    |> Enum.each(fn {rank, index} ->
      bar_char = Enum.at(score_bar_chars, index)
      print_rank(rank, game_state.board, bar_char, highlight_squares)
    end)

    IO.puts("     +--------------------------+")
    IO.puts("       a  b  c  d  e  f  g  h")
    IO.puts("   Score: #{format_score(score)}")
    IO.puts("")
  end

  defp print_rank(rank, board, bar_char, highlight_squares) do
    IO.write("    #{rank} |")

    Enum.each(@files, fn file ->
      square = String.to_atom(file <> rank)
      piece = Map.get(board, square)
      
      # Check if the current square should be highlighted
      if MapSet.member?(highlight_squares, square) do
        # Use cyan background for highlighting
        IO.write(IO.ANSI.cyan_background() <> " #{get_piece_char(piece)} " <> IO.ANSI.reset())
      else
        IO.write(" #{get_piece_char(piece)} ")
      end
    end)
    
    IO.puts("| #{bar_char}")
  end

  # (Rest of the functions remain the same)
  defp get_piece_char(nil), do: "."
  defp get_piece_char({:white, :pawn}), do: "♙"
  defp get_piece_char({:white, :rook}), do: "♖"
  defp get_piece_char({:white, :knight}), do: "♘"
  defp get_piece_char({:white, :bishop}), do: "♗"
  defp get_piece_char({:white, :queen}), do: "♕"
  defp get_piece_char({:white, :king}), do: "♔"
  defp get_piece_char({:black, :pawn}), do: "♟"
  defp get_piece_char({:black, :rook}), do: "♜"
  defp get_piece_char({:black, :knight}), do: "♞"
  defp get_piece_char({:black, :bishop}), do: "♝"
  defp get_piece_char({:black, :queen}), do: "♛"
  defp get_piece_char({:black, :king}), do: "♚"

  defp display_timers(game_state) do
    black_ms = game_state.black_time_left_ms
    white_ms = game_state.white_time_left_ms
    black_time_str = format_time(black_ms)
    white_time_str = format_time(white_ms)
    black_arrow = if game_state.to_move == :black, do: ">", else: " "
    white_arrow = if game_state.to_move == :white, do: ">", else: " "

    IO.puts("")
    IO.puts("    Black: #{black_time_str} #{black_arrow}")
    IO.puts("    White: #{white_time_str} #{white_arrow}")
    IO.puts("     +--------------------------+")
  end

  defp format_time(milliseconds) do
    safe_ms = max(milliseconds, 0)
    total_seconds = div(safe_ms, 1000)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    mins_str = minutes |> Integer.to_string() |> String.pad_leading(2, "0")
    secs_str = seconds |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{mins_str}:#{secs_str}"
  end

  defp format_score(n) when n > 0, do: "+#{n}"
  defp format_score(n), do: "#{n}"

  defp render_score_bar(score) do
    score_ratio = score / @max_score_for_bar |> max(-1.0) |> min(1.0)
    white_ranks = round(8 * (0.5 + score_ratio / 2))
    black_bar = List.duplicate(" ", 8 - white_ranks)
    white_bar = List.duplicate("█", white_ranks)
    black_bar ++ white_bar
  end
end
