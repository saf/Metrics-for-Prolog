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

sub package_volume($) {
    my ($v) = @_;
    return linear($v, 3000);
}

sub package_effort($) {
    my ($v) = @_;
    return linear($v, 30000);
}

sub predicate_volume($) {
    my ($v) = @_;
    return linear($v, 1000);
}

sub predicate_effort($) {
    my ($v) = @_;
    return linear($v, 10000);
}

sub difficulty($) {
    my ($v) = @_;
    return linear($v, 10);
}

sub total_complexity($) {
    my ($v) = @_;
    return linear($v, 50);
}

#TOOLS:

sub linear($$) {
    my ($v, $thr) = @_;
    
    return { color => color_of_rating(($v > $thr ? 1 : $v / $thr), 1) };
}

sub color_of_rating($$) {
    my ($rating, $rev) = @_;

    $rating = 1 - $rating if $rev;

    my $red = int(255*(1-$rating));
    my $green = int(255*$rating);

    return "rgb($red, $green, 0)";
}

sub value_to_hex($) {
    my ($v) = @_;
    return sprintf "%x", $v;
}
