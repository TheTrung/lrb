require "readline"
require "colorize"
require "bracer"
require "pry"

class Lrb
  attr_accessor :parser, :debug

  def initialize
    @_dbg = false
    @_indent = 0
    @_stack = Array.new
    @_parser = Bracer.new
    @_parser.ruby_keyword_literals = true
    readline_autocompletion
  end

  def parse source
    @_parser.parse_string source 
  end

  def repl
    begin
      while line = readline_with_hist_management
        @_stack << line
        if balanced?
          e = eval_source @_stack.join " "
          puts e.to_s.blue
          @_stack.clear
          @_indent = 0
        end
      end
    rescue Interrupt => e
      puts "\nGoodbye !".light_yellow
      exit
    end
  end

  def eval_file path
    source = File.read path
    eval_source source, mode = :compile
  end

  def eval_source source, mode = :repl
    begin
      e = to_ruby source
      evaluated = eval e
    rescue Exception => ex
      if @_dbg
        puts ex.backtrace.join("\n").red
        binding.pry 
      end
      puts ex.message.red
    end
    if @_dbg
      if mode == :compile
        puts "[LRB]:".light_yellow
        puts source.light_yellow
      end  
      puts e.light_green
      if mode == :compile
        puts "\n[evaluated]:".light_yellow
        puts "#{evaluated}".blue
      end
    end
    evaluated
  end

  def eval_list list
    eval list_to_ruby(list)
  end

  def list_to_ruby ast
    ast = ast.map do |sexp|
      result = transform sexp
      puts result if @_dbg
      result
    end
    ast.join "\n\n"
  end

  def to_ruby source
    ast = parse source 
    puts "parsed: #{ast}".green if @_dbg
    list_to_ruby ast
  end

  def transform sexp
    puts line if @_dbg
    if sexp.class == Array
      fun = sexp.first
      args = wrap_string sexp.drop(1)
      result = ""
      if @_dbg
        puts "function: #{fun}".yellow
        puts "args: #{args}".yellow
        puts line 
      end
      
      if KEYWORD.include? fun
        result = self.instance_exec *args, &KEYWORD[fun]
      elsif class_method? fun
        puts "[ERROR] dot operator only take 1 arg.".red if args.length > 1
        result = class_method_append fun, args.first
      else
        # function call
        result = compose_function fun, args
      end

      if @_dbg
        puts result.light_green
        puts line
      end
      indent + result
    else
      puts "#{sexp}".yellow if @_dbg
      sexp
    end
  end

  private
  def balanced?
    source = @_stack.join " "
    @left = source.count "["
    @right = source.count "]"
    @_indent = @left - @right if (@left - @right) > 0
    @left == @right
  end
  
  def readline_autocompletion
    @dict = KEYWORD.keys.sort

    comp = proc { |s| @dict.grep( /^#{Regexp.escape(s)}/ ) }

    Readline.completion_append_character = " "
    Readline.completion_proc = comp
  end

  def readline_with_hist_management
    line = Readline.readline('> ' + indent, true)
    return nil if line.nil?
    if line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
      Readline::HISTORY.pop
    end
    line
  end

  def class_method? function
    function[0] == "."
  end

  def class_method_append fun, args
    "(#{transform args})#{fun}"
  end

  def wrap_string args
    args.map do |arg| 
      if arg.class == String 
        "\"#{arg}\""
      else
        replace_parenthese arg
      end
    end
  end

  def replace_parenthese arg
    if arg.kind_of? Array
      arg = arg.map{ |element|
        replace_parenthese element
      }
      arg
    else
      if arg.to_s["("] && arg.to_s[")"]
        old = arg
        arg = arg.to_s.gsub(/\((.*)\)/, '[\1]').to_sym
        puts "arg: #{old} => #{arg}".light_yellow if @_dbg
        arg
      else
        arg
      end
    end
  end

  def transform_exp exps
    exps.map do |arg|
      unless arg.class == String
        transform arg 
      else
        arg
      end
    end
  end

  def compose_function fun, args
    args = transform_exp args
    "#{fun} #{args.join ', '}"
  end

  def indent
    "  " * @_indent
  end

  def line
    "-" * 80
  end

  def operator op, args
    args = args.map do |arg|
      transform arg
    end
    e = args.join " #{op.to_s} "
    "(#{e})"
  end

  def transform_body block
    if block.first.class == Array
      block.map{|body| transform body}.join "\n  "
    else
      transform block
    end
  end

  def conditional_block keyword, cond, true_block, false_block
    op = cond.first
    cond = cond.drop(1).join " #{op} "
    true_block = transform true_block
    false_block = transform false_block
    ["#{keyword} #{cond}",
      "    #{true_block}",
      "  else",
      "    #{false_block}",
      "  end"
    ].join("\n")
  end

  def single_block keyword, block
    block = transform_body block
    ["#{keyword}",
      "  #{block}",
      "end"
    ].join("\n")
  end

  KEYWORD = {
    :* => lambda {|*args| operator :*, args},
    :/ => lambda {|*args| operator :/, args},
    :- => lambda {|*args| operator :-, args},
    :+ => lambda {|*args| operator :+, args},
    :<< => lambda {|*args| operator :<<, args},
    :'^' => lambda {|*args| operator :'^', args},
    :'<' => lambda {|*args| operator :'<', args},
    :'>' => lambda {|*args| operator :'>', args},
    :'<=' => lambda {|*args| operator :'<=', args},
    :'>=' => lambda {|*args| operator :'>=', args},
    
    :'=' => lambda {|left, right| "#{left} = #{transform right}"},
    :== => lambda {|left, right| "#{transform left} == #{transform right}"},
    
    :quote => lambda {|*args|
        "#{args.first}"
      },
    :list => lambda {|*args|
        "[#{args.join ', '}]"
      },
    :lambda => lambda {|args, body|
        args = args.join ", "
        body = transform_body body
        ["lambda {|#{args}|",
          "  #{body}",
          "}"
        ].join("\n")  
      },
    :begin => lambda {|do_block, rescue_block| 
        do_block = transform_body do_block
        rescue_block = transform_body rescue_block
        ["begin",
          "  #{do_block}",
          "rescue Exception => e",
          "  #{rescue_block}",
          "end"
        ].join("\n")
      },
    :debug => lambda {
        @_dbg = !@_dbg
        puts "[DEBUG = #{@_dbg}]".light_yellow
        ""
        },
    :do => lambda {|fun, args, bodies|
        fun = transform fun
        args = args.join ", "
        bodies = transform_body bodies
        ["#{fun} do |#{args}|",
          "  #{bodies}",
          "end"
        ].join("\n")  
      },
    :class => lambda {|name, body|
        body = transform_body body
        ["class #{name}",
          "  #{body}",
          "end"
        ].join("\n")
      },
    :def => lambda {|args, body| 
        name = args.first
        args = args.drop(1).join ", "
        body = transform_body body
        ["def #{name} #{args}",
          "  #{body}",
          "end"
        ].join("\n")
      },
    :if => lambda {|cond, true_block, false_block|
        conditional_block :if, cond, true_block, false_block
      },
    :unless => lambda {|cond, true_block, false_block|
        conditional_block :unless, cond, true_block, false_block
      },
    :cond => lambda {|*conds|
        conds = conds.map{|cond| 
          transform cond
        }.each_slice(2).to_a
        cond_first = conds.first
        cond_body = conds.drop(1).map do |pair|
          ["elsif #{pair.first}",
            "  #{pair.last}"
            ].join "\n"
        end
        ["if #{cond_first.first}",
          "  #{cond_first.last}",
          cond_body,
          "end"
          ].join  "\n"
      }
  }
end
# @test = Lrb.new
# @test.debug = true
# x = @test.to_ruby <<-REC
# [= @a Hash.new]

# [= @a(:test) 1]

# [puts 
#   [.blue "HELLO ROSE"]]
# REC
# eval x
# @test.repl