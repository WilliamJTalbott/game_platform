module GoFish
  class Game < CardGame::Game
    def initialize(players)
      @players = players
      @deck = CardGame::Deck.new
      @turn_index = 0
      @results = []
    end

    serializes players: [ Player ]

    def deal
      deck.shuffle
      players.each { |player| player.receive(deck.deal(hand_amount)) }
    end

    def play_turn(target, rank)
      new_turn_result(target, rank)
      handle_turn(target, rank)

      get_winner if is_winner?
    end

    private

    def handle_turn(target, rank)
      return repeat_turn if get_matches(target, rank)
      return repeat_turn if go_fish&.rank == rank
      end_turn
    end

    def new_turn_result(target, rank)
      self.results.append(TurnResult.new(players, active_player, target, rank))
    end

    def decide_winner
      highest_count = players.map(&:book_count).max
      tied_players = players.select { |player| player.book_count == highest_count }

      if tied_players.length == 1
        tied_players.first
      else
        handle_book_tie(tied_players)
      end
    end

    def handle_book_tie(tied_players)
      tied_players.max_by do |player|
        CardGame::Card::RANKS.index(player.highest_book.rank)
      end
    end

    def draw_on_empty(player)
      draw_from_deck(player) if player.cards.empty?
    end

    def turn_result
      self.results.last
    end

    def get_matches(target, rank)
      matches = target.take(rank)
      return nil if matches.empty?

      handle_matches(target, matches)
      matches
    end

    def handle_matches(target, matches)
      turn_result.got_cards(matches.length)
      active_player.receive(matches)
      draw_on_empty(target)
    end

    def repeat_turn
      draw_on_empty(active_player)
      switch_turn if active_player.cards.empty?
    end

    def end_turn
      draw_on_empty(active_player)
      switch_turn
    end

    def switch_turn
      order = players.rotate(turn_index + 1)
      order.each { |player| return self.turn_index = players.index(player) unless player.cards.empty? }
    end

    def go_fish
      turn_result.go_fish
      draw_from_deck(active_player)
    end

    def draw_from_deck(player)
      return if deck.depleted?
      card = deck.draw
      player.receive(card)
      turn_result.drew_card(card)
      card
    end

    def is_winner? = players.none? { |player| !player.cards.empty? }

    def get_winner
      player = decide_winner
      return nil unless player
      turn_result.winner(player)
      player
    end
  end
end
