window.App = Em.Application.create()

window.App.gameController = Ember.Object.create
  content: Em.Object.create
    name: "PlayerX"
    life: 18
    hand: 6
    lib: 48
  update: ->
    $.get "game.json", (data) ->
      me = data.me

      App.Player1BattlefieldView.set "cards", me.battlefield.map (obj, index) ->
        Em.Object.create obj, { number: index }

      App.PlayerHandView.set "cards", me.hand.map (obj, index) ->
        Em.Object.create obj, { number: index }
    
window.App.PlayerView = Em.View.extend
  #templateName: "playerTemplate"
  #mouseDown: ->
  #  window.alert "hello world! #{this.player.name}"
  nameBinding: 'App.gameController.content.name'
  lifeBinding: 'App.gameController.content.life'
  handBinding: 'App.gameController.content.hand'
  libBinding:  'App.gameController.content.lib'

window.App.PlayerHandView = Ember.View.create
  templateName: "cards"
  cards: []

window.App.Player1BattlefieldView = Ember.View.create
  templateName: "cards"
  cards:[]

$ ->
  App.Player1BattlefieldView.appendTo "#player-1 .creatures"
  App.PlayerHandView.appendTo "#hand"
  
  App.gameController.update()
  
  $("#phase_bar").click ->
    $.get "/game/pass_phase", ->
      window.App.gameController.update()
    
  $("#hand .card").live "click", ->
    number = $(this).attr("data-number")
    $.post "/game/play_card.json", {card: number}, ->
      window.App.gameController.update()

  $(".battlefield .card").live "click", ->
    number = $(this).attr("data-number")
    $.post "/game/tap_card.json", {card: number}, ->
      window.App.gameController.update()

