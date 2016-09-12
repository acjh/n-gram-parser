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

    $input_num = 0
    $hold_count = 0
    $phrase = ""

    def matches(cmp)
    	cmp == 0
    end

    def matches_front_only(cmp, ngram, phrase)
    	!matches(cmp) && ngram.string.start_with?(phrase)
    end

    def does_not_match(cmp)
    	cmp == 1
    end

    def has_more_words()
    	$input_num += 1
    	$input_num < $input.length
    end

    def next_word()
    	$input[$input_num]
    end

    def step_back_words()
    	$input_num -= 1 + $hold_count
    	$hold_count = 0
    end

    def compare(ngram, phrase)
    	cmp = ngram.string.casecmp(phrase)
    	puts "#{ngram.string} == #{phrase} : #{cmp}"

    	if matches(cmp)
    		$hold_count = -1
    		$output.pop
    		$output.push(copy_of(ngram.v))
    		if has_more_words
    			$phrase += next_word
    		end

    	elsif matches_front_only(cmp, ngram, phrase)
    		if has_more_words
    			$hold_count += 1
    			$phrase += next_word
    			compare(ngram, $phrase)
    		end

    	elsif does_not_match(cmp)
    		step_back_words
    	   	$phrase.clear
    	end
    end

    def copy_of(string)
    	String.new(string)
    end

    while $input_num < $input.length
    	$phrase += $input[$input_num]
       	$output.push(copy_of($phrase))
       	entries = $database[$phrase]
       	if entries
       		[entries].flatten.each do |ngram|
    	   		compare(ngram, $phrase)
    		end
    	else
    		$input_num += 1
    	end
    	$phrase.clear
    end

    @output = $output
    render :index
  end
end
