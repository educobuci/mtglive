window.App = Em.Application.create()

window.App.PlayerHandView = Ember.View.create
  templateName: "cards"
  cards: []
  onCardClick: (evt) ->
    cardDiv = $(evt.target).parent()
    index = cardDiv.attr("data-number")
    client.publish "/play", { type: "play_card", value: index }
  
window.App.DialogView = Ember.View.create
  templateName: "dialog"
  text: ""
  buttons: []
  handler: null
  onButtonClick: (evt) ->
    this.get('handler')($(evt.target).text())
    
window.App.PlayerBoardView = Ember.View.create
  templateName: "cards"
  cards: []
  onCardClick: (evt) ->
    cardDiv = $(evt.target).parent()
    index = cardDiv.attr("data-number")
    client.publish "/play", { type: "tap_card", value: index }

$ ->
  $("#user_name").focus()
  App.PlayerHandView.appendTo "#hand"
  App.PlayerBoardView.appendTo "#player_board .lands"
  
  resizeBar = ->
    height = Math.max($(window).height(), 600)
    $("#players_bar").width(height / 5)
    $("#chat_bar").width(height / 5)
    $("#boards").css({"margin-left" : height / 5})
    $("#boards").css({"margin-right" : height / 5 + 2})
    
  resizeBar()
  
  window.resetServer = ->
    $.get "/game/main", ->
      window.location.reload()
  
  $(window).resize ->
    resizeBar()
  
  window.client = new Faye.Client 'http://localhost:3000/faye'
  userName = null
  opponent = null
  mulligan = 0
  onMessage = (msg) ->
    console.dir(msg)
    switch msg.type
      when "roll_dices"
        for p of msg.value
          console.log p
          if p != userName
            opponent = p
        if msg.value[userName] > msg.value[opponent]
          showDialog "Want to start?", ['Yes', 'No'], (value) ->
            client.publish "/play", { type: "start_player", value: (if value == 'Yes' then 0 else 1) }
        else
          showDialog "Waiting #{opponent} decide"
      when "hand"
        App.PlayerHandView.set "cards", msg.value.player.hand.map (obj, index) ->
          Em.Object.create obj, { number: index }
        showDialog "Want to mulligan to #{Math.max(0, msg.value.player.hand.length - 1)}?", ['Yes', 'No'], (value) ->
          if value == "Yes"
            client.publish "/play", { type: "mulligan" }
          else
            showDialog "Waiting for #{opponent}"
            client.publish "/play", { type: "keep" }
      when "info"
        App.PlayerHandView.set "cards", msg.value.player.hand.map (obj, index) ->
          Em.Object.create obj, { number: index }

        App.PlayerBoardView.set "cards", msg.value.player.board.map (obj, index) ->
          Em.Object.create obj, { number: index }
        
        if msg.value.current_player == userName
          showDialog "Phase #{msg.value.phase}", ["Ok"],  ->
            showDialog "Waiting for #{opponent}."
            client.publish "/play", { type: "pass" }
        else
          showDialog "Waiting for #{opponent}."
        
      when "pass"
        showDialog "Phase #{msg.value.phase}", ["Ok"],  ->
          client.publish "/play", { type: "pass" }    
    
    # switch phase
    #   when "first_main"
    #     showDialog "Main phase. Cast spells and activate abilities.", ["Ok"],  ->
    #       showDialog "Waiting for #{opponent}."
    #       client.publish "/play", { type: "pass" }
    #   when "begin_combat"
    #     showDialog "Begin combat. Select attackers.", ["Ok"],  ->
    #       showDialog "Waiting for #{opponent}."
    #       client.publish "/play", { type: "pass" } 
    #   when "begin_combat"
    #     showDialog "Begin combat. Select attackers.", ["Ok"],  ->
    #       showDialog "Waiting for #{opponent}."
    #       client.publish "/play", { type: "pass" }
              
  showDialog = (text, buttons, handler) ->
    App.DialogView.set "text", text
    App.DialogView.set "buttons", buttons
    App.DialogView.set "handler", handler
  
  $("#login button").click (e) ->
    userName = $("#user_name").val()
    
    if userName != null && userName != ""
      client.subscribe "/play/#{userName}", onMessage
      $(this).parent().slideUp()
      App.DialogView.appendTo "#dialog"
      
    e.preventDefault()
    