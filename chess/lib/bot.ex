defmodule Chess.Bot do
  @moduledoc """
  The 'Strategist' module.
  Provides different AI algorithms for choosing a move.
  """
  alias Chess.GameState
  alias Chess.Validator
  alias Chess.Evaluator

  @infinity 1_000_000

  @doc """
  Chooses a move using a simple greedy algorithm (depth 1).
  This is fast but not very smart.
  """
  def choose_greedy_move(%GameState{} = state) do
    color = state.to_move
    IO.puts("🤖 Simple Bot (#{color}) is thinking...")

    moves = Validator.generate_all_legal_moves(state, color)

    scored_moves =
      Enum.map(moves, fn {from, to} ->
        shadow_state = GameState.make_move(state, from, to, :queen)
        score = Evaluator.evaluate(shadow_state)
        {{from, to}, score}
      end)

    best_move_tuple =
      if color == :white do
        Enum.max_by(scored_moves, fn {_move, score} -> score end, fn -> {nil, 0} end)
      else
        Enum.min_by(scored_moves, fn {_move, score} -> score end, fn -> {nil, 0} end)
      end

    case best_move_tuple do
      {move, score} when move != nil ->
        IO.puts("🤖 Simple Bot chose #{inspect(move)} with score #{score}")
        {:ok, move}
      _ ->
        {:error, :no_moves}
    end
  end

  @doc """
  Chooses the best move using the minimax algorithm with alpha-beta pruning.
  """
  def find_best_move(%GameState{} = state, depth) do
    color = state.to_move
    IO.puts("🤖 Minimax Bot (#{color}) is thinking (depth: #{depth})...")

    maximizing_player = (color == :white)
    {score, move} = minimax(state, depth, -@infinity, @infinity, maximizing_player)

    if move == nil do
      IO.puts("🤖 Minimax has no best move, falling back to greedy.")
      choose_greedy_move(state)
    else
      IO.puts("🤖 Minimax Bot chose #{inspect(move)} with a projected score of #{score}")
      {:ok, move}
    end
  end

  # Private minimax implementation
  defp minimax(game_state, depth, alpha, beta, maximizing_player) do
    # Base case: if max depth is reached or game is over, return static evaluation
    if depth == 0 or Validator.checkmate?(game_state, game_state.to_move) do
      {Evaluator.evaluate(game_state), nil}
    else
      # Recursive step
      moves = Validator.generate_all_legal_moves(game_state, game_state.to_move)
      # If no moves, it's a stalemate
      if Enum.empty?(moves), do: {Evaluator.evaluate(game_state), nil}, else:
        run_search(moves, game_state, depth, alpha, beta, maximizing_player)
    end
  end

  defp run_search(moves, game_state, depth, alpha, beta, maximizing_player) do
    # Set initial best value based on whether we are maximizing or minimizing
    initial_best_value = if maximizing_player, do: -@infinity, else: @infinity
    initial_acc = {initial_best_value, hd(moves), alpha, beta}

    # The core loop: iterate through moves, updating best move and alpha/beta values
    {best_value, best_move, _, _} =
      Enum.reduce_while(moves, initial_acc, fn move, {best_val, best_mv, a, b} ->
        # Explore the next state
        shadow_state = GameState.make_move(game_state, elem(move, 0), elem(move, 1), :queen)
        {eval, _} = minimax(shadow_state, depth - 1, a, b, not maximizing_player)

        if maximizing_player do
          # Maximizing player's logic
          if eval > best_val do
            new_alpha = max(a, eval)
            if beta <= new_alpha, do: {:halt, {eval, move, new_alpha, b}}, else: {:cont, {eval, move, new_alpha, b}}
          else
            if beta <= a, do: {:halt, {best_val, best_mv, a, b}}, else: {:cont, {best_val, best_mv, a, b}}
          end
        else
          # Minimizing player's logic
          if eval < best_val do
            new_beta = min(b, eval)
            if new_beta <= a, do: {:halt, {eval, move, a, new_beta}}, else: {:cont, {eval, move, a, new_beta}}
          else
            if b <= alpha, do: {:halt, {best_val, best_mv, a, b}}, else: {:cont, {best_val, best_mv, a, b}}
          end
        end
      end)

    {best_value, best_move}
  end
end
