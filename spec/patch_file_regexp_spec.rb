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
@@ remove two leading lines
-I have a script to patch text files, it's more like
RE:-.* Why not (patch|GNU patch)?
 When I hack files using GNU patch,
RE: sometimes fail because .*
@@ add copyright
+/*
+ * Copyright (c) 2013 Jiang Xin
+ */
+
 When I hack files using GNU patch,
RE: sometimes fail because .*
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

  it "patch on file" do
    before = <<-EOF
I have a script to patch text files, it's more like
"grep" and "seed -s". Why not GNU patch?
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

end
