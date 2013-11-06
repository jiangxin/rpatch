#!/usr/bin/env ruby
#

require 'spec_helper'

describe Rpatch::PatchHunk do

  it "Regexp in pattern" do
    before = <<-EOF
    HeLLo
    world
    EOF

    diff = <<-EOF
/ [hH][eE][lL]{2}[oO]
+foo
+bar
    EOF

    after = <<-EOF
    HeLLo
foo
bar
    world
    EOF

    hunk = Rpatch::PatchHunk.new('@@ description')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq nil
    hunk.match_before_patch(before.split($/)).should eq [0, 1]
    result = hunk.patch(before.split($/))
    (result * "\n" + "\n").should eq after
  end

  it "Regexp in pattern (2)" do
    before = <<-EOF
Copyright 2013
    HeLLo
    world
--
jiangxin
    EOF

    diff = <<-EOF
/ [hH][eE][lL]{2}[oO]
+foo
+bar
/-wo*
+baz
    EOF

    after = <<-EOF
Copyright 2013
    HeLLo
foo
bar
baz
--
jiangxin
    EOF

    hunk = Rpatch::PatchHunk.new('@@ description')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq nil
    hunk.match_before_patch(before.split($/)).should eq [1, 2]
    result = hunk.patch(before.split($/))
    (result * "\n" + "\n").should eq after
  end

end
