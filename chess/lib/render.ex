defmodule Chess.Render do
  @moduledoc """
  Handles printing the game state to the console.
  """

  # Define the files and ranks as STRING lists
  @files ~w(a b c d e f g h)
  @ranks ~w(8 7 6 5 4 3 2 1)

  @doc """
  The main public function. Renders the board AND timers.
  """
  def board(%Chess.GameState{} = game_state) do
    IO.write(:clear)
    IO.puts("   --- Chess Game ---")

    # --- NEW SECTION: DISPLAY TIMERS ---
    display_timers(game_state)

    # We use Enum.each to loop and perform an action
    # (printing) for each rank.
    Enum.each(@ranks, fn rank ->
      print_rank(rank, game_state.board)
    end)

    # Print the file letters at the bottom
    IO.puts("  ")
    IO.puts("      a  b  c  d  e  f  g  h")
    IO.puts("  ")
  end

  # --- Helper Functions ---

  # Prints a single rank (row)
  defp print_rank(rank, board) do
    # 'rank' is now a String, e.g., "8"
    IO.write("  #{rank} |")

    # For each file (a-h), get its piece and print it
    Enum.each(@files, fn file ->
      # 'file' is "a" and 'rank' is "8"
      # "a" <> "8" == "a8"
      square = String.to_atom(file <> rank)

      # We get the piece from the board map
      piece = Map.get(board, square)

      # We get the character for that piece and print it
      # Note: We added an extra space to keep alignment
      IO.write(" #{get_piece_char(piece)} ")
    end)

    # End the rank with a newline
    IO.puts("|")
  end

  # --- UPDATED SECTION ---
  # This function translates the data (e.Example, {:white, :pawn})
  # into a Unicode string for printing.
  defp get_piece_char(nil), do: "." # Empty square
  # White pieces (Unicode)
  defp get_piece_char({:white, :pawn}), do: "♙"
  defp get_piece_char({:white, :rook}), do: "♖"
  defp get_piece_char({:white, :knight}), do: "♘"
  defp get_piece_char({:white, :bishop}), do: "♗"
  defp get_piece_char({:white, :queen}), do: "♕"
  defp get_piece_char({:white, :king}), do: "♔"
  # Black pieces (Unicode)
  defp get_piece_char({:black, :pawn}), do: "♟"
  defp get_piece_char({:black, :rook}), do: "♜"
  defp get_piece_char({:black, :knight}), do: "♞"
  defp get_piece_char({:black, :bishop}), do: "♝"
  defp get_piece_char({:black, :queen}), do: "♛"
  defp get_piece_char({:black, :king}), do: "♚"

  # --- NEW HELPER FUNCTIONS ---

  defp display_timers(game_state) do
    # 1. Get the raw time left for each player
    black_ms = game_state.black_time_left_ms
    white_ms = game_state.white_time_left_ms

    # 2. Format them into "MM:SS"
    black_time_str = format_time(black_ms)
    white_time_str = format_time(white_ms)

    # 3. Print them. We'll add an arrow ">" to show whose turn it is.
    black_arrow = if game_state.to_move == :black, do: ">", else: " "
    white_arrow = if game_state.to_move == :white, do: ">", else: " "

    IO.puts("  ")
    IO.puts("    Black: #{black_time_str} #{black_arrow}")
    IO.puts("    White: #{white_time_str} #{white_arrow}")
    IO.puts("  ")
  end

  defp format_time(milliseconds) do
    # Ensure time doesn't go below zero
    safe_ms = max(milliseconds, 0)

    total_seconds = div(safe_ms, 1000)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)

    # Pad numbers with a leading 0 if they are < 10
    mins_str = minutes |> Integer.to_string() |> String.pad_leading(2, "0")
    secs_str = seconds |> Integer.to_string() |> String.pad_leading(2, "0")

    "#{mins_str}:#{secs_str}"
  end
end
