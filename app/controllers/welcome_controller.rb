class WelcomeController < ApplicationController

  # Here's the description of the requirements:
  # 1. On the main home page, the user can enter a space-separated string to be used as the input (e.g. "A B C D")
  # 2. The platform should output the transformed version of the input string
  # 3. The lookup table should be implemented in a database (Postgres)
  # 4. The app should be deployable to Heroku (you can get a free account if you don't have one)

  def index
  end

  def transform
    $input = "This is New York".chomp.split(" ")
    $output = []

    $database = {
    	"This" => ["That", "This", "Those"],
    	"is" => ["is"],
    	"New" => ["New", "New York"],
    	"York" => ["York"]
    }

    $i = 0
    $phrase = ""

    def compare(entry, phrase)
    	casecmp = entry.casecmp(phrase)
    	if casecmp == 0
    		$output.pop
    		$output.push(String.new(phrase))
    	elsif casecmp == 1
    		phrase.clear
    	end
    	casecmp
    end

    while $i < $input.length
    	$phrase += $input[$i]
       	$output.push(String.new($phrase))

       	entries = $database[$phrase]
       	if entries
       		entries = [entries].flatten
    	   	entries.each do |entry|
    			if compare(entry, $phrase) == 1
    				break
    			end
    		end
    	end
    	$phrase.clear
    	$i += 1
    end

    @output = output
    render :index
  end

end
