#!/bin/sh
#
# Copyright (c) 2013 Jiang Xin
#

test_description='patch file test'

. ./test-lib.sh

############################################################

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ add two lines
+baz
+foo
diff -u a/bar b/bar
--- a/bar       2013-11-04 16:01:56.000000000 +0800
+++ b/bar       2013-11-04 16:01:59.000000000 +0800
@@ add two lines
+baz
+bar
EOF

cat > expect <<EOF
EOF

cat > expect_errlog <<EOF
Error: Multiple patch entries (2) have been found in patch <IO>
Error: Multiple patch entries (2) have been found in patch <IO>
EOF

test_expect_success 'cannot patch single file with multi patch entries' '
	touch ! -f actual &&
	touch actual &&
	test_must_fail rpatch actual < diff 2>actual_errlog &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > expect_errlog <<EOF
Patched "output/foo".
Patched "output/bar".
EOF

cat > expect_foo <<EOF
baz
foo
EOF

cat > expect_bar <<EOF
baz
bar
EOF

test_expect_success 'Patch on directory: create new file automatically' '
	mkdir output &&
	rpatch output < diff 2>actual_errlog &&
	test -f output/foo &&
	test -f output/bar &&
	test_cmp expect_foo output/foo &&
	test_cmp expect_bar output/bar &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ heading
+heading of foo...
-baz
@@ tail
 foo
+tail of foo ...
diff -u a/bar b/bar
--- a/bar       2013-11-04 16:01:56.000000000 +0800
+++ b/bar       2013-11-04 16:01:59.000000000 +0800
@@ heading
+heading of bar...
-baz
@@ tail
 bar
+tail of bar ...
EOF

cat > expect_errlog <<EOF
Patched "output/foo".
Patched "output/bar".
EOF

cat > expect_foo <<EOF
heading of foo...
foo
tail of foo ...
EOF

cat > expect_bar <<EOF
heading of bar...
bar
tail of bar ...
EOF

test_expect_success 'Patch on directory (2): patch exist files' '
	rpatch output < diff 2>actual_errlog &&
	test -f output/foo &&
	test -f output/bar &&
	test_cmp expect_foo output/foo &&
	test_cmp expect_bar output/bar &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ can not match
 heading of foo...
 foobar
-tail of foo ...
diff -u a/bar b/bar
--- a/bar       2013-11-04 16:01:56.000000000 +0800
+++ b/bar       2013-11-04 16:01:59.000000000 +0800
@@ remove tail
 heading of bar...
 bar
-tail of bar ...
EOF

cat > expect_errlog <<EOF
ERROR: output/foo: Hunk 1 (can not match) FAILED to apply. Match failed.
output/foo: nothing changed
Patched "output/bar".
EOF

cat > expect_foo <<EOF
heading of foo...
foo
tail of foo ...
EOF

cat > expect_bar <<EOF
heading of bar...
bar
EOF

test_expect_success 'Patch on directory (3): one fail, another success' '
	test_must_fail rpatch output < diff 2>actual_errlog &&
	test -f output/foo &&
	test -f output/bar &&
	test_cmp expect_foo output/foo &&
	test_cmp expect_bar output/bar &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ can not match
RE:-heading
RE:-foo
RE:-tail.*
diff -u a/bar b/bar
--- a/bar       2013-11-04 16:01:56.000000000 +0800
+++ b/bar       2013-11-04 16:01:59.000000000 +0800
@@ add tail
RE: ^[bB][aA][rR]$
+tail of bar...
EOF

cat > expect_errlog <<EOF
Remove "output/foo".
Patched "output/bar".
EOF

cat > expect_bar <<EOF
heading of bar...
bar
tail of bar...
EOF

test_expect_success 'Patch on directory (4): remove file' '
	rpatch -p1 output < diff 2>actual_errlog &&
	test ! -f output/foo &&
	test -f output/bar &&
	test_cmp expect_bar output/bar &&
	test_cmp expect_errlog actual_errlog
'

############################################################

test_done