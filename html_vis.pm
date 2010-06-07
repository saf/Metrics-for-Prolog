#!/usr/bin/perl

package html_vis;

use Data::Dumper;
use GraphViz;

use html;
use util;
use rate;

return 1;

sub visualise($) {
    my ($data) = @_;
    
    my $deps = get_dependencies($data);
    create_dep_graph($deps);
    project_summary($data, $deps);    

    for my $pkg (sort @{util::get_packages($data)}) {
	package_details($pkg, $data->{$pkg}, $deps);
    }
}

sub project_summary($) {
    my ($data, $deps) = @_;

    open OVERALL, ">output/index.html";
    html::header(\*OVERALL, "Metrics for Prolog");

    my $pkgs = util::get_packages($data);
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
	my $info = package_overall_info($pkg, $data->{$pkg}, $deps);

	print OVERALL 
	    "\t  <tr>\n"
	    . "\t    <td><a href=\"$pkgpage\">$pkg</a></td>\n"
	    . (join '', (map { "\t    <td>$_</td>\n" } (
			     $info->{fan_in}, 
			     $info->{fan_out}, 
			     $info->{n_predicates}, 
			     $info->{total_volume}, 
			     $info->{total_effort}, 
			     $info->{average_complexity})))
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

    my $average_complexity = $total_partitions == 0 ? 0 : $total_complexity / $total_partitions;

    return { 
	fan_in => $fanin, 
	fan_out => $fanout, 
	n_predicates => $npred,
	total_volume => $total_volume,
	total_effort => $total_effort, 
	average_complexity => $average_complexity,
    };
}

sub get_dependencies($) {
    my ($data) = @_;
    my $outgoing = {};
    my $incoming = {};
    my $pkgs = util::get_packages($data);

    for my $pkg (@$pkgs) {
	$incoming->{$pkg} = [];
	$outgoing->{$pkg} = [];
    };

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

sub package_details($$$) {
    my ($pkg, $data, $deps) = @_;
    
    my $out = package_page_name($pkg);

    open OUTPUT, ">output/$out";
    html::header(\*OUTPUT, "Package $pkg");

    my $details = package_info($pkg, $data, $deps);
    my $complexity_rating = rate::local_complexity($details->{complexity}->{average_complexity});

    print OUTPUT <<_END;
    <h2>Package <span class="packageName">$pkg</span></h2>
    <h3>Package summary</h3>

       <table class="noborder">
         <tr><th colspan="2" class="hdr">Code metrics</th></tr>
	 <tr><th>Total lines of code</th><td>$details->{code}->{loc}</td></tr>
	 <tr><th>Lines with effective code</th><td>$details->{code}->{effective_loc}</td></tr>
	 <tr><th>Lines with comments</th><td>$details->{code}->{loc_comments}</td></tr>
	 <tr><th>Comments per effective line</th><td>$details->{code}->{comments_per_line}</td></tr>
	 
	 <tr><th colspan="2" class="hdr">Predicate statistics</th></tr>
	 <tr><th>Number of predicates</th><td>$details->{predicates}->{number}</td></tr>
	 <tr><th>LOC per predicate</th><td>$details->{predicates}->{loc_per_predicate}</td></tr>
	 <tr><th>Comment lines per predicate</th><td>$details->{predicates}->{comments_per_predicate}</td></tr>

	 <tr><th colspan="2" class="hdr">Package metrics</th></tr>
	 <tr><th>Total volume</th><td>$details->{halstead}->{volume}</td></tr>
	 <tr><th>Total effort</th><td>$details->{halstead}->{effort}</td></tr>
	 <tr><th>Estimated time to implement</th><td>$details->{halstead}->{time}</td></tr>
	 <tr><th>Average partition complexity</th>
	     <td>$details->{complexity}->{average_complexity} 
                 <span style="color: $complexity_rating->{color}">($complexity_rating->{long})</span>
	     </td></tr>

	 <tr><th colspan="2" class="hdr">Package relationship metrics</th></tr>
	 <tr><th>Fan-in</th><td>$details->{relationships}->{fan_in}</td></tr>
	 <tr><th>Fan-out</th><td>$details->{relationships}->{fan_out}</td></tr>

       </table>

    <h3>Predicates</h3>
    
_END
}

sub package_info($$$) {
    my ($pkg, $data, $deps) = @_;

    my $predicates = pl_package::get_predicates($data);
    my $overall = package_overall_info($pkg, $data, $deps); 
    my $n_predicates = $overall->{n_predicates};

    return {
	code => {
	    loc => $data->{loc},
	    effective_loc => $data->{effective_loc}, 
	    loc_comments => $data->{comments}, 
	    comments_per_line => $data->{effective_loc} == 0 
		? 0 
		: $data->{comments} / $data->{effective_loc},
	},
	predicates => {
	    number => $n_predicates, 
	    loc_per_predicate => $n_predicates == 0 
		? 0 
		: $data->{effective_loc} / $n_predicates,
	    comments_per_predicate => $n_predicates == 0 
	        ? 0 
		: $data->{comments} / $n_predicates,
	},
	halstead => {
	    volume => $overall->{total_volume}, 
	    effort => $overall->{total_effort}, 
	    time   => time_from_seconds($overall->{total_effort} / 5),
        },
	complexity => {
	    average_complexity => $overall->{average_complexity}, 
	},
	relationships => {
	    fan_in => $overall->{fan_in}, 
	    fan_out => $overall->{fan_out}, 
	},
    };
}

sub package_page_name($) {
    my ($name) = @_;
    my $esc = $name;
    $esc =~ s|/|__|g;
    return $esc . ".html";
}


sub time_from_seconds($) {
    my ($seconds) = @_;

    my $spm = 60;
    my $sph = $spm * 60;
    my $spd = $sph * 8;

    my $days = int($seconds / $spd);
    my $hours = int(($seconds - $spd * $days) / $sph);
    my $minutes = int(($seconds - $spd * $days - $sph * $hours) / $spm);

    my $result = '';
    $result .= "$days days, " if $days > 0;
    $result .= "$hours hours, " if $hours > 0; 
    $result .= "$minutes minutes" if $minutes > 0;

    return $result;
}

