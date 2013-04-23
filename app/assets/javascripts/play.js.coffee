window.App = Em.Application.create()

window.App.PlayerHandView = Ember.View.create
  templateName: "cards"
  cards: []
  
$ ->
  App.PlayerHandView.appendTo "#hand"
  
  resizeBar = ->
    height = Math.max($(window).height(), 600)
    $("#players_bar").width(height / 5)
    $("#chat_bar").width(height / 5)
    $("#boards").css({"margin-left" : height / 5})
    $("#boards").css({"margin-right" : height / 5 + 2})
    
  resizeBar()
  $(window).resize ->
    resizeBar()
  
  client = new Faye.Client 'http://localhost:3000/faye'
  userName = null
  opponent = null
  onMessage = (msg) ->
    console.dir(msg)
    
    if msg.type == "roll_dices"
      for p of msg.value
        console.log p
        if p != userName
          opponent = p
      if msg.value[userName] > msg.value[opponent]
        alert "Want to start?"
        client.publish "/play", { type: "start_player", value: 0 }
      else
        alert "Waiting #{opponent} decide"
    else if msg.type == "hand"
      App.PlayerHandView.set "cards", msg.value.map (obj, index) ->
        Em.Object.create obj, { number: index }
  
  $("#login button").click (e) ->
    userName = $("#user_name").val()
    
    if userName != null && userName != ""
      client.subscribe "/play/#{userName}", onMessage
      $(this).parent().slideUp()
      
    e.preventDefault()
    