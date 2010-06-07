package rate;

use Data::Dumper;

return 1;


sub local_complexity($) {
    my ($c) = @_;

    return { long => "Trivial", short => "T", color => "#00FF00" } if $c <= 3;
    return { long => "Simple",  short => "S", color => "#88FF00" } if $c <= 7;
    return { long => "Complex", short => "C", color => "#FFFF00" } if $c <= 13;
    return { long => "Very comples", short => "V", color => "#FF8800" };
}

