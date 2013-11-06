require 'optparse'
require 'rpatch/utils'
require 'rpatch/version'
require 'rpatch/patch'

module Rpatch
  class Runner
      class <<self
        def runner
          path = "."
          patches = []
          patch_level = 1

          OptionParser.new do |opts|
            opts.banner = "Usage: rpatch [options] [originalfile [patchfile]]"
            opts.on("-p", "--strip num", "Patch level") {|v| patch_level = v.to_i}
            opts.on("-V", "--version", "Show version") do
              puts "Version #{Rpatch::VERSION}"
              exit 0
            end
            opts.on("-v", "--verbose", "More verbose") {Tty.options[:verbose] += 1}
            opts.on("-q", "--quiet", "Less verbose") {Tty.options[:verbose] -= 1}
            opts.on_tail("-h", "--help", "Show this message") do
              puts opts
              exit 0
            end
          end.parse!

          case ARGV.size
          when 0
            patches << STDIN
          when 1
            path = ARGV.shift
            patches << STDIN
          else
            path = ARGV.shift
            until ARGV.empty? do
              patches << ARGV.shift
            end
          end

          result = Patch::apply(path, patches, patch_level)
          exit 1 unless result
      end
    end
  end
end
