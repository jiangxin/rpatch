require 'rpatch/error'

module Rpatch
  class PatchHunk
    attr_reader :title, :diffs, :num

    def initialize(text, num=nil)
      @title = text.chomp.sub(/^@@/, '').strip
      @num = num || "#"
      @diffs = []
    end

    def feed_line(line)
      diffs << line.chomp
    end

    # Patch lines in place.
    def patch(lines)
      matched_before = match_before_patch lines
      matched_after = match_after_patch lines

      if patterns_before_patch.size > patterns_after_patch.size
        if not matched_before
          if matched_after
            raise AlreadyPatchedError.new("Hunk #{num} (#{title}) is already patched.")
          else
            raise PatchHunkError, "Hunk #{num} (#{title}) FAILED to apply. Match failed."
          end
        end
      else
        if matched_after
          raise AlreadyPatchedError.new("Hunk #{num} (#{title}) is already patched.")
        elsif not matched_before
          raise PatchHunkError, "Hunk #{num} (#{title}) FAILED to apply. Match failed."
        end
      end

      n, size = matched_before
      lines[n...(n+size)] = convert lines[n...(n+size)]
      lines
    end

    # Apply patch on lines.
    # Return array of strings contain result of applying patch.
    def convert(lines)
      lines_dup = lines.dup
      result = []
      i = 0
      while i < @diffs.size
        case @diffs[i]
        when /^( |RE: )/
          while true
            match =  match_line lines_dup.first, patterns[i]
            if not match
              raise PatchFormatError.new("Hunk #{num} (#{title}) FAILED to apply. No match \"#{patterns[i]}\" with #{lines_dup.first.inspect}.")
            elsif match > 0
              result << lines_dup.shift
              break
            elsif match == 0
              result << lines_dup.shift
            end
          end
        when /^(-|RE:-)/
          while true
            match =  match_line lines_dup.first, patterns[i]
            if not match
              raise PatchFormatError.new("Hunk #{num} (#{title}) FAILED to apply. No match pattern \"#{patterns[i]}\" against #{lines_dup.first.inspect}.")
            elsif match > 0
              lines_dup.shift
              break
            elsif match == 0
              lines_dup.shift
            end
          end
        when /^\+/
          result << @diffs[i][1..-1]
        else
          raise PatchFormatError.new("Hunk #{num} (#{title}) FAILED to apply. Unknow syntax in hunk: #{@diffs[i]}")
        end
        i += 1
      end
      result
    end

    # Return [location, +num_of_lines], which seems already patched, and
    # match start with location and +num lines are matched.
    # Return nil, if nothing matched.
    def match_after_patch(lines)
      i = 0
      if patterns_after_patch.size == 0
        return [0, 0]
      end

      loop_n = lines.size
      loop_n = loop_n - patterns_after_patch.size + 1 if patterns_after_patch.size > 0
      while i < loop_n
        matched_line_no = match_beginning(lines[i..-1], patterns_after_patch)
        if matched_line_no
          return [i, matched_line_no]
        else
          i += 1
        end
      end
      nil
    end

    # Return [location, +num_of_lines], which could apply patch at
    # at location, and +num lines would be replaced.
    # Return nil, if nothing matched.
    def match_before_patch(lines)
      i = 0
      if patterns_before_patch.size == 0
        return [0, 0]
      end

      loop_n = lines.size
      loop_n = loop_n - patterns_before_patch.size + 1 if patterns_before_patch.size > 0

      while i < loop_n
        matched_size = match_beginning(lines[i..-1], patterns_before_patch)
        if matched_size
          return [i, matched_size]
        else
          i += 1
        end
      end
      nil
    end

    # Test whether patterns match against the beginning of lines
    # Return nil if not match, or return number of lines matched
    # with patterns (would be replaced later).
    def match_beginning(lines, patterns)
      i = 0
      found = true
      patterns.each do |pattern|
        unless lines[i]
          found = false
          break
        end

        while true
          match = match_line lines[i], pattern
          if not match
            found = false
            break
          # Match precisely for the first line of pattern (i==0),
          # Not pass blank lines.
          elsif match == 0 and i == 0
            found = false
            break
          # Matched.
          elsif match > 0
            break
          # Match next line if this line is blank.
          elsif match == 0
            i += 1
            unless lines[i]
              found = false
              break
            end
          # Never comes here.
          else
            found = false
            break
          end
        end

        break unless found
        i += 1
      end

      if found
        i
      else
        nil
      end
    end

    def match_line(message , pattern)
      return nil unless message
      line = nil
      match = nil
      while true
        if pattern.is_a? Regexp
          # When match with regexp, do not twick message
          line ||= message.dup
          if pattern.match(line)
            match = 1
          end
        else
          line ||= message.strip.gsub(/\s+/, ' ')
          if pattern == line
            match = 1
          end
        end

        if match
          break
        elsif line.empty?
          match = 0
          break
        elsif line.start_with? "#"
          while line.start_with? "#"
            line = line[1..-1]
            line = line.strip unless pattern.is_a? Regexp
          end
        else
          break
        end
      end
      match
    end

    def patterns_before_patch
      @patterns_before_patch ||= begin
        result = []
        @diffs.each do |line|
          case line
          when /^( |-)/
            result << line[1..-1].strip.gsub(/\s+/, ' ')
          when /^(RE: |RE:-)/
            result << Regexp.new(line[4..-1].strip)
          when /^\+/
            next
          else
            raise PatchFormatError.new("Unknown pattern in diffs: #{line}")
          end
        end
        result
      end
    end

    def patterns_after_patch
      @patterns_after_patch ||= begin
        result = []
        @diffs.each do |line|
          case line
          when /^( |\+)/
            result << line[1..-1].strip.gsub(/\s+/, ' ')
          when /^(RE: )/
            result << Regexp.new(line[4..-1].strip)
          when /^(-|RE:-)/
            next
          else
            raise PatchFormatError.new("Unknown pattern in diffs: #{line}")
          end
        end
        result
      end
    end

    def patterns
      @patterns ||= begin
        result = []
        @diffs.each do |line|
          case line
          when /^( |\+|-)/
            result << line[1..-1].strip.gsub(/\s+/, ' ')
          when /^(RE: |RE:-)/
            result << Regexp.new(line[4..-1].strip)
          else
            raise PatchFormatError.new("Unknown pattern in diffs: #{line}")
          end
        end
        result
      end
    end

  end
end
