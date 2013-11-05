#!/usr/bin/env ruby
#

require 'rpatch/error'
require 'rpatch/entry'

module Rpatch
  class Patch
    attr_reader :name, :level, :patch_entries

    class <<self
      def apply(path, patches, patch_level)
        unless File.exist? path
          raise FileNotExistError, "File or directory \"#{path}\" does not exist"
        end
        patch_status = true
        patches.each do |patch_file|
          if patch_file.is_a? IO or patch_file.is_a? StringIO
            apply_one(path, patch_file, patch_level) || patch_status = false
          elsif File.file? patch_file
            apply_one(path, patch_file, patch_level) || patch_status = false
          elsif File.directory? patch_file
            apply_quilt(path, patch_file, patch_level) || patch_status = false
          else
            raise FileNotExistError, "Can not find patch file: #{patch_file}"
          end
        end
        patch_status
      rescue Exception => e
        STDERR.puts "Error: #{e.message}"
        patch_status = false
      end
    end

    def initialize(file, level)
      @name = file.is_a?(String) ? file : "<#{file.class.to_s}>"
      @patch = file
      @level = level
      @patch_entries = []
      load_patch
    end

    def apply_to(input, output=nil)
      patch_status = true
      patch_entries.each do |patch_entry|
        begin
          # input maybe a IO, StringIO, directory, file, or in-exist file.
          if input.is_a? String and File.directory? input
            patch_entry.patch_on_directory(input, output) || patch_status = false
          else
            if patch_entries.size > 1
              raise PatchOneWithManyError, "Multiple patch entries (#{patch_entries.size}) have been found in patch #{name}"
            end
            # a IO, StringIO, file, or inexist file.
            patch_entry.patch_on_file(input, output) || patch_status = false
          end
        rescue Exception => e
          STDERR.puts "Error: #{e.message}"
          patch_status = false
        end
      end
      patch_status
    end

  private

    class <<self
      def apply_one(path, patch_file, patch_level)
        patch = Patch.new(patch_file, patch_level)
        patch.apply_to(path)
      end

      def apply_quilt(path, quilt_dir, patch_level)
        patch_status = true
        if File.exist?("#{quilt_dir}/series")
          File.open("#{quilt_dir}/series") do |io|
            io.readlines.each do |line|
              line.strip!
              filename = line
              level = patch_level
              if line =~ /^(.*?)[\s]+-p([0-9]*)$/
                filename = $1
                level = $2
              end
              unless filename.start_with? '#'
                apply_one(path, File.join(quilt_dir, filename), level) || patch_status = false
              end
            end
          end
        else
          raise FileNotExistError, "Can not find (quilt) patchs in dir: #{quilt_dir}"
        end
        patch_status
      end
    end

    def load_patch
      i=0
      lines = get_patch
      while i < lines.size
        entry_names = find_new_entry(lines[i..i+6])
        if entry_names
          @patch_entries << PatchEntry.new(entry_names[0], entry_names[1], @level)
          while not lines[i] =~ /^@@ / and lines[i]
            i += 1
          end
          break unless i < lines.size
        end

        if @patch_entries.any?
          if lines[i] =~ /^(@@| |-|\+|RE: |RE:-)/
            @patch_entries.last.feed_line lines[i]
          elsif lines[i] =~ /^(Binary files |Only in)/
            # ignore
          else
            raise PatchFormatError, "Line #{i} of patch \"#{name}\" is invalid.\n\t=> #{lines[i].inspect}"
          end
        end

        i += 1
      end
    end

    def get_patch
      if @patch.is_a? IO or @patch.is_a? StringIO
        @patch.readlines.map {|line| line.chomp}
      else
        File.open(@patch) do |io|
          io.readlines.map {|line| line.chomp}
        end
      end
    end

    def find_new_entry(lines)
      old = new = nil
      lines = lines.dup
      while lines.first
        case lines.first
        when /^--- (.+?)([\s]+[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.*)?$/
          old = $1
        when /^\+\+\+ (.+?)([\s]+[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.*)?$/
          new = $1
        when /^(@@| |-|\+|RE: |RE:-)/
          break
        when /^(diff |new file mode|index )/
            # Ignore GNU/Git diff header
        when /^(Index:|=+)/
            # Ignore quilt patch header
        else
            # Ignore comments in the header
        end
        lines.shift
      end

      if lines.first =~ /^@@ / and old and new
        [old, new]
      else
        nil
      end
    end
  end

end
