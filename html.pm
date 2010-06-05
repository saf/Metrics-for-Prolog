#!/usr/bin/perl

package html;
return 1;

sub header($$) {
    my ($fh, $title) = @_;
    print $fh <<_END
<html>
  <head>
    <title>$title</title>
  </head>
  <body>
_END
}

sub footer($) {
    my ($fh) = @_;
    print $fh <<_END
  </body>
</html>
_END
}
