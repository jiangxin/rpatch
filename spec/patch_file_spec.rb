#!/usr/bin/env ruby
#

require 'rubygems'
require 'spec_helper'
require 'stringio'

describe Rpatch::PatchFile do
    let(:diff) do
      <<-EOF
diff -ru before/readme.txt after/readme.txt
--- a/readme.txt   2013-11-03 22:17:02.000000000 +0800
+++ b/readme.txt    2013-11-03 21:10:46.000000000 +0800
@@ add copyright
+/*
+ * Copyright (c) 2013 Jiang Xin
+ */
+
 When I hack files using GNU patch,
 sometimes fail because of the change of upstream files.
@@ add notes
+If patch can ignore blank lines, support regex patterns
+in patch, it will be nice.
 So comes rpatch.
 
@@ add signature
 Happy hacking.
+--
+jiangxin
    EOF
  end

  it "patch on file (1): normal patch" do
    before = <<-EOF
When I hack files using GNU patch,
sometimes fail because of the change of upstream files.
So comes rpatch.

Happy hacking.
    EOF

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

    inputfile = StringIO.new(before, "r")
    patchfile = StringIO.new(diff, "r")
    output = ''
    outputfile = StringIO.new(output, "w")
    patch = Rpatch::PatchFile.new(patchfile, 1)
    patch.apply_to(inputfile, outputfile)
    output.should == after
  end

  it "patch on file (2): partial patched" do
    before = <<-EOF
When I hack files using GNU patch,
sometimes fail because of the change of upstream files.
If patch can ignore blank lines, support regex patterns
in patch, it will be nice.
So comes rpatch.

Happy hacking.
    EOF

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

    inputfile = StringIO.new(before, "r")
    patchfile = StringIO.new(diff, "r")
    output = ''
    outputfile = StringIO.new(output, "w")
    patch = Rpatch::PatchFile.new(patchfile, 1)
    patch.apply_to(inputfile, outputfile)
    output.should == after
  end

  it "patch on file (3): already patched" do
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

    before = after.dup

    inputfile = StringIO.new(before, "r")
    patchfile = StringIO.new(diff, "r")
    output = ''
    outputfile = StringIO.new(output, "w")
    patch = Rpatch::PatchFile.new(patchfile, 1)
    patch.apply_to(inputfile, outputfile)
    output.should == after
  end

  it "patch on file (4): blank lines and white spaces" do
    before = <<-EOF
    When I hack files using GNU             patch,

    sometimes fail because of the change of upstream files.

So comes rpatch.

Happy hacking.

    EOF

    after = <<-EOF
/*
 * Copyright (c) 2013 Jiang Xin
 */

    When I hack files using GNU             patch,

    sometimes fail because of the change of upstream files.

If patch can ignore blank lines, support regex patterns
in patch, it will be nice.
So comes rpatch.

Happy hacking.
--
jiangxin

    EOF

    inputfile = StringIO.new(before, "r")
    patchfile = StringIO.new(diff, "r")
    output = ''
    outputfile = StringIO.new(output, "w")
    patch = Rpatch::PatchFile.new(patchfile, 1)
    patch.apply_to(inputfile, outputfile)
    output.should == after
  end

  it "patch on file (5): patch on blank files" do
    before = ''

    diff = <<-EOF
diff -ru before/readme.txt after/readme.txt
--- a/readme.txt   2013-11-03 22:17:02.000000000 +0800
+++ b/readme.txt    2013-11-03 21:10:46.000000000 +0800
@@ initial
+hello
+world
    EOF

    after = <<-EOF
hello
world
    EOF


    inputfile = StringIO.new(before, "r")
    patchfile = StringIO.new(diff, "r")
    output = ''
    outputfile = StringIO.new(output, "w")
    patch = Rpatch::PatchFile.new(patchfile, 1)
    patch.apply_to(inputfile, outputfile)
    output.should == after
  end

  it "bad patch header, so nothing patched (1)" do
    before = ''

    diff = <<-EOF
diff -ru before/readme.txt after/readme.txt
@@ initial
+hello
+world
    EOF

    after = <<-EOF
    EOF


    inputfile = StringIO.new(before, "r")
    patchfile = StringIO.new(diff, "r")
    output = ''
    outputfile = StringIO.new(output, "w")
    patch = Rpatch::PatchFile.new(patchfile, 1)
    patch.apply_to(inputfile, outputfile)
    output.should == after
  end

  it "patch failed (1): patch format error" do
    diff = <<-EOF
diff -ru before/readme.txt after/readme.txt
--- a/readme.txt   2013-11-03 22:17:02.000000000 +0800
+++ b/readme.txt    2013-11-03 21:10:46.000000000 +0800
@@ initial
 lines of a patch must start with
 space
+plus
-minus
RE: regexp match
RE:-regexp match
 others are bad.
BAD PATCH SYNTAX.
    EOF

    patchfile = StringIO.new(diff, "r")
    expect {
      Rpatch::PatchFile.new(patchfile, 1)
    }.to raise_exception Rpatch::PatchFormatError, /BAD PATCH SYNTAX./

  end

  it "patch failed (2): apply_to return false" do
    before = <<-EOF
bad
    EOF

    diff = <<-EOF
diff -ru before/readme.txt after/readme.txt
--- a/readme.txt	2013-11-03 22:17:02.000000000 +0800
+++ b/readme.txt	2013-11-03 21:10:46.000000000 +0800
@@ initial
 hello
+world
    EOF

    inputfile = StringIO.new(before, "r")
    patchfile = StringIO.new(diff, "r")
    output = ''
    outputfile = StringIO.new(output, "w")

    patch = Rpatch::PatchFile.new(patchfile, 1)
    patch.apply_to(inputfile, outputfile).should be == false
    output.should be == before
  end

end
