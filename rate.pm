package rate;

use Data::Dumper;

return 1;


sub local_complexity($) {
    my ($c) = @_;

    return { long => "Trivial", short => "T", color => "#00FF00" } if $c <= 3;
    return { long => "Simple",  short => "S", color => "#55AA00" } if $c <= 7;
    return { long => "Complex", short => "C", color => "#AA5500" } if $c <= 13;
    return { long => "Very complex", short => "V", color => "#FF0000" };
}

