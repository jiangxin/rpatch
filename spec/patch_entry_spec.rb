#!/usr/bin/env ruby
#

require 'spec_helper'

describe Rpatch::PatchEntry do

  it "filename and patch level (1)" do
    old = "a/foo/bar/src/file.c"
    new = "b/foo/bar/src/file.c"
    entry = Rpatch::PatchEntry.new(old, new, 0)
    entry.oldfile.should be == "a/foo/bar/src/file.c"
    entry.newfile.should be == "b/foo/bar/src/file.c"
    entry = Rpatch::PatchEntry.new(old, new, 1)
    entry.oldfile.should be == "foo/bar/src/file.c"
    entry.newfile.should be == "foo/bar/src/file.c"
    entry = Rpatch::PatchEntry.new(old, new, 3)
    entry.oldfile.should be == "src/file.c"
    entry.newfile.should be == "src/file.c"
  end

  it "filename and patch level (2)" do
    old = "/dev/null"
    new = "b/foo/bar/src/file.c"
    entry = Rpatch::PatchEntry.new(old, new, 1)
    entry.oldfile.should eq "/dev/null"
    entry.newfile.should eq "foo/bar/src/file.c"
    old = "a/foo/bar/src/file.c"
    new = "/dev/null"
    entry = Rpatch::PatchEntry.new(old, new, 1)
    entry.oldfile.should eq "foo/bar/src/file.c"
    entry.newfile.should eq "/dev/null"
  end

  it "patch on file (1)" do
    before = <<-EOF
When I hack files using GNU patch,
sometimes fail because of the change of upstream files.
So comes rpatch.

Happy hacking.
    EOF

    diff = <<-EOF
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

    old = "a/foo/bar/src/file.c"
    new = "b/foo/bar/src/file.c"
    entry = Rpatch::PatchEntry.new(old, new, 1)
    diff.lines.each do |line|
      entry.feed_line line
    end
    entry.patch_on_message(before).should == after
  end

  it "patch on file (2)" do
    before = <<-EOF
Subject: about rpatch

When I hack files using GNU patch,
sometimes fail because of the change of upstream files.
So comes rpatch.

Happy hacking.
    EOF

    diff = <<-EOF
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

    after = <<-EOF
Subject: about rpatch

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

    old = "a/foo/bar/src/file.c"
    new = "b/foo/bar/src/file.c"
    entry = Rpatch::PatchEntry.new(old, new, 1)
    diff.lines.each do |line|
      entry.feed_line line
    end
    entry.patch_on_message(before).should == after
  end

  it "patch on file (3)" do
    before = ''

    diff = <<-EOF
@@ initial
+/*
+ * Copyright (c) 2013 Jiang Xin
+ */
+
+When I hack files using GNU patch,
+sometimes fail because of the change of upstream files.
+If patch can ignore blank lines, support regex patterns
+in patch, it will be nice.
+So comes rpatch.
+
+Happy hacking.
+--
+jiangxin
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

    old = "a/foo/bar/src/file.c"
    new = "b/foo/bar/src/file.c"
    entry = Rpatch::PatchEntry.new(old, new, 1)
    diff.lines.each do |line|
      entry.feed_line line
    end
    entry.patch_on_message(before).should == after
  end

  it "patch on file (4)" do
    before = <<-EOF
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

    diff = <<-EOF
@@ remove all
-/*
- * Copyright (c) 2013 Jiang Xin
- */
-
-When I hack files using GNU patch,
-sometimes fail because of the change of upstream files.
-If patch can ignore blank lines, support regex patterns
-in patch, it will be nice.
-So comes rpatch.
-
-Happy hacking.
---
-jiangxin
    EOF

    after = ''

    old = "a/foo/bar/src/file.c"
    new = "b/foo/bar/src/file.c"
    entry = Rpatch::PatchEntry.new(old, new, 1)
    diff.lines.each do |line|
      entry.feed_line line
    end
    entry.patch_on_message(before).should == after
  end
end
