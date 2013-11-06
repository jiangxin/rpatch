#!/usr/bin/env ruby
#

require 'spec_helper'

describe Rpatch::PatchHunk do

  it "Question mark expression in pattern" do
    before = <<-EOF
original text
end of text
    EOF

    diff = <<-EOF
? original text
+    foobar
    EOF

    after = <<-EOF
original text
    foobar
end of text
    EOF

    hunk = Rpatch::PatchHunk.new('@@ description')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq nil
    hunk.match_before_patch(before.split($/)).should eq [0, 1]
    result = hunk.patch(before.split($/))
    (result * "\n" + "\n").should eq after
  end

  it "Question mark expression in pattern (2)" do
    before = <<-EOF
original text
end of text
    EOF

    diff = <<-EOF
? original text
?+    # comment for foobar
+    foobar
    EOF

    after = <<-EOF
original text
    # comment for foobar
    foobar
end of text
    EOF

    hunk = Rpatch::PatchHunk.new('@@ description')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq nil
    hunk.match_before_patch(before.split($/)).should eq [0, 1]
    result = hunk.patch(before.split($/))
    (result * "\n" + "\n").should eq after
  end

  it "Question mark expression in pattern (3)" do
    before = <<-EOF
changed original contents
  foobar
end of text
    EOF

    diff = <<-EOF
? original text
?+    # comment for foobar
+    foobar
    EOF

    after = <<-EOF
changed original contents
  foobar
end of text
    EOF

    hunk = Rpatch::PatchHunk.new('@@ patch with qmark')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq [1, 1]
    hunk.match_before_patch(before.split($/)).should eq nil
    expect {
      hunk.patch(before.split($/))
    }.to raise_exception Rpatch::AlreadyPatchedError, /Hunk # \(patch with qmark\) is already patched\./
  end

  it "Question mark expression in pattern (4)" do
    before = <<-EOF
Copyright 2013, jiangxin
  foo
  baz

  bar
bye.
    EOF

    diff = <<-EOF
?/ [cC]opyright [0-9]{4}
? Hello, world
?+
+    baz
    EOF

    after = before.dup

    hunk = Rpatch::PatchHunk.new('@@ patch with qmark')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq [2, 1]
    hunk.match_before_patch(before.split($/)).should eq nil
    expect {
      hunk.patch(before.split($/))
    }.to raise_exception Rpatch::AlreadyPatchedError, /Hunk # \(patch with qmark\) is already patched\./
  end

  it "Question mark expression in pattern (5)" do
    before = <<-EOF
Copyright 2013, jiangxin
Hello, world
  foo
  baz

  bar
bye.
    EOF

    diff = <<-EOF
?/ [cC]opyright [0-9]{4}
? Hello, world
?+
+    baz
    EOF

    after = before.dup

    hunk = Rpatch::PatchHunk.new('@@ patch with qmark')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq [3, 1]
    hunk.match_before_patch(before.split($/)).should eq [0, 2]
    hunk.patterns_before_patch.size.should eq 2
    hunk.patterns_after_patch.size.should eq 1
    expect {
      hunk.patch(before.split($/))
    }.to raise_exception Rpatch::AlreadyPatchedError, /Hunk # \(patch with qmark\) is already patched\./
  end

end
