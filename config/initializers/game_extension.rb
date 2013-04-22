require "mtgsim"

class GameExtension
  def initialize
    @players = []
  end
  
  def incoming(message, callback)
    if message['channel'] == '/meta/subscribe'
      @players = []
      player_id = message['subscription'].gsub(/\/play\//, "")
      #if players.size < 2
        @players.push({ player_id => Player.new })
        @players.push({ fake: Player.new })
        #if @players.size == 2
          start_game()
        #end
      #end
    elsif message['channel'].include?("/play/")
      player_id = message['channel'].gsub(/\/play\//, "")
      if message['data']['type'] == 'start_player'
        @game.start_player(0,0)
        @game.draw_hands()
        [0,1].each do |n|
          faye_client.publish "/play/#{players_id[n]}",{
            type: "hand",
            value: { hand: players()[n].hand }
          }
        end
      end
    end
    
    puts message.to_s
    callback.call(message)
  end
  
  def players
    @players.map {|p| p[p.keys[0]] }
  end
  
  def players_id
    @players.map {|p| p.keys[0] }
  end
  
  def start_game
    @game = Game.new(players())
    dices = @game.roll_dices()
    
    puts "dices #{dices.to_s}"
    
    players_id.each do |p|
      faye_client.publish "/play/#{p}",{
        type: "roll_dices",
        value: { players_id[0] => dices[0], players_id[1] => dices[1] }
      }
    end    
  end
  
  def faye_client
     @faye_client ||= Faye::Client.new('http://localhost:3000/faye')
  end
end