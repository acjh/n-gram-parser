class WelcomeController < ApplicationController

  # Here's the description of the requirements:
  # 1. On the main home page, the user can enter a space-separated string to be used as the input (e.g. "A B C D")
  # 2. The platform should output the transformed version of the input string
  # 3. The lookup table should be implemented in a database (Postgres)
  # 4. The app should be deployable to Heroku (you can get a free account if you don't have one)

  def index
  end

  class Ngram
    attr_reader :v

    def initialize(id, w1, w2="", w3="", w4="", v)
      @id = id
      @w1 = w1
      @w2 = w2
      @w3 = w3
      @w4 = w4
      @v = v
    end

    def string
      string = @w1 + @w2 + @w3 + @w4
    end
  end

  def transform
    # Works for "A B C D F"
    $input = params[:input].chomp.split(" ")
    $output = []

    $database = {
    	"A" => [Ngram.new(1, "A",           "X1"),
    			    Ngram.new(3, "A",      "B", "Y1")],
    	"B" => [Ngram.new(2, "B",           "X2"),
    			    Ngram.new(6, "B", "C", "D", "Y2")],
    	"C" => [Ngram.new(4, "C",           "X3"),
    			    Ngram.new(7, "C", "D", "F", "Y3"),
    			    Ngram.new(8, "C", "D", "G", "Y4")],
    	"D" => [Ngram.new(5, "D",           "X4")],
    	"E" => [Ngram.new(9, "E",           "X5")]
    }

    $i = 0
    $phrase = ""

    def compare_loop(ngram, phrase)
    	entry = ngram.string
    	cmp = entry.casecmp(phrase)

    	if cmp == 0 # Matches fully
    		$output.pop
    		$output.push(String.new(ngram.v))

    	elsif ngram.string.downcase.start_with?($phrase.downcase) # Matches front
    		$inputNum += 1
    		if $inputNum < $input.length
    			$phrase += $input[$inputNum]
    			cmp = compare_loop(ngram, $phrase)
    		else
    			cmp = 1
    		end
    	end

    	if cmp == 1 # No more matches
    		$inputNum -= 1
    		$phrase.clear
    	end
    	cmp
    end

    while $inputNum < $input.length
    	$phrase += $input[$inputNum]
       	$output.push(String.new($phrase))

       	entries = $database[$phrase]
       	if entries
       		entries = [entries].flatten
       		entryNum = 0
    	   	until entryNum == entries.size do
    	   		ngram = entries[entryNum]
    	   		cmp = compare_loop(ngram, $phrase)
    	   		if cmp == 0 # Matches current entry && has more
    	   			$inputNum += 1
    				if $inputNum < $input.length
    					$phrase += $input[$inputNum]
    				end
    	   		elsif cmp == 1
    	   			$inputNum += 1
    	   			break
    	   		end
    	   		entryNum += 1
    		end
    	end
    	$phrase.clear
    end

    @output = $output
    render :index
  end
end
