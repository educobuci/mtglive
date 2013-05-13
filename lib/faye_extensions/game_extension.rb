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
      player_action(player, {
        type: message['data']['type'],
        value: message['data']['value']
      })
    end
    puts message.to_s
    puts "___________________________________________________________"
    callback.call(message)
  end
  
  def player_action(player, action)
    case action.type
      when "start_player"
        if action.value.to_i == 0
          start_index = player[:index]
        else
          start_index = player[:index] == 0 ? 1 : 0
        end
        @game.start_player(player[:index], start_index)
        @game.draw_hands()
        broadcast_info "hand"
      when "mulligan"
        @game.mulligan(player[:index])
        broadcast_info "hand"
      when "keep"
        @game.keep(player[:index])
        @game.keep(1) if @test_mode
        if @game.state == :keep
          @game.start()
          broadcast_info
        end
      when "play_card"
        @game.play_card(player[:index], action.value.to_i)
        broadcast_info
      when "tap_card"
        @game.tap_card(player[:index], action.value.to_i)
        broadcast "info" do |p|
          self.player_info(p)
        end
      when "pass"
        @game.pass(player[:index])
        @game.pass(1) if @test_mode        
        
        if player[:index] == @game.current_player_index
          opponent = @players[player[:index] == 0 ? 1 : 0]

          faye_client.publish "/play/#{opponent[:player_id]}", {
            type: "pass",
            value: player_info(opponent)
          }
        end
    end
  end
  
  def player_info(player)
    opponent = @players[player[:index] == 0 ? 1 : 0]
    return {
      player: {
        hand: player[:player].hand,
        library: player[:player].library.size,
        board: player[:player].board,
      },
      phase: @game.current_phase,
      current_player: @players[@game.current_player_index][:player_id],
      opponent: { hand: opponent.player.hand, library: opponent.player.library.size, board: opponent.player.board }
    }
  end
  
  def start_game
    @game = Game.new(@players.map { |p| p.player })
    @game.phase_manager.add_observer self
    dices = @game.roll_dices()
    
    # Test dices roll
    if @test_mode
      @game.die_winner=0
      dices = [6, 2]
    end
    
    broadcast "roll_dices" do
      { @players[0].player_id => dices[0], @players[1].player_id => dices[1] }
    end
  end
  
  def update(status, phase)
    broadcast_info "info"
  end
  
  def broadcast_info(type="info", &block)
    broadcast type do |p|
      unless block.nil?
        block.call.merge player_info(p)
      else
        player_info(p)
      end
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