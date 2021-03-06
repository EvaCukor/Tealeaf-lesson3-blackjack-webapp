require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry'

set :sessions, true

BLACKJACK = 21
DEALER_MIN_HIT = 17

helpers do
  def calculate_total(cards)
    arr = cards.map{|e| e[1] }

    total = 0
    arr.each do |value|
      if value == "ace"
        total += 11
      elsif value.to_i == 0
        total += 10
      else
        total += value.to_i
      end
    end

    arr.select{|e| e == "ace"}.count.times do
      total -= 10 if total > 21
    end

    total
  end

  def image_source(card)
    "<img src='/images/cards/" + card[0] + "_" + card[1] + ".jpg' class='card_image' />"
  end

  def winner!(msg)
    @show_hit_stay_buttons = false
    @play_again = true
    @success = "<strong>Congratulations, #{session[:player_name]}. You have won!</strong> #{msg}"
  end

  def loser!(msg)
    @show_hit_stay_buttons = false
    @play_again = true
    @error = "<strong>Sorry, #{session[:player_name]}. You have lost.</strong> #{msg}"
  end

  def tie!(msg)
    @show_hit_stay_buttons = false
    @play_again = true
    @success = "<strong>It's a tie!</strong> #{msg}"
  end
end

before do
  @show_hit_stay_buttons = true
  @dealer_hidden_card = true
  @play_again = false
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "You must enter your name."
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  suits = ['hearts', 'diamonds', 'spades', 'clubs']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace']

  session[:deck] = suits.product(values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK
    winner!("You hit blackjack.")
  elsif player_total > BLACKJACK
    loser!("You busted at #{player_total}.")
  end
  erb :game
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  @show_hit_stay_buttons = false
  @dealer_hidden_card = false

  redirect '/game/dealer'
end

get '/game/dealer' do
  @dealer_hidden_card = false
  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK
    loser!("The dealer hit blackjack.")
  elsif dealer_total > BLACKJACK
    winner!("The dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN_HIT
    #dealer stays
    redirect '/game/compare'
  else
    #dealer hits
    @dealer_hit_btn = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_stay_buttons = false
  @dealer_hidden_card = false
  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])
  if dealer_total > player_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif dealer_total < player_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{dealer_total}.")
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end