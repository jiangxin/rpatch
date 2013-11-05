require 'optparse'
require 'rpatch/patch'
require 'rpatch/version'

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
            opts.on("-v", "--version", "Show version") do
              puts "Version #{Rpatch::VERSION}"
              exit 0
            end
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
