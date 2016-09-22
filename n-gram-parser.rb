class NgramParser

  # Usage:
  # 1. Enter a space-separated string to be used as the input (e.g. "A B C D")
  # 2. Output is the transformed version of the input string

  def test_transform()
    puts "Running tests..."
    puts transform("A B C D")       == ["Y1", "X3", "X4"]
    puts transform("A B C D E")     == ["Y1", "X3", "X4", "X5"]
    puts transform("A B C D F")     == ["Y1", "Y3"]
    puts transform("A B C D E F G") == ["Y1", "X3", "X4", "X5", "F", "G"]
    puts transform("B C D E F G")   == ["Y2", "X5", "F", "G"]
    puts transform("C D E F G")     == ["X3", "X4", "X5", "F", "G"]
    puts transform("C D F G")       == ["Y3", "G"]
    puts transform("C D G")         == ["Y4"]
    puts transform("C D G A")       == ["Y4", "X1"]
    puts transform("C D G A B")     == ["Y4", "Y1"]
    puts transform("C D F A B")     == ["Y3", "Y1"]
    puts "Tests ended."
  end

  def transform(input)
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
      if $entries && $entries.any?
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
      $entries = $database[front_token]
      if !has_entries
        discard_peeked_token
      else
        while has_more_entries
          ngram = next_ngram_entry
          while ngram.has_more_words && has_more_input
            current_token = peek_input_token
            word = ngram.next_word
            compare_value = compare(word, current_token)
            if compare_value == 0   # Entry.word == input.word
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

  def initialize()
    initialize_database
  end

  def initialize_database()
    $database = {
      "A" => [Ngram.new(1, "A",           "X1"),
              Ngram.new(3, "A", "B",      "Y1")],
      "B" => [Ngram.new(2, "B",           "X2"),
              Ngram.new(6, "B", "C", "D", "Y2")],
      "C" => [Ngram.new(4, "C",           "X3"),
              Ngram.new(7, "C", "D", "F", "Y3"),
              Ngram.new(8, "C", "D", "G", "Y4")],
      "D" => [Ngram.new(5, "D",           "X4")],
      "E" => [Ngram.new(9, "E",           "X5")],

      "New" => [Ngram.new(0, "New", "York", "NY")]
    }
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

end
