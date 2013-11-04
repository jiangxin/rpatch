#!/usr/bin/env ruby
#

require 'rubygems'
require 'spec_helper'

describe Rpatch::PatchHunk do

  let(:hunk_text) do
    <<-EOF
+/*
+ * Copyright (c) 2013 Jiang Xin
+ */
+
 When I hack files using GNU patch,
 sometimes fail because of the change of upstream files.
 If patch can ignore blank lines, support regex patterns
 in patch, it will be nice.
+So comes rpatch.
+
 Happy hacking.
-
--- jiangxin
+--
+jiangxin
    EOF
  end

  let(:patch_hunk) do
    hunk = Rpatch::PatchHunk.new('@@ description')
    hunk_text.lines.each do |line|
      hunk.feed_line line.chomp
    end
    hunk
  end

  it "Initial with description only" do
    title = "foo.bar"
    Rpatch::PatchHunk.new("@@ #{title}").title.should be == title
  end

  it "Initial with zero patterns_before_patch.size and zero patterns_after_patch.size" do
    Rpatch::PatchHunk.new("@@ test").diffs.size.should be == 0
    Rpatch::PatchHunk.new("@@ test").patterns_before_patch.size.should be == 0
    Rpatch::PatchHunk.new("@@ test").patterns_after_patch.size.should be == 0
  end


  it "patch_hunk's desc and contents test" do
    patch_hunk.title.should be == 'description'
    patch_hunk.diffs.size.should be == hunk_text.split("\n").size
    patch_hunk.patterns.size.should be == 15
  end

  it "should have 7 patterns_before_patch.sizes" do
    patch_hunk.patterns_before_patch.size.should be == 7
    patch_hunk.patterns_before_patch.size.should be == 7
  end

  it "should have 13 patterns_after_patch.sizes" do
    patch_hunk.patterns_after_patch.size.should be == 13
    patch_hunk.patterns_after_patch.size.should be == 13
  end

  it "patch success (1)" do
    before = <<-EOF
When I hack files using GNU patch,
sometimes fail because of the change of upstream files.
If patch can ignore blank lines, support regex patterns
in patch, it will be nice.
Happy hacking.

-- jiangxin
    EOF
    before_lines = before.split("\n")
    before_lines_dup = before_lines.dup

    after = <<-EOF
/*
 * Copyright (c) 2013 Jiang Xin
 */

When I hack files using GNU patch,
sometimes fail because of the change of upstream files.
If patch can ignore blank lines, support regex patterns
in patch, it will be nice.
So comes rpatch.

Happy hacking.
--
jiangxin
    EOF

    patch_hunk.match_after_patch(before_lines).should be == nil
    patch_hunk.match_before_patch(before_lines).should be == [0, 7]
    result = before_lines.dup
    patch_hunk.patch(result).should be == after.split("\n")
    (result * "\n" + "\n").should be == after
    before_lines_dup.should be == before_lines
  end

  it "patch success (2): whitespaces" do
    before = <<-EOF
  When  I hack files using GNU patch,
		sometimes fail  because of the change of upstream files.
  If patch can	ignore blank lines, support regex patterns
		in patch,	   it    will be nice.
Happy                  hacking.   

--      jiangxin
    EOF
    before_lines = before.split("\n")
    before_lines_dup = before_lines.dup

    after = <<-EOF
/*
 * Copyright (c) 2013 Jiang Xin
 */

  When  I hack files using GNU patch,
		sometimes fail  because of the change of upstream files.
  If patch can	ignore blank lines, support regex patterns
		in patch,	   it    will be nice.
So comes rpatch.

Happy                  hacking.   
--
jiangxin
    EOF

    patch_hunk.match_after_patch(before_lines).should be == nil
    patch_hunk.match_before_patch(before_lines).should be == [0, 7]
    result = before_lines.dup
    patch_hunk.patch(result)
    (result * "\n" + "\n").should be == after
    before_lines_dup.should be == before_lines
  end

  it "patch success (3): blank lines and comments " do
    before = <<-EOF


  When  I hack files using GNU patch,

    sometimes fail  because of the change of upstream files.

    #   If patch can	ignore blank lines, support regex patterns
		##  in patch,	   it    will be nice.
Happy                  hacking.   

--      jiangxin
    EOF
    before_lines = before.split("\n")
    before_lines_dup = before_lines.dup

    after = <<-EOF


/*
 * Copyright (c) 2013 Jiang Xin
 */

  When  I hack files using GNU patch,

    sometimes fail  because of the change of upstream files.

    #   If patch can	ignore blank lines, support regex patterns
		##  in patch,	   it    will be nice.
So comes rpatch.

Happy                  hacking.   
--
jiangxin
    EOF

    patch_hunk.match_after_patch(before_lines).should be == nil
    patch_hunk.match_before_patch(before_lines).should be == [2, 9]
    result = before_lines.dup
    patch_hunk.patch(result)
    (result * "\n" + "\n").should be == after
    before_lines_dup.should be == before_lines
  end

  it "patch failed (1): not match" do
    before = "Hello, \nworld."
    before_lines = before.split("\n")
    before_lines_dup = before_lines.dup

    patch_hunk.match_after_patch(before_lines).should be == nil
    patch_hunk.match_before_patch(before_lines).should be == nil
    expect {
      patch_hunk.patch(before_lines)
    }.to raise_exception Rpatch::PatchHunkError, /Hunk # \(description\) FAILED to apply. Match failed./
    before_lines.should be == before_lines_dup
  end

  it "patch failed (2): already patched" do
    before = <<-EOF
/*
 * Copyright (c) 2013 Jiang Xin
 */



  When  I hack files using GNU patch,

    sometimes fail  because of the change of upstream files.

    #   If patch can	ignore blank lines, support regex patterns
		##  in patch,	   it    will be nice.
So comes rpatch.

Happy                  hacking.   
--
jiangxin
    EOF


    before_lines = before.split("\n")
    before_lines_dup = before_lines.dup

    patch_hunk.match_after_patch(before_lines).should be == [0, 17]
    patch_hunk.match_before_patch(before_lines).should be == nil
    expect {
      patch_hunk.patch(before_lines)
    }.to raise_exception Rpatch::AlreadyPatchedError
    before_lines.should be == before_lines_dup
  end

  it "patch partial of text" do
    before = <<-EOF
When I hack files using GNU patch,
sometimes fail because of the change of upstream files.
So comes rpatch.

Happy hacking.
    EOF
    before_lines = before.split("\n")
    result = before_lines.dup

    diff = <<-EOF
+/*
+ * Copyright (c) 2013 Jiang Xin
+ */
+
 When I hack files using GNU patch,
 sometimes fail because of the change of upstream files.
    EOF

    after = <<-EOF
/*
 * Copyright (c) 2013 Jiang Xin
 */

When I hack files using GNU patch,
sometimes fail because of the change of upstream files.
So comes rpatch.

Happy hacking.
    EOF

    patch_hunk = Rpatch::PatchHunk.new('@@ description')
    diff.lines.each do |line|
      patch_hunk.feed_line line.chomp
    end

    patch_hunk.match_after_patch(before_lines).should be == nil
    patch_hunk.match_before_patch(before_lines).should be == [0, 2]
    result.should be == before_lines
    patch_hunk.patch(result)
    (result * "\n" + "\n").should be == after
  end
end
