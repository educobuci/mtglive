require "mtgsim"

class Game
  def die_winner=(value)
    @die_winner = value
  end
end

class GameExtension
  def initialize
    @players = []
  end
  
  def incoming(message, callback)
    if message['channel'] == '/meta/subscribe'
      @players = []
      player_id = message['subscription'].gsub(/\/play\//, "")
      #if players.size < 2
        @players.push({ player: Player.new, client_id: message['client_id'], player_id: player_id, index: 0 })
        @players.push({ player: Player.new, client_id: 0, player_id: "fake", index: 1 })
        #if @players.size == 2
          start_game()
        #end
      #end
    elsif message['channel'].include?("/play")
      player = @players.select { |p| p.client_id == message['client_id'] }
      player_action(player, {
        type: message['data']['type'],
        value: message['data']['value']
      })
    end
    puts message.to_s
    callback.call(message)
  end
  
  def player_action(player, action)
    case action.type
    when "start_player"
      puts action.to_s
      @game.start_player(player.index, action.value.to_i)
      @game.draw_hands()
      broadcast "hand" do |p|
        p.player.hand
      end
    end
  end
  
  def start_game
    @game = Game.new(@players.map { |p| p.player })
    dices = @game.roll_dices()
    
    # Test dices roll
    @game.die_winner=0
    dices = [6,2]
    
    broadcast "roll_dices" do
      { @players[0].player_id => dices[0], @players[1].player_id => dices[1] }
    end
  end
  
  def broadcast(type, &block)
    @players.each do |p|
      faye_client.publish "/play/#{p.player_id}",{
        type: type,
        value: block.call(p)
      }
    end
  end
  
  def faye_client
     @faye_client ||= Faye::Client.new('http://localhost:3000/faye')
  end
end