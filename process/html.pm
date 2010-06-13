#!/usr/bin/perl

package html;
return 1;

sub header($$) {
    my ($fh, $title) = @_;
    print $fh <<_END
<html>
  <head>
    <title>$title</title>
    <link rel="stylesheet" href="style.css" />
    <script language="JavaScript" src="js/jquery-1.4.2.js"></script>
    <script language="JavaScript" src="js/mfpl.js"></script>
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
