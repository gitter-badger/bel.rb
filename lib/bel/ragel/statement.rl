=begin
%%{
  machine bel;

  action call_statement {fcall statement;}
  action statement {
    @statement = @statement_stack.pop
    @statement.annotations = @annotations.clone()

    if @statement_group
      statement_group.statements << @statement
    end

    changed
    notify_observers(@statement)
  }
  action statement_init {
    @statement = BEL::Script::Statement.new()
    @statement_stack = [@statement]
  }
  action statement_subject {
    @statement_stack.last.subject = @term
  }
  action statement_oterm {
    @statement_stack.last.object = @term
  }
  action statement_ostmt {
    nested = BEL::Script::Statement.new()
    @statement_stack.last.object = nested
    @statement_stack.push nested
  }
  action statement_pop {
    @statement = @statement_stack.pop
  }
  action rels {relbuffer = []}
  action reln {relbuffer << fc}
  action rele {
    rel = relbuffer.map(&:chr).join()
    @statement_stack.last.rel = rel.to_sym
  }
  action cmts {cmtbuffer = []}
  action cmtn {cmtbuffer << fc}
  action cmte {
    comment = cmtbuffer.map(&:chr).join()
    @statement_stack.first.comment = comment
  }

  include 'common.rl';
  include 'set.rl';
  include 'term.rl';

  comment = '//' ^NL+ >cmts $cmtn %cmte;
  statement :=
    FUNCTION '(' @term_init @term_fx @call_term SP* %statement_subject comment? NL? @statement @return
    RELATIONSHIP >rels $reln %rele SP+
    (
      FUNCTION '(' @term_init @term_fx @call_term %statement_oterm SP* ')'? @return
      |
      '(' @statement_ostmt @call_statement %statement_pop
    ) SP* comment? %statement NL @{n = 0} @return;
  
  statement_main :=
    (
      '\n' |
      any >statement_init >{fpc -= 1; fcall statement;}
    )+;
}%%
=end

require 'observer'
require_relative 'parse_objects'

module BEL
  module Script
    class Parser
      include Observable

      def initialize
        @annotations = {}
        @statement_group = nil
        %% write data;
      end

      def parse(content)
        eof = :ignored
        buffer = []
        stack = []
        data = content.unpack('C*')

        if block_given?
          observer = Observer.new(&Proc.new)
          self.add_observer(observer)
        end

        %% write init;
        %% write exec;

        if block_given?
          self.delete_observer(observer)
        end
      end
    end

    private

    class Observer
      include Observable

      def initialize(&block)
        @block = block
      end

      def update(obj)
        @block.call(obj)
      end
    end
  end
end

# intended for direct testing
if __FILE__ == $0
  if ARGV[0]
    content = (File.exists? ARGV[0]) ? File.open(ARGV[0], 'r:UTF-8').read : ARGV[0]
  else
    content = $stdin.read
  end

  class DefaultObserver
    def update(obj)
      puts obj
    end
  end

  parser = BEL::Script::Parser.new
  parser.add_observer(DefaultObserver.new)
  parser.parse(content) 
end
# vim: ts=2 sw=2:
# encoding: utf-8
