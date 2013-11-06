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
<
+bar
+baz
EOF

cat > actual <<EOF
hello
world
EOF


cat > expect <<EOF
bar
baz
hello
world
EOF

cat > expect_errlog <<EOF
EOF

test_expect_success 'patch from beginning' '
	rpatch -p1 -vv actual < diff 2>&1 >actual_errlog  &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ add two lines
>
+bar
+baz
EOF

cat > actual <<EOF
hello
world
EOF


cat > expect <<EOF
hello
world
bar
baz
EOF

cat > expect_errlog <<EOF
EOF

test_expect_success 'patch from tail' '
	rpatch -p1 -vv actual < diff 2>&1 >actual_errlog  &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'


############################################################

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ add two lines
<
 hello, world
+bar
+baz
EOF

cat > actual <<EOF
hello,  world
hello,  world
EOF


cat > expect <<EOF
hello,  world
bar
baz
hello,  world
EOF

cat > expect_errlog <<EOF
EOF

test_expect_success 'patch from beginning (2)' '
	rpatch -p1 -vv actual < diff 2>&1 >actual_errlog  &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ add two lines
>
 hello, world
+bar
+baz
EOF

cat > actual <<EOF
hello,  world
hello,  world
EOF


cat > expect <<EOF
hello,  world
hello,  world
bar
baz
EOF

cat > expect_errlog <<EOF
EOF

test_expect_success 'patch from tail (2)' '
	rpatch -p1 -vv actual < diff 2>&1 >actual_errlog  &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

cat > actual <<EOF
Copyright 2013, jiangxin
Hello, world
bye.
EOF

cat > diff <<EOF
diff -u a/foo b/foo
--- a/foo       2013-11-04 16:01:56.000000000 +0800
+++ b/foo       2013-11-04 16:01:59.000000000 +0800
@@ add two lines
/ [cC]opyright [0-9]{4}
/-[Hh]ello
+foo
+bar
EOF

cat > expect <<EOF
Copyright 2013, jiangxin
foo
bar
bye.
EOF

cat > expect_errlog <<EOF
EOF

test_expect_success 'Start regex pattern with /' '
	rpatch -p1 -vv actual < diff 2>&1 >actual_errlog  &&
	test_cmp expect actual &&
	test_cmp expect_errlog actual_errlog
'

############################################################

test_done
