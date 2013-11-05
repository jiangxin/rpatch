# Rpatch

rpatch: a patch utility support regexp in patchfile.

Rpatch is a patch utility, more tolerant than GNU patch. It will ignore
changes of blank lines and white spaces, and what's more you can write
regexp ("RE: " and "RE:-") in patch file to match lines.

 * Use "RE: " with a regexp to match unchanged line.
 * Use "RE:-" with a regexp to match removed line.
 * Use "@@" to starts a new patch hunk only and use it's text as
   description for the hunk only.

For example:

 * Origninal file:

        When    I    hack    files    using    GNU    patch,
        sometimes fail because of the change of upstream files.
        blah blah blah...
        So    comes    rpatch.
    
        Happy hacking.

 * Patch file:

        diff -ru a/README b/README
        --- a/readme.txt	2013-11-03 22:17:02.000000000 +0800
        +++ b/readme.txt	2013-11-03 21:10:46.000000000 +0800
        @@ add copyright at the beginning
        +# Copyright (c) 2013 Jiang Xin
        +
         When I hack files using GNU patch,
        RE: sometimes fail because .*
        RE:-(blah\s*){3}
        @@ add notes
        +If patch can ignore blank lines, support regex patterns
        +in patch, it will be nice.
         So comes rpatch.
        @@ add signature
         Happy hacking.
        +--
        +jiangxin

 * And the result would be:

        # Copyright (c) 2013 Jiang Xin

        When    I    hack    files    using    GNU    patch,
        sometimes fail because of the change of upstream files.
        If patch can ignore blank lines, support regex patterns
        in patch, it will be nice.
        So    comes    rpatch.

        Happy hacking.
        --
        jiangxin

## Installation

Install using rubygems:

    $ gem install rpatch

Or install from source:

    $ rake build
    $ rake install

## Usage

Rpatch is a GNU patch likely utilty, patch original file using patch file like this:

    $ patch originalfile patchfile

Or patch files under the current directory, and read patchfile from STDIN:

    $ patch -p1 < patchfile

Rpatch can also read a series patches in quilt format.

    $ patch -p1 . patches

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
