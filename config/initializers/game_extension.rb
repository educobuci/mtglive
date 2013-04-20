require "mtgsim"

class GameExtension
  def initialize
    @players = []
  end
  
  def incoming(message, callback)
    if message['channel'] == '/meta/subscribe'
      player_id = message['subscription'].gsub(/\/play\//, "")
      if players.size < 2
        @players.push({ player_id => Player.new })
        if @players.size == 2
          start_game()
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