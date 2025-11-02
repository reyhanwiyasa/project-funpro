defmodule Chess.GameState do
  @modledoc "Holds the entire state of the game."

  defstruct [
    :board,
    :to_move,
    # --- NEW FIELDS ---
    :white_time_left_ms,
    :black_time_left_ms,
    :turn_started_at      # A System.monotonic_time in :millisecond
  ]

  @doc """
  Returns a new, starting game state with a given time control.
  """
  def new(start_minutes) do
    # Convert minutes to milliseconds
    total_ms = start_minutes * 60 * 1000

    %__MODULE__{
      board: initial_board(),
      to_move: :white,
      # --- NEW FIELDS ---
      white_time_left_ms: total_ms,
      black_time_left_ms: total_ms,
      turn_started_at: System.monotonic_time(:millisecond)
    }
  end

  # This private function builds the starting board map.
  # Empty squares are just absent from the map.
  defp initial_board() do
    %{
      # White Pieces
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

      # Black Pieces
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
