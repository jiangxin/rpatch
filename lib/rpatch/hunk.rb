require 'rpatch/error'

module Rpatch

  class Pattern
    attr_reader :text

    def initialize(line)
      @text = line.chomp
    end

    def is_in_before?
      @is_in_before ||= begin
        @text =~ /^( |-|\/ |\/-|\? |\?-|\?\/ |\?\/-)/
      end
    end

    def is_in_after?
      @is_in_after ||= begin
        @text =~ /^( |\+|\/ |\/\+)/
      end
    end

    def is_add?
      @is_add ||= begin
        @text =~ /^\+/
      end
    end

    def is_pattern?
      @is_pattern ||= pattern.is_a?(Regexp)
    end

    def pattern
      @pattern ||= begin
        if text =~ /^\/( |-|\+)/
          Regexp.new(text[2..-1].strip)
        elsif text =~ /^\?\/( |-|\+)/
          Regexp.new(text[3..-1].strip)
        elsif text =~ /^( |-|\+)/
          pattern = text[1..-1].strip.gsub(/\s+/, ' ')
        elsif text =~ /^\?( |-|\+)/
          pattern = text[2..-1].strip.gsub(/\s+/, ' ')
        else
          raise PatchFormatError.new("-0---Unknown pattern in diffs: #{text.inspect}")
        end
      end
    end

    def match(message)
      return nil unless message
      message = message.chomp
      match = nil
      while true
        if is_pattern?
          # When match with regexp, do not twick message
          if pattern.match(message)
            match = 1
          end
        else
          message = message.strip.gsub(/\s+/, ' ')
          if pattern == message
            match = 1
          end
        end

        if match
          break
        elsif message.empty?
          match = 0
          break
        # compare without leading "#"
        elsif message.start_with? "#"
          while message.start_with? "#"
            message = message[1..-1]
            message = message.strip unless is_pattern?
          end
        else
          break
        end
      end
      match
    end
  end

  class PatchHunk
    attr_reader :title, :diffs, :num

    def initialize(text, num=nil)
      @title = text.chomp.sub(/^@@/, '').strip
      @num = num || "#"
      @diffs = []
    end

    def feed_line(line)
      @diffs << line.chomp
    end

    def head?
      not tail?
    end

    def tail?
      diffs.first == ">"
    end

    def has_add?
      @has_add ||= begin
        patterns.select{|p| p.is_add?}.any?
      end
    end

    # Patch lines in place.
    def patch(lines)
      matched_before = match_before_patch lines
      matched_after = match_after_patch lines

      if matched_after
        if not matched_before
          raise AlreadyPatchedError.new("Hunk #{num} (#{title}) is already patched.")
        elsif has_add?
          raise AlreadyPatchedError.new("Hunk #{num} (#{title}) is already patched.")
        end
      elsif not matched_before
        raise PatchHunkError, "Hunk #{num} (#{title}) FAILED to apply. Match failed."
      end

      n, size = matched_before
      lines[n...(n+size)] = convert lines[n...(n+size)]
      lines
    end

    # Apply patch on lines.
    # Return array of strings contain result of applying patch.
    def convert(lines)
      lines = lines.dup
      result = []
      i = j = 0
      while i < diffs.size
        case diffs[i]
        when /^\??\/? /
          while true
            match =  patterns[j].match lines.first
            if not match
              raise PatchFormatError.new("Hunk #{num} (#{title}) FAILED to apply. No match \"#{patterns[j]}\" with #{lines.first.inspect}.")
            elsif match > 0
              result << lines.shift
              break
            elsif match == 0
              result << lines.shift
            end
          end
        when /^\??\/?[-]/
          while true
            match =  patterns[j].match lines.first
            if not match
              raise PatchFormatError.new("Hunk #{num} (#{title}) FAILED to apply. No match pattern \"#{patterns[j]}\" against #{lines.first.inspect}.")
            elsif match > 0
              lines.shift
              break
            elsif match == 0
              lines.shift
            end
          end
        when /^(\??\/?\+)/
          result << diffs[i][$1.size..-1]
        when /^(<|>)$/
          # patterns do not have locaiton direction
          j -= 1
        else
          raise PatchFormatError.new("Hunk #{num} (#{title}) FAILED to apply. Unknow syntax in hunk: #{diffs[i]}")
        end
        i += 1
        j += 1
      end
      result
    end

    # Return [location, +num_of_lines], which seems already patched, and
    # match start with location and +num lines are matched.
    # Return nil, if nothing matched.
    def match_after_patch(lines)
      if patterns_after_patch.size == 0
        return head? ? [0, 0] : [lines.size, 0]
      end

      if head?
        i = 0
        loop_n = lines.size - patterns_after_patch.size
        while i <= loop_n
          matched_size = get_matched_size(lines[i..-1], patterns_after_patch)
          if matched_size
            return [i, matched_size]
          else
            i += 1
          end
        end
      else
        i = lines.size - patterns_after_patch.size
        while i >= 0
          matched_size = get_matched_size(lines[i..-1], patterns_after_patch)
          if matched_size
            return [i, matched_size]
          else
            i -= 1
          end
        end
      end
      nil
    end

    # Return [location, +num_of_lines], which could apply patch at
    # at location, and +num lines would be replaced.
    # Return nil, if nothing matched.
    def match_before_patch(lines)
# puts "="*90
# puts patterns_before_patch.inspect
# puts patterns_before_patch.size
# puts "-"*90
# puts diffs.inspect
#puts "-"*90
#puts patterns.map{|p| [p.pattern.inspect, p.is_in_before?.inspect, p.is_in_after?.inspect]}.inspect
      if patterns_before_patch.size == 0
        return head? ? [0, 0] : [lines.size, 0]
      end

      if head?
        i = 0
        loop_n = lines.size - patterns_before_patch.size

        while i <= loop_n
          matched_size = get_matched_size(lines[i..-1], patterns_before_patch)
          if matched_size
            return [i, matched_size]
          else
            i += 1
          end
        end
      else
        i = lines.size - patterns_before_patch.size
        while i >= 0
          matched_size = get_matched_size(lines[i..-1], patterns_before_patch)
          if matched_size
            return [i, matched_size]
          else
            i -= 1
          end
        end
      end
      nil
    end

    # Test whether patterns match against the beginning of lines
    # Return nil if not match, or return number of lines matched
    # with patterns (would be replaced later).
    def get_matched_size(lines, patterns)
      i = 0
      found = true
      patterns.each do |pattern|
        unless lines[i]
          found = false
          break
        end

        while true
          match = pattern.match lines[i]
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

    def patterns_before_patch
      @patterns_before_patch ||= begin
        patterns.select{|p| p.is_in_before?}
      end
    end

    def patterns_after_patch
      @patterns_after_patch ||= begin
        patterns.select{|p| p.is_in_after?}
      end
    end

    def patterns
      @patterns ||= begin
        result = []
        diffs.each do |line|
          case line
          when /^(RE: |RE:-)/
            raise PatchFormatError.new("Obsolete pattern, subsitude \"RE:\" with \"/\":\n=> #{line}")
          when /^(<|>)$/
            # ignore locaiton direction
          else
            result << Pattern.new(line)
          end
        end
        result
      end
    end

  end
end
