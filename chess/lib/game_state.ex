defmodule Chess.GameState do
  @moduledoc "Holds the entire state of the game."

  defstruct [
    :board,
    :to_move,
    :white_time_left_ms,
    :black_time_left_ms,
    :turn_started_at
  ]

  def new(start_minutes) do
    total_ms = start_minutes * 60 * 1000

    %__MODULE__{
      board: initial_board(),
      to_move: :white,
      white_time_left_ms: total_ms,
      black_time_left_ms: total_ms,
      turn_started_at: System.monotonic_time(:millisecond)
    }
  end

  def make_move(%__MODULE__{} = state, from, to) do
    piece = Map.get(state.board, from)

    if piece == nil do
      IO.puts("No piece on #{from}")
      state
    else
      new_board =
        state.board
        |> Map.delete(from)
        |> Map.put(to, piece)

      %__MODULE__{
        state
        | board: new_board,
          to_move: toggle_turn(state.to_move),
          turn_started_at: System.monotonic_time(:millisecond)
      }
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
