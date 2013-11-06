#!/bin/sh
#
# Copyright (c) 2013 Jiang Xin
#

test_description='patch file test'

. ./test-lib.sh

############################################################

cat > diff <<EOF
diff -u /dev/null b/foo
--- /dev/null   2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ add two lines
+bar
+baz
EOF

cat > expect <<EOF
bar
baz
EOF

test_expect_success 'patch newfile' '
	touch ! -f actual &&
	touch actual &&
	rpatch -p1 actual < diff &&
	test_cmp expect actual
'

############################################################

cat > expect_errlog <<EOF
Patched "actual".
INFO: actual: Hunk 1 (add two lines) is already patched.
actual: nothing changed
EOF

test_expect_success 'patch newfile (2nd)' '
	rm actual &&
	touch actual &&
	rpatch -vv actual < diff 2> actual_errlog &&
	rpatch -vv actual < diff 2>>actual_errlog &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > orig <<EOF
bar
baz
EOF

cat > diff <<EOF
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ insert heading
+Insert at the beginning
@@ add/remove
 bar
-baz
+foo
@@ insert footer
 foo
+end of text
EOF

cat > expect <<EOF
Insert at the beginning
bar
foo
end of text
EOF

test_expect_success 'patch add/remote contents' '
	cp orig actual &&
	rpatch actual < diff &&
	test_cmp expect actual
'

############################################################

cat > expect_errlog <<EOF
INFO: actual: Hunk 1 (insert heading) is already patched.
INFO: actual: Hunk 2 (add/remove) is already patched.
INFO: actual: Hunk 3 (insert footer) is already patched.
actual: nothing changed
EOF

test_expect_success 'patch add/remote contents (2nd)' '
	rpatch -vv actual < diff 2>actual_errlog &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ delete all
-Insert at the beginning
-bar
-foo
-end of text
EOF

cat > expect_errlog <<EOF
Remove "actual".
EOF

test_expect_success 'patch to rm file' '
	rpatch -vv -p1 actual < diff 2> actual_errlog &&
	test ! -f actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > expect_errlog <<EOF
INFO: actual: Hunk 1 (delete all) is already patched.
actual: nothing changed
EOF

test_expect_success 'patch to rm file (2nd)' '
	touch actual &&
	rpatch -vv -p1 actual < diff 2> actual_errlog &&
	test -z "$(cat actual)" &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > orig <<EOF
	 FOO
       bAr
 baz
EOF

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ remove bAr
RE: ^[\\s]+(foo|FOO)\$
RE:-[bB][aA][rR]
+bar
@@ mixed
RE: baz
+end of text
EOF

cat > expect <<EOF
	 FOO
bar
 baz
end of text
EOF

cat > expect_errlog <<EOF
Patched "actual".
EOF

test_expect_success 'use regexp in patch' '
	cp orig actual &&
	rpatch -vv actual < diff 2> actual_errlog &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > expect_errlog <<EOF
INFO: actual: Hunk 1 (remove bAr) is already patched.
INFO: actual: Hunk 2 (mixed) is already patched.
actual: nothing changed
EOF

test_expect_success 'use regexp in patch (2nd)' '
	rpatch -vv actual < diff 2> actual_errlog &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ add two lines
+bar
+baz
trash text
EOF

cat > expect_errlog <<EOF
ERROR: Line 6 of patch "<IO>" is invalid.
       => "trash text"
EOF

test_expect_success 'patch load fail: bad syntax' '
	rm actual &&
	touch actual &&
	test_must_fail rpatch -vv actual < diff 2> actual_errlog &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > orig <<EOF
foo
EOF

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ insert one
 bar
+baz
EOF

cat > expect_errlog <<EOF
ERROR: actual: Hunk 1 (insert one) FAILED to apply. Match failed.
actual: nothing changed
EOF

test_expect_success 'patch apply fail' '
	cp orig actual &&
	test_must_fail rpatch -vv actual < diff 2> actual_errlog &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > orig <<EOF
foo
EOF

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ add header
+# header...
 foo
@@ add footer
 baz
+footer...
EOF

cat > expect <<EOF
# header...
foo
EOF

cat > expect_errlog <<EOF
ERROR: actual: Hunk 2 (add footer) FAILED to apply. Match failed.
WARNING: saved orignal file as "actual.orig".
Patched "actual".
EOF

test_expect_success 'partial patch success' '
	cp orig actual &&
	test ! -f actual.orig &&
	test_must_fail rpatch -vv actual < diff 2> actual_errlog &&
	test -f actual.orig &&
	test_cmp actual.orig orig &&
	test_cmp actual expect &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > expect_errlog <<EOF
INFO: actual: Hunk 1 (add header) is already patched.
ERROR: actual: Hunk 2 (add footer) FAILED to apply. Match failed.
actual: nothing changed
EOF

test_expect_success 'partial patch success (2nd)' '
	test_must_fail rpatch -vv actual < diff 2> actual_errlog &&
	test -f actual.orig &&
	test_cmp actual.orig orig &&
	test_cmp actual expect &&
	test_cmp expect_errlog actual_errlog
'

############################################################

test_done
