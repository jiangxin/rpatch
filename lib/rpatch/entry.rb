#!/usr/bin/env ruby
#

require 'stringio'
require 'fileutils'
require 'rpatch/error'
require 'rpatch/hunk'

module Rpatch
  class PatchEntry
    attr_reader :level

    def initialize(old, new, level)
      @entry_old = old
      @entry_new = new
      @level = level
      @hunks = []
    end

    def oldfile
      @oldfile ||= path_strip_prefix(@entry_old, @level)
    end

    def newfile
      @newfile ||= path_strip_prefix(@entry_new, @level)
    end

    def feed_line(line)
      if line =~ /^@@/
        hunk = PatchHunk.new line, @hunks.size + 1
        @hunks << hunk
      elsif @hunks.any?
        @hunks[-1].feed_line line
      else
        raise PatchFormatError, "Feed lines must start with @@, not: #{line}"
      end
    end

    # Used in test cases.
    def patch_on_message(text)
      lines = text.split("\n").map{|line| line.chomp}

      @hunks.each do |hunk|
        hunk.patch(lines)
      end

      if lines.size > 0
        lines * "\n" + "\n"
      else
        ''
      end
    rescue Exception => e
      STDERR.puts "Error: #{e.message}"
    end

    def patch_on_file(input, output=nil)
      lines = []
      output ||= input
      if output.is_a? IO or output.is_a? StringIO
      	filename = "<#{newfile}>"
      else
      	filename = output
        unless File.exist?(File.dirname(output))
          FileUtils.mkdir_p File.dirname(output)
        end
      end

      if input.is_a? IO or input.is_a? StringIO
        lines = input.readlines.map{|line| line.chomp}
      elsif File.file? input
        File.open(input) do |io|
          lines = io.readlines.map{|line| line.chomp}
        end
      end
      lines_dup = lines.dup

      patch_applied = false
      patch_status = true
      @hunks.each do |hunk|
        begin
          hunk.patch(lines)
        rescue AlreadyPatchedError => e
          STDERR.puts "#{filename}: #{e.message}"
        rescue Exception => e
          STDERR.puts "ERROR: #{filename}: #{e.message}"
          patch_status = false
        else
          patch_applied = true
        end
      end

      if output.is_a? IO or output.is_a? StringIO
        output.write lines * "\n" + "\n"
      elsif not patch_applied
        STDERR.puts "#{filename}: nothing changed"
        if input != output
          File.open(output, "w") do |io|
            io.write lines * "\n" + "\n"
          end
        end
      else
        unless patch_status
          STDERR.puts "Warning: saved orignal file as \"#{output}.orig\"."
          File.open("#{output}.orig", "w") do |io|
            io.write lines_dup * "\n" + "\n"
          end
        end
        if lines.size > 0
          STDERR.puts "Patched \"#{output}\"."
          File.open(output, "w") do |io|
            io.write lines * "\n" + "\n"
          end
        else
          STDERR.puts "Remove \"#{output}\"."
          File.unlink output
        end
      end
      return patch_status
    end

    def patch_on_directory(inputdir, outputdir=nil)
      outputdir ||= inputdir
      if oldfile == '/dev/null'
        input = newfile.start_with?('/') ? newfile : File.join(inputdir, newfile)
      else
        input = oldfile.start_with?('/') ? oldfile : File.join(inputdir, oldfile)
      end
      output = newfile.start_with?('/') ? newfile : File.join(outputdir, newfile)
      patch_on_file(input, output)
    end

  private

    def path_strip_prefix(name, level)
      filename = name.dup
      unless filename.start_with? '/'
        level.times {filename.sub!(/^[^\/]+\//, '')}
      end
      filename
    end
  end
end
