#!/usr/bin/env ruby
#

require 'spec_helper'

describe Rpatch::PatchHunk do

  it "patch has default location direction" do
    diff = <<-EOF
+foo
+bar
    EOF

    before = <<-EOF
hello
world
    EOF

    after = <<-EOF
foo
bar
hello
world
    EOF

    hunk = Rpatch::PatchHunk.new('@@ description')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq nil
    hunk.match_before_patch(before.split($/)).should eq [0, 0]
    result = hunk.patch(before.split($/))
    (result * "\n" + "\n").should eq after
  end

  it "patch has head location direction" do
    diff = <<-EOF
<
+foo
+bar
    EOF

    before = <<-EOF
hello
world
    EOF

    after = <<-EOF
foo
bar
hello
world
    EOF

    hunk = Rpatch::PatchHunk.new('@@ description')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq nil
    hunk.match_before_patch(before.split($/)).should eq [0, 0]
    result = hunk.patch(before.split($/))
    (result * "\n" + "\n").should eq after
  end

  it "patch has tail location direction" do
    diff = <<-EOF
>
+foo
+bar
    EOF

    before = <<-EOF
hello
world
    EOF

    after = <<-EOF
hello
world
foo
bar
    EOF

    hunk = Rpatch::PatchHunk.new('@@ description')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq nil
    hunk.match_before_patch(before.split($/)).should eq [2, 0]
    result = hunk.patch(before.split($/))
    (result * "\n" + "\n").should eq after
  end

  it "patch has head location direction (2)" do
    diff = <<-EOF
<
 hello
+foo
+bar
    EOF

    before = <<-EOF
hello
hello
    EOF

    after = <<-EOF
hello
foo
bar
hello
    EOF

    hunk = Rpatch::PatchHunk.new('@@ description')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq nil
    hunk.match_before_patch(before.split($/)).should eq [0, 1]
    result = hunk.patch(before.split($/))
    (result * "\n" + "\n").should eq after
  end

  it "patch has tail location direction (2)" do
    diff = <<-EOF
>
 hello
+foo
+bar
    EOF

    before = <<-EOF
hello
hello
    EOF

    after = <<-EOF
hello
hello
foo
bar
    EOF

    hunk = Rpatch::PatchHunk.new('@@ description')
    diff.split($/).each {|line| hunk.feed_line line.chomp}

    hunk.match_after_patch(before.split($/)).should eq nil
    hunk.match_before_patch(before.split($/)).should eq [1, 1]
    result = hunk.patch(before.split($/))
    (result * "\n" + "\n").should eq after
  end

end
