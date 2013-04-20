$ ->
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
    if msg.type == "roll_dices"
      for p of msg.value
        console.log p
        if p != userName
          opponent = p
      if msg.value[userName] > msg.value[opponent]
        alert "Want to start?"
      else
        alert "Waiting #{opponent} decide"
        
    console.dir(msg)
  
  $("#login button").click (e) ->
    userName = $("#user_name").val()
    
    if userName != null && userName != ""
      client.subscribe "/play/#{userName}", onMessage
      $(this).parent().slideUp()
      
    e.preventDefault()
    