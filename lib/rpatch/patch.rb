
  REGEXP_VALID_HUNK_PREFIX = /^(@@| |-|\+|RE: |RE:-|<$|>$)/

          while not lines[i] =~ /^@@/ and lines[i]
          if lines[i] =~ REGEXP_VALID_HUNK_PREFIX
        when REGEXP_VALID_HUNK_PREFIX
      if lines.first =~ /^@@/ and old and new