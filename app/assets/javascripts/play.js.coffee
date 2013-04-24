window.App = Em.Application.create()

window.App.PlayerHandView = Ember.View.create
  templateName: "cards"
  cards: []
  
window.App.DialogView = Ember.View.create
  templateName: "dialog"
  text: ""
  buttons: []
  handler: null
  onButtonClick: (evt) ->
    this.get('handler')($(evt.target).text())
  
$ ->
  App.PlayerHandView.appendTo "#hand"
  
  resizeBar = ->
    height = Math.max($(window).height(), 600)
    $("#players_bar").width(height / 5)
    $("#chat_bar").width(height / 5)
    $("#boards").css({"margin-left" : height / 5})
    $("#boards").css({"margin-right" : height / 5 + 2})
    
  resizeBar()
  
  window.resetServer = ->
    $.get "/game/main", ->
      showDialog "Server reset!"
  
  $(window).resize ->
    resizeBar()
  
  client = new Faye.Client 'http://localhost:3000/faye'
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
        App.PlayerHandView.set "cards", msg.value.map (obj, index) ->
          Em.Object.create obj, { number: index }
        showDialog "Want to mulligan to #{Math.max(0, msg.value.length - 1)}?", ['Yes', 'No'], (value) ->
          if value == "Yes"
            client.publish "/play", { type: "mulligan" }
          else
            showDialog "Waiting for #{opponent}"
            client.publish "/play", { type: "keep" }
      when "start"
        showDialog "Game start"
  
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
    