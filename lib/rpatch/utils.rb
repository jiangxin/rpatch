require 'rpatch/error'

module Rpatch

  class Tty
    class << self
      def options
        @options ||= {:verbose => 0}
      end
      def blue; bold 34; end
      def white; bold 39; end
      def red; underline 31; end
      def yellow; underline 33 ; end
      def reset; escape 0; end
      def em; underline 39; end
      def green; color 92 end
      def gray; bold 30 end

      def width
        @width = begin
          w = %x{stty size 2>/dev/null}.chomp.split.last.to_i.nonzero?
          w ||= %x{tput cols 2>/dev/null}.to_i
          w < 1 ? 80 : w
        end
      end

      def die(*messages)
        error messages
        exit 1
      end

      def tty_puts(*args)
        opts = args.last.is_a?(Hash) ? args.pop : {}

        case (opts[:type] || :notice).to_s.downcase.to_sym
        when :error
          # always show errors
        when :warning
          return if verbose < -1
        when :notice
          return if verbose < 0
        when :info
          return if verbose < 1
        when :debug
          return if verbose < 2
        end

        lines = args.map{|m| m.to_s.split($/)}.flatten
        prompt = opts[:type] ? "#{opts[:type].to_s.upcase}: " : ""
        if opts[:type]
          if STDERR.tty?
            STDERR.write "#{Tty.red}#{prompt}#{Tty.reset}"
          else
            STDERR.write "#{prompt}"
          end
        end
        if STDERR.tty? and opts[:color] and Tty.respond_to? opts[:color]
          STDERR.puts "#{Tty.send(opts[:color])}#{lines.shift}#{Tty.reset}"
        else
          STDERR.puts lines.shift
        end
        spaces = " " * prompt.size
        lines.each do |line|
          STDERR.write spaces
          if STDERR.tty? and opts[:color] and Tty.respond_to? opts[:color]
            STDERR.puts "#{Tty.send(opts[:color])}#{line}#{Tty.reset}"
          else
            STDERR.puts line
          end
        end
      end

      def error(*messages)
        tty_puts(*messages << {:type => :error, :color => :red})
      end

      def warning(*messages)
        tty_puts(*messages << {:type => :warning, :color => :yellow})
      end

      def notice(*messages)
        tty_puts(*messages << {:type => nil})
      end

      def info(*messages)
        tty_puts(*messages << {:type => :info, :color => :green})
      end

      def debug(*messages)
        tty_puts(*messages << {:type => :debug, :color => :blue})
      end

      private

      def verbose
        options[:verbose]
      end

      def color n
        escape "0;#{n}"
      end
      def bold n
        escape "1;#{n}"
      end
      def underline n
        escape "4;#{n}"
      end
      def escape n
        "\033[#{n}m" if $stdout.tty?
      end

    end
  end
end

class String
  def charat(n)
    result = self.send "[]", n
    RUBY_VERSION < "1.9" ?  result.chr : result
  end
end
