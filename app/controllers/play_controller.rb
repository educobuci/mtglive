class PlayController < FayeRails::Controller
  channel '/play' do
    monitor :subscribe do
      puts "Client #{client_id} subscribed to #{channel}."
    end
    monitor :publish do
      puts "Client #{client_id} published #{data.inspect} to #{channel}."
    end
    # subscribe do
    #   PlayController.publish "/play", data.inspect
    # end
  end
end