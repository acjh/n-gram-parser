class WelcomeController < ApplicationController

  # Here's the description of the requirements:
  # 1. On the main home page, the user can enter a space-separated string to be used as the input (e.g. "A B C D")
  # 2. The platform should output the transformed version of the input string
  # 3. The lookup table should be implemented in a database (Postgres)
  # 4. The app should be deployable to Heroku (you can get a free account if you don't have one)

  def index
  end

  def transform
    input = params[:input].chomp.split(" ")
    @output = transform_helper(input)
    render :index
  end

  def get_ngrams_starting_with(word)
    require 'activerecord-jdbcpostgresql-adapter'
    conn = PGConn.open(:dbname => 'ngrams')
    conn.prepare('statement', 'SELECT id, w1, w2, w3, w4, v FROM ngrams_table WHERE w1 = $1')
    res = conn.exec_prepared('statement', [word])
    ngrams = []
    res.each do |row|
      ngrams += Ngram.new(row['id'], row['w1'], row['w2'], row['w3'], row['w4'], row['v'])
    end
    ngrams
  end

  def transform_tests()
    puts "Running tests..."
    puts transform_helper("A B C D E")     == ["Y1", "X3", "X4", "X5"]
    puts transform_helper("A B C D F")     == ["Y1", "Y3"]
    puts transform_helper("A B C D E F G") == ["Y1", "X3", "X4", "X5", "F", "G"]
    puts transform_helper("B C D E F G")   == ["Y2", "X5", "F", "G"]
    puts transform_helper("C D E F G")     == ["X3", "X4", "X5", "F", "G"]
    puts transform_helper("C D F G")       == ["Y3", "G"]
    puts transform_helper("C D G")         == ["Y4"]
    puts transform_helper("C D G A")       == ["Y4", "X1"]
    puts transform_helper("C D G A B")     == ["Y4", "Y1"]
    puts transform_helper("C D F A B")     == ["Y3", "Y1"]
  end

  class Ngram
  	attr_reader :v

    def initialize(id, w1, *w, v)
    	@id = id
  	  @w = [w1] + w
    	@v = v
    end

  	def next_word()
  		$w_index += 1
  		@w[$w_index - 1]
  	end

  	def has_more_words()
  		$w_index < @w.length
  	end
  end

  def transform_helper(input)
    $input = input
  	$output = []
  	$entries = []
  	$hold = []
  	$input_num = 0
  	$entry_num = 0
  	$w_index = 0

  	def has_more_input()
      $input_num < $input.length
  	end

  	def has_more_entries()
  		$entry_num < $entries.length
  	end

  	def next_input_token()
  		$input_num += 1
  		$input[$input_num - 1]
  	end

  	def peek_input_token()
  		$input[$input_num]
  	end

  	def discard_peeked_token()
  		$input_num += 1
  	end

  	def next_ngram_entry()
  		$entry_num += 1
  		$entries[$entry_num - 1]
  	end

  	def copy_of(string)
  		String.new(string)
  	end

  	def has_entries()
  		if $entries
  			$entries = [$entries].flatten
  			$entry_num = 0
  			$w_index = 0
  		end
  		$entries
  	end

  	def compare(str1, str2)
  		str1.casecmp(str2)
  	end

  	def roll_back()
  		$input_num -= $hold.length
  	   	$hold.clear
  	end

  	while has_more_input
  		front_token = peek_input_token
     	$output.push(copy_of(front_token))
     	$entries = get_ngrams_starting_with(front_token)
     	if !has_entries
  			discard_peeked_token
  		else
     		while has_more_entries
     			ngram = next_ngram_entry
     			while ngram.has_more_words && has_more_input
     				current_token = peek_input_token
     				word = ngram.next_word
     				compare_value = compare(word, current_token)
     				if compare_value == 0 	# Entry.word == input.word
     					discard_peeked_token
     					if ngram.has_more_words
     						$hold.push(copy_of(current_token))
     					else
     						$hold.clear
     						$output.pop
     						$output.push(copy_of(ngram.v))
     					end
     				elsif compare_value == -1 # Entry.word < input.word
     					next
     				elsif compare_value == 1  # Entry.word > input.word
     					roll_back
     				end
     			end
     			if $hold.any?
     				$w_index -= 1 # Check same word for next entry
     			end
     		end
    	end
    end
    $output
  end

end
