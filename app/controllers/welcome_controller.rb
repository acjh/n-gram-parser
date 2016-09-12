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
    # Works for "B C D E"
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

    def compare(ngram, phrase)
    	entry = ngram.string
    	casecmp = entry.casecmp(phrase)
    	if casecmp == 0
    		$output.pop
    		$output.push(String.new(ngram.v))
    	elsif ngram.string.downcase.start_with?($phrase.downcase)
    		casecmp = -1
    	elsif casecmp == 1
    		$phrase.clear
    	end
    	casecmp
    end

    def compare_loop(ngram, phrase)
    	cmp = compare(ngram, $phrase)
    	if cmp == 0
    		$i += 1
    		if $i + 1 < $input.length
    			$phrase += $input[$i]
    		else
    			cmp = 1
    		end
    	elsif cmp == -1
    		$i += 1
    		if $i + 1 < $input.length
    			$phrase += $input[$i]
    			cmp = compare_loop(ngram, $phrase)
    		else
    			cmp = 1
    		end
    	end
    	cmp
    end

    while $i < $input.length
    	$phrase += $input[$i]
       	$output.push(String.new($phrase))

       	entries = $database[$phrase]
       	if entries
       		entries = [entries].flatten
    	   	entries.each do |ngram|
    	   		if compare_loop(ngram, $phrase) == 1
    	   			break
    	   		end
    		end
    	end
    	$phrase.clear
    end

    @output = $output
    render :index
  end
end
