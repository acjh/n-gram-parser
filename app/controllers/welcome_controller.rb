class WelcomeController < ApplicationController

  # Here's the description of the requirements:
  # 1. On the main home page, the user can enter a space-separated string to be used as the input (e.g. "A B C D")
  # 2. The platform should output the transformed version of the input string
  # 3. The lookup table should be implemented in a database (Postgres)
  # 4. The app should be deployable to Heroku (you can get a free account if you don't have one)

  def index
  end

  def transform
    input = params[:input].split(" ")
    output = []

    database = {
    	"This" => ["That", "This", "Those"],
    	"New" => ["New", "New York"],
    	"York" => ["York"]
    }

    i = 0
    phrase = ""

    while i < input.length
    	phrase += input[i]
       	output.push(String.new(phrase))

       	entries = database[phrase]
       	if entries
       		entries = [entries].flatten
    	   	entries.each do |entry|
    			if entry.casecmp(phrase) == 0
    				output.pop
    				output.push(String.new(phrase))
    			elsif entry.casecmp(phrase) == 1
    				phrase.clear
    				break
    			end
    		end
    	end
    	phrase.clear
    	i += 1
    end

    @output = output
    render :index
  end

end
