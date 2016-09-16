class WelcomeController < ApplicationController

  # Here's the description of the requirements:
  # 1. On the main home page, the user can enter a space-separated string to be used as the input (e.g. "A B C D")
  # 2. The platform should output the transformed version of the input string
  # 3. The lookup table should be implemented in a database (Postgres)
  # 4. The app should be deployable to Heroku (you can get a free account if you don't have one)

  def index
  end

  @database_needs_initialize = true

  def transform
    if @database_needs_initialize
      initialize_database
      @database_needs_initialize = false
    end
    input = params[:input].chomp
    @output = transform_helper(input)
    render :index
  end

  def getConnection()
    # url = "jdbc:postgresql://localhost/ngram-parser_development"
    # conn = java::sql::DriverManager.getConnection(url, 'postgres', 'postgres')
    url = java::lang::System.getenv("DATABASE_URL")
    dbUri = URI(url)
    username = dbUri.userinfo.split(":")[0]
    password = dbUri.userinfo.split(":")[1]
    dbUrl = "jdbc:postgresql://" + dbUri.host + ':' + dbUri.port.to_s + dbUri.path
    conn = java::sql::DriverManager.getConnection(dbUrl, username, password)

  end

  def initialize_database()
    conn = getConnection

    drop_table = 'DROP TABLE IF EXISTS "ngrams";'
    conn.create_statement.execute_update(drop_table)

    create_table = 'CREATE TABLE "ngrams" (id INT NOT NULL, w1 CHAR(1) NOT NULL, w2 CHAR(1), w3 CHAR(1), w4 CHAR(1), v CHAR(2), PRIMARY KEY (id));'
    conn.create_statement.execute_update(create_table)

    insert_values = "INSERT INTO \"ngrams\" VALUES (1, 'A', DEFAULT, DEFAULT, DEFAULT, 'X1'), (2, 'B', DEFAULT, DEFAULT, DEFAULT, 'X2'), (3, 'A', 'B', DEFAULT, DEFAULT, 'Y1'), (4, 'C', DEFAULT, DEFAULT, DEFAULT, 'X3'), (5, 'D', DEFAULT, DEFAULT, DEFAULT, 'X4'), (6, 'B', 'C', 'D', DEFAULT, 'Y2'), (7, 'C', 'D', 'F', DEFAULT, 'Y3'), (8, 'C', 'D', 'G', DEFAULT, 'Y4'), (9, 'E', DEFAULT, DEFAULT, DEFAULT, 'X5');"
    conn.create_statement.execute_update(insert_values)

    conn.close
    test_transform
  end

  def get_ngrams_starting_with(word)
    conn = getConnection
    query = 'SELECT id, w1, w2, w3, w4, v FROM "ngrams" WHERE w1 = "#{word}";'
    result = conn.create_statement.execute_query(query)
    conn.close

    ngrams = []
    while result.next
      ngrams.push(Ngram.new(result.getInt('id'),
                            result.getString('w1'),
                            result.getString('w2'),
                            result.getString('w3'),
                            result.getString('w4'),
                            result.getString('v')))
    end
    ngrams
  end

  def test_transform()
    puts "Running tests..."
    puts transform_helper("A B C D")       == ["Y1", "X3", "X4"]
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
    puts "Tests ended."
  end

  class Ngram
  	attr_reader :v

    def initialize(id, w1, *w, v)
    	@id = id
  	  @w = ([w1] + w).compact
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
    $input = input.split(" ")
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
  		has_entries = false
  		if $entries.any?
  			has_entries = true
  			$entry_num = 0
  			$w_index = 0
  		end
  		has_entries
  	end

  	def compare(str1, str2)
        str1 ? str1.casecmp(str2) : -1
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
     				if compare_value == 0 # Entry.word == input.word
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
     				$w_index = 0 # Check from start for next entry, not just wrong word
     				roll_back    # Otherwise "C D G" will fail "C D F" and pass "C E G"
     			end
     		end
    	end
    end
    $output
  end

end
