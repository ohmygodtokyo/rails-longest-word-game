require 'open-uri'
require 'json'

class GamesController < ApplicationController

  def new
    @grid = generate_grid(10).join
    @start_time = Time.now
  end

  def score
    # Retrieve game date from form
    grid = params[:grid].split("")
    @attempt = params[:attempt]
    start_time = Time.parse(params[:start_time])
    end_time = Time.now

    # Compute score
    @result = new_game(@attempt, grid, start_time, end_time)
  end

  private

  def generate_grid(grid_size)
    Array.new(grid_size) { ('A'..'Z').to_a[rand(26)] }
  end

  def included?(guess, grid)
    guess.split("").all? { |letter| grid.include? letter }
  end

  def compute_score(attempt, time_taken)
    (time_taken > 60.0) ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

  def new_game(attempt, grid, start_time, end_time)
    result = { time: end_time - start_time }

    result[:translation] = get_translation(attempt)
    result[:score], result[:message] = score_and_message(attempt, result[:translation], grid, result[:time])
    result
  end

  def score_and_message(attempt, translation, grid, time)
    if translation
      if included?(attempt.upcase, grid)
        score = compute_score(attempt, time)
        [score, "welcome done"]
      else
        [0, "not in the grid"]
      end
    else
      [0, "not an english word"]
    end
  end

def get_translation(word)
  begin
    response = open("https://wagon-dictionary.herokuapp.com/#{URI.encode(word.downcase)}")
    json = JSON.parse(response.read)

    if json["Error"]
      return nil  # Handle the case where an error occurred
    end

    # Check if the response structure is as expected
    if json.dig('term0', 'PrincipalTranslations', '0', 'FirstTranslation', 'term')
      return json.dig('term0', 'PrincipalTranslations', '0', 'FirstTranslation', 'term')
    else
      return nil  # Handle unexpected response structure
    end
  rescue OpenURI::HTTPError => e
    puts "HTTP Error: #{e.message}"
    return nil  # Handle HTTP errors
  rescue JSON::ParserError => e
    puts "JSON Parsing Error: #{e.message}"
    return nil  # Handle JSON parsing errors
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
    return nil  # Handle other errors
  end
end

# def get_translation(word)
#   response = open("https://wagon-dictionary.herokuapp.com/#{word.downcase}")
#   json = JSON.parse(response.read.to_s)
#   json['term0']['PrincipalTranslations']['0']['FirstTranslation']['term'] unless json["Error"]
# end

end
