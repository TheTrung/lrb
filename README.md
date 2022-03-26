# Lispy Ruby
[LRB] transform Ruby to a Lisp with braces, remain all ruby keywords and same funtionalities. 

Gem: https://rubygems.org/gems/lrb

\* Install:

    gem install lrb

\* To Start REPL:

    lrb

\* for debug mode:

    [debug] 

\* To compile & run a source file:

    lrb test.lrb

\* LRB source look like lisp, but with braces:

    [require "colorize"]

    [def [square x]
      [* x x]
    ]

    [def [factorial acc n]
      [if [< n 1]
        acc
        [factorial [* acc n] [- n 1]]]]


    [puts [square 10]]
    [puts [factorial 1 10]]


    [def [single_exp]
      [puts "only block !"]
    ]

    [def [multiple_exps][
        [puts "1st statement"]
        [puts "2nd statement"]
      ]
    ]

    [single_exp]
    [multiple_exps]


    [puts [== 1 1]]

    [= name :Trung.to_s ]
    [puts name]
    [puts [+ "Hello " name " \!"]]

    [= lst [list 1 2 3]]
    [= lst Array.new]
    [<< lst 4]
    [puts lst.to_s.blue]

    [puts [.to_s.blue [+ "Heell" "o"]]]

    [do [.map [list 1 2 3]] [n][
        [puts n]
      ]
    ]

    [unless [< 1 0]
      [puts "one is not lesser than zero"]
      [puts "you're doomed."]
    ]

    [= square 
      [lambda [x]
        [* x x]
      ]
    ]

    [puts 
      [.to_s.blue [square.call 2]]]

    [def [argumented x=2] 
      [puts x]
    ]

    [argumented]


    [cond 
      [< 1 0] [puts "1 < 0"]
      [> 3 4] [puts "3 > 4"]
      [<= 1 0] [puts "1 <= 0"]
      [>= 1 0] [puts "1 >= 0"]
      true    [puts "as always"]
    ]

\* By then, LRB compile down into Ruby:

    require "colorize"

    def square x
      x * x
    end

    def factorial acc, n
      if n < 1
        acc
      else
        factorial acc * n, n - 1
      end
    end

    puts square 10

    puts factorial 1, 10

    def single_exp 
      puts "only block !"
    end

    def multiple_exps 
      puts "1st statement"
      puts "2nd statement"
    end

    single_exp 

    multiple_exps 

    puts 1 == 1

    name = :Trung.to_s

    puts name

    puts "Hello " + name + " !"

    lst = [1, 2, 3]

    lst = Array.new

    lst << 4

    puts lst.to_s.blue

    puts ("Heell" + "o").to_s.blue

    ([1, 2, 3]).map do |n|
      puts n
    end

    unless 1 < 0
        puts "one is not lesser than zero"
      else
        puts "you're doomed."
      end

    square = lambda {|x|
      x * x
    }

    puts (square.call 2).to_s.blue

    def argumented x=2
      puts x
    end

    argumented 

    if 1 < 0
      puts "1 < 0"
    elsif 3 > 4
      puts "3 > 4"
    elsif 1 <= 0
      puts "1 <= 0"
    elsif 1 >= 0
      puts "1 >= 0"
    elsif true
      puts "as always"
    end


\* And evaluate everything:

    [evaluated]:
    100
    3628800
    only block !
    1st statement
    2nd statement
    true
    Trung
    Hello Trung !
    [4]
    Heello
    1
    2
    3
    one is not lesser than zero
    4
    2
    1 >= 0


Currently, it's only experiment toy, 
not yet support `repl` or `macros`.

Have fun !
