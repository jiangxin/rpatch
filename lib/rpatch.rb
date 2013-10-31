#!/usr/bin/env ruby
#

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'rpatch/patch'
require_relative 'rpatch/entry'
require_relative 'rpatch/hunk'
require_relative 'rpatch/error'
