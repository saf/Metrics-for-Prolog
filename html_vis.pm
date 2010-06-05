#!/usr/bin/perl

package html_vis;

use html;

return 1;

sub visualise($) {
    my ($data) = @_;
    
    package_summary($data);
    my $deps = get_dependencies($data);

    for my $pkg (sort get_packages($data)) {
	package_details($pkg, $data->{$pkg}, $deps);
    }
}

sub package_summary($) {
    my ($data) = @_;

    open OVERALL, ">output/index.html";
    html::header(\*OVERALL, "Metrics for Prolog");

    my $pkgs = get_packages($data);
    my $deps = get_dependencies($data);

    print OVERALL <<_END;
	<table>
	  <tr>
	    <th>File name</th>
	    <th>Fan-in</th>
	    <th>Fan-out</th>
	    <th>Predicates</th>
	    <th>Volume</th>
	    <th>Effort</th>
	    <th>Average LC</th>
	  </tr>
_END
    for my $pkg (sort @$pkgs) {
	my $pkgpage = package_page_name($pkg);
	print OVERALL 
	    "\t  <tr>\n"
	    . "\t    <td><a href=\"$pkgpage\">$pkg</a></td>\n"
	    . (join '', (map { "\t    <td>$_</td>\n" } @{package_overall_info($pkg, $data->{$pkg}, $deps)}))
	    . "\t  </tr>\n";
    };
    
    print OVERALL <<_END;
        </table>
_END
    html::footer(\*OVERALL);
}

sub package_overall_info($$$) {
    my ($pkg, $data, $deps) = @_;

    my $fanin  = defined $deps->{incoming}->{$pkg} ? @{$deps->{incoming}->{$pkg}} : 0;
    my $fanout = defined $deps->{outgoing}->{$pkg} ? @{$deps->{outgoing}->{$pkg}} : 0;

    my $predicates = pl_package::get_predicates($data);
    my $npred      = @$predicates;
    my $total_volume = 0;
    my $total_effort = 0;
    my $total_complexity = 0;
    my $total_partitions = 0;
    
    for (@$predicates) {
	$total_volume += $_->{halstead}->{volume}; 
	$total_effort += $_->{halstead}->{effort};
	$total_complexity += $_->{local}->{sum};
	$total_partitions += $_->{local}->{n_partitions};
    };

    return [ $fanin, $fanout, $npred, $total_volume, $total_effort, $total_complexity / $total_partitions ];
}

sub package_details($$) {
    my ($pkg, $data, $deps) = @_;
    
}

sub get_packages($) {
    my ($data) = @_;
    return [keys %$data];
}

sub get_dependencies($) {
    my ($data) = @_;
    my $outgoing = {};
    my $incoming = {};
    my $pkgs = get_packages($data);

    for my $pkg (sort @$pkgs) {
	my $links = $data->{$pkg}->{links};
	if ($links =~ /^ARRAY/) {
	    for (@$links) {
		my $dep = $_->{ref};
		if (defined $outgoing->{$pkg}) {
		    push @{$outgoing->{$pkg}}, $dep;
		} else {
		    $outgoing->{$pkg} = [$dep];
		};
		if (defined $incoming->{$dep}) {
		    push @{$incoming->{$dep}}, $pkg;
		} else {
		    $incoming->{$dep} = [$pkg];
		};
	    }
	}
    }

    return { 
	incoming => $incoming, 
	outgoing => $outgoing,
    };
}

sub create_dep_graph($) {
    my ($deps) = @_;
    
    
}

sub package_page_name($) {
    my ($name) = @_;
    my $esc = $name;
    $esc =~ s|/|__|g;
    return $esc . ".html";
}
