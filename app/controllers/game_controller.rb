require "mtgsim"
class GameController < ApplicationController
  respond_to :html, :json
  @@game = nil
  def main
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
  def game
    if @@game.nil?
      @@game = Game.new [Player.new, Player.new]
      @@game.start
    end
    @player_game = { me: @@game.players(session[:player]) }
    respond_with @player_game
  end
end