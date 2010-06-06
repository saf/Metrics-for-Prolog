#!/usr/bin/perl

package html_vis;

use html;
use GraphViz;

return 1;

sub visualise($) {
    my ($data) = @_;
    
    my $deps = get_dependencies($data);
    create_dep_graph($deps);
    project_summary($data);    

    for my $pkg (sort get_packages($data)) {
	package_details($pkg, $data->{$pkg}, $deps);
    }
}

sub project_summary($) {
    my ($data) = @_;

    open OVERALL, ">output/index.html";
    html::header(\*OVERALL, "Metrics for Prolog");

    my $pkgs = get_packages($data);
    my $deps = get_dependencies($data);
    my $number_packages = @$pkgs;

    print OVERALL <<_END;
        <h2>Project summary</h2>
	<h2>Package dependency graph</h2>
	  <p class="explanation">The following graph shows relationships between the project modules. 
	    An arrow from package X to package Y means that package X consults Y. </p>
	    <img src="packages.png" />
	<h2>List of packages</h2>
	  <p class="explanation">The list contains all Prolog files included within the project, along
	    with some top-level statistics of the files. Click on the file name to view details on
	    the package.</p>
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

    my $fanin  = @{$deps->{incoming}->{$pkg}};
    my $fanout = @{$deps->{outgoing}->{$pkg}};

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

    for my $pkg (@$pkgs) {
	$incoming->{$pkg} = [];
	$outgoing->{$pkg} = [];
    };

    use Data::Dumper;
    warn Dumper($pkgs);

    for my $pkg (sort @$pkgs) {
	my $links = $data->{$pkg}->{links};

	if ($links =~ /^ARRAY/) {
	    for (@$links) {
		my $dep = $_->{ref};
		push @{$outgoing->{$pkg}}, $dep;
		push @{$incoming->{$dep}}, $pkg;
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
    
    my $gv = GraphViz->new();
    for (keys %{$deps->{outgoing}}) {
	$gv->add_node($_);
    };
    for my $pkg (keys %{$deps->{outgoing}}) {
	for (@{$deps->{outgoing}->{$pkg}}) {
	    $gv->add_edge($pkg => $_);
	}
    };

    open GRAPH, ">output/packages.png";
    print GRAPH $gv->as_png;
    close GRAPH;
}

sub package_page_name($) {
    my ($name) = @_;
    my $esc = $name;
    $esc =~ s|/|__|g;
    return $esc . ".html";
}
