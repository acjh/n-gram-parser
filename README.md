# [n-gram](https://en.wikipedia.org/wiki/N-gram) parser

Implemented in Ruby.

This challenge was a follow-up from a technical interview for an internship.<br/>
Run my test cases with `NgramParser.new.test_transform`.


## Use it:

1. Enter a space-separated string to be used as the input (e.g. "A B C D").<br/>
   `NgramParser.new.transform("A B C D")`<br/>
   `# "A" == "X1"`<br/>
   `# "B" == "X2"`<br/>
   `# "C" == "X3"`<br/>
   `# "D" == "X4"`<br/>
   `# "A B" == "Y1"`

2. Output is the transformed version of the input string!<br/>
   `# [ "Y1", "X3", "X4" ]`


## Extend it:

1. Add your own n-grams to the dictionary!<br/>
   `"New" => [Ngram.new(0, "New", "York", "NY")]`<br/>
   `# Three things to note:`<br/>
   `# 1. The key must be the first word.`<br/>
   `# 2. Any (reasonable) number of words.`<br/>
   `# 3. Last string is the transformed word.`

2. Try that it works!<br/>
   `NgramParser.new.transform("I love New York")`<br/>
   `# [ "I", "love", "NY" ]`
