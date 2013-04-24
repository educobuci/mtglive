require "mtgsim"

class Game
  def die_winner=(value)
    @die_winner = value
  end
end

class GameExtension
  
  def initialize
    @players = []
    @test_mode = false
  end
  
  def incoming(message, callback)
    if message['channel'] == '/meta/subscribe'
      @players = [] if @test_mode
      player_id = message['subscription'].gsub(/\/play\//, "")
      if @players.size < 2 || @test_mode
        @players.push({ player: Player.new, client_id: message['clientId'], player_id: player_id, index: @players.size })
        @players.push({ player: Player.new, client_id: 0, player_id: "fake", index: 1 }) if @test_mode
        if @players.size == 2 || @test_mode
          start_game()
        end
      end
    elsif message['channel'] == "/play"
      player = (@players.select{ |p| p.client_id == message['clientId'] })[0]
      puts player[:index]
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
        @game.start_player(player[:index], action.value.to_i)
        @game.draw_hands()
        broadcast "hand" do |p|
          p[:player].hand
        end
      when "keep"
        @game.keep(player[:index])
        @game.keep(1) if @test_mode
        if @game.state == :keep
          @game.start()
          broadcast "start" do
            { game: "this will be the game data" }
          end          
        end
        
      when "mulligan"
        @game.mulligan(player[:index])
        broadcast "hand" do |p|
          p[:player].hand
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
      faye_client.publish "/play/#{p.player_id}", {
        type: type,
        value: block.call(p)
      }
    end
  end
  
  def faye_client
     @faye_client ||= Faye::Client.new('http://localhost:3000/faye')
  end
end