defmodule Chess.Bot do
  @moduledoc """
  The 'Strategist' module.
  Uses the Evaluator to pick the best move (Greedy AI).
  """
  alias Chess.GameState
  alias Chess.Validator
  alias Chess.Evaluator

  @doc """
  Chooses the best move for the current turn color.
  Returns {:ok, {from, to}} just like Input.get_move/0.
  """
  def choose_move(%GameState{} = state) do
    color = state.to_move
    IO.puts("🤖 Bot (#{color}) is thinking...")

    # 1. Get all possible moves
    moves = Validator.generate_all_legal_moves(state, color)

    # 2. Evaluate every single move
    # We map each move to a tuple: {move, score}
    scored_moves =
      Enum.map(moves, fn {from, to} ->
        # Create a "shadow state" to test the move
        # We assume no promotion logic for the bot yet (defaults to Queen)
        shadow_state = GameState.make_move(state, from, to, :queen)

        # Get the score of this future state
        score = Evaluator.evaluate(shadow_state)

        {{from, to}, score}
      end)

    # 3. Pick the best move based on color
    # White wants highest score (+), Black wants lowest score (-)
    best_move_tuple =
      if color == :white do
        Enum.max_by(scored_moves, fn {_move, score} -> score end)
      else
        Enum.min_by(scored_moves, fn {_move, score} -> score end)
      end

    # Handle result
    case best_move_tuple do
      {move, score} ->
        IO.puts("🤖 Bot chose #{inspect(move)} with score #{score}")
        {:ok, move}
      nil ->
        {:error, :no_moves} # Should be handled by checkmate logic elsewhere
    end
  end
end
