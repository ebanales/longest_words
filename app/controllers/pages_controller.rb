require 'open-uri'
require 'json'

class PagesController < ApplicationController
  def game
    @grid = generate_grid(9)
    @start_time = Time.now
  end

  def score
    @guess = params[:guess]
    @grid = params[:grid].split("")
    @start_time = Time.parse(params[:start_time])
    @end_time = Time.now
    @time = @end_time - @start_time
    @translation = get_translation(@guess)
    @score = score_and_message(@guess, @translation, @grid, @time)[0]
    @message = score_and_message(@guess, @translation, @grid, @time)[1]
  end

  private

  def generate_grid(grid_size)
    Array.new(grid_size) { ('A'..'Z').to_a[rand(26)] }
  end

  def included?(guess, grid)
    the_grid = grid.clone
    guess.chars.each do |letter|
      the_grid.delete_at(the_grid.index(letter)) if the_grid.include?(letter)
    end
    grid.size == guess.size + the_grid.size
  end

  def get_translation(word)
    response = open("http://api.wordreference.com/0.8/80143/json/enfr/#{word.downcase}")
    json = JSON.parse(response.read.to_s)
    json['term0']['PrincipalTranslations']['0']['FirstTranslation']['term'] unless json["Error"]
  end

  def compute_score(attempt, time_taken)
    (time_taken > 60.0) ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

  def score_and_message(guess, translation, grid, time)
    if translation
      if included?(guess.upcase, grid)
        score = compute_score(guess, time)
        [score, "well done"]
      else
        [0, "not in the grid"]
      end
    else
      [0, "not an english word"]
    end
  end
end
