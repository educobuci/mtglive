require "mtgsim"
class GameController < ApplicationController
  respond_to :html, :json
  @@game = nil
  def main
    Mtglive::Application.reload_routes!
    render text: "reset"
    unless params[:reset].nil?
      @@game = nil
    end
  end
  def play_card
    @@game.play_card(params[:card].to_i)
    render text: ""
  end
  def tap_card
    @@game.tap_card(params[:card].to_i)
    render text: ""
  end
  def pass_phase
    @@game.next_phase
    render text: ""
  end
  def game
    if @@game.nil?
      @@game = Game.new [Player.new, Player.new]
    end
    @player_game = { phase: @@game.current_phase, player: @@game.current_player_index, me: @@game.players(session[:player]) }
    respond_with @player_game
  end
  def play
    
  end
end