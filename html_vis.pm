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
    my $summary = project_overall_info($data, $deps);
    my $compl_rating = rate::local_complexity($summary->{predicates}->{ave_loc});

    print OVERALL <<_END;
        <h2>Project metrics summary</h2>
	<div class="separator"></div>
	<h3>Project summary</h3>
	  <table class="summaryTable">
	    <tr><td colspan="2" class="hdr">Code metrics</th></tr>
	    <tr><th>Lines of code</th><td>$summary->{code}->{loc}</td></tr>
            <tr><th>Lines of effective code</th><td>$summary->{code}->{eloc}</td></tr>
            <tr><th>Comments per line</th><td>${format_float($summary->{code}->{comments_per_line})}</td></tr>
	  </table>
	  <table class="summaryTable">
	    <tr><td colspan="2" class="hdr">Halstead metrics</th></tr>
	    <tr><th>Total volume</th><td>${format_float($summary->{halstead}->{volume})}</td></tr>
	    <tr><th>Total effort</th><td>${format_float($summary->{halstead}->{effort})}</td></tr>
	    <tr><th>Total time</th><td>${format_time($summary->{halstead}->{time})}</td></tr>
	  </table>
	  <table class="summaryTable">
	    <tr><td colspan="2" class="hdr">Packages</th></tr>
	    <tr><th>Number of packages</th><td>$summary->{packages}->{number}</td></tr>
	    <tr><th>Average LOC per package</th><td>$summary->{packages}->{loc_per_package}</td></tr>
	  </table>
	  <table class="summaryTable">
	    <tr><td colspan="2" class="hdr">Predicates</th></tr>
	    <tr><th>Number of predicates</th><td>$summary->{predicates}->{number}</td>
	    <tr><th>Average LOC per predicate</th><td>${format_float($summary->{predicates}->{ave_loc})}</td>
	    <tr><th>Average complexity</th>
	      <td>${format_float($summary->{predicates}->{ave_complexity})}
                  <span style="color: $compl_rating->{color}">($compl_rating->{long})</span>
              </td></tr>
	  </table>
	  
	<h3>Package dependency graph</h3>
	  <p class="explanation">The following graph shows relationships between the project modules. 
	    An arrow from package X to package Y means that package X consults Y. </p>
	    <img src="packages.png" />
	<h3>List of packages</h3>
	  <p class="explanation">The list contains all Prolog files included within the project, along
	    with some top-level statistics of the files. Click on the file name to view details on
	    the package.</p>
	<table class="detailsTable">
	  <tr class="mainHdr">
	    <th class="lastInGroup">Package</th>
	    <th>Fan-in</th>
	    <th class="lastInGroup">Fan-out</th>
	    <th class="lastInGroup">Predicates</th>
	    <th>Volume</th>
	    <th class="lastInGroup">Effort</th>
	    <th colspan="2">Average LC</th>
	  </tr>
_END
    my $trClass = "odd";
    for my $pkg (sort @$pkgs) {
	my $pkgpage = package_page_name($pkg);
	my $info = package_overall_info($pkg, $data->{$pkg}, $deps);
	my $complexity_rating = rate::local_complexity($info->{average_complexity});
	my $volume_rating = rate::package_volume($info->{total_volume});
	my $effort_rating = rate::package_effort($info->{total_effort});

	print OVERALL <<_END;
	  <tr class="$trClass">
	      <td class="mainCell lastInGroup"><a href="$pkgpage">$pkg</a></td>
	      <td>$info->{fan_in}</td>
	      <td class="lastInGroup">$info->{fan_out}</td>
	      <td class="lastInGroup">$info->{n_predicates}</td>
	      <td class="numeric" style="color: $volume_rating->{color}">
	         ${format_float($info->{total_volume})}
	      </td>
	      <td class="lastInGroup numeric" style="color: $effort_rating->{color}">
	         ${format_float($info->{total_effort})}
	      </td>
	      <td class="right numeric">${format_float($info->{average_complexity})}</td>
              <td class="left" style="color: $complexity_rating->{color}">($complexity_rating->{long})</td>
	  </tr>
_END
        $trClass = ($trClass eq 'odd') ? 'even' : 'odd';
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
    my $volume_rating = rate::package_volume($details->{halstead}->{volume});
    my $effort_rating = rate::package_effort($details->{halstead}->{effort});
				     
    my $preds = pl_package::get_predicates($data);
    my @predicates = sort { $a->{name} cmp $b->{name} } @$preds;
    my @incoming = @{$deps->{incoming}->{$pkg}};
    my @outgoing = @{$deps->{outgoing}->{$pkg}};

    print OUTPUT <<_END;
    <a class="backLink" href="index.html">Back to package list</a>
    <h2>Package <span class="packageName">$pkg</span></h2>
    <div class="separator"></div>	
	
    <h3>Package summary</h3>

       <table class="summaryTable">
         <tr><td colspan="2" class="hdr">Code metrics</th></tr>
	 <tr><th>Total lines of code</th><td>$details->{code}->{loc}</td></tr>
	 <tr><th>Lines with effective code</th><td>$details->{code}->{effective_loc}</td></tr>
	 <tr><th>Lines with comments</th><td>$details->{code}->{loc_comments}</td></tr>
	 <tr><th>Comments per effective line</th><td>${format_float($details->{code}->{comments_per_line})}</td></tr>
       </table>
	 
       <table class="summaryTable">
	 <tr><td colspan="2" class="hdr">Predicate statistics</th></tr>
	 <tr><th>Number of predicates</th><td>$details->{predicates}->{number}</td></tr>
	 <tr><th>LOC per predicate</th><td>${format_float($details->{predicates}->{loc_per_predicate})}</td></tr>
	 <tr><th>Comment lines per predicate</th><td>${format_float($details->{predicates}->{comments_per_predicate})}</td></tr>
       </table>

       <table class="summaryTable">
	 <tr><td colspan="2" class="hdr">Package metrics</th></tr>
	 <tr><th>Total volume</th><td style="color: $volume_rating->{color}">${format_float($details->{halstead}->{volume})}</td></tr>
	 <tr><th>Total effort</th><td style="color: $effort_rating->{color}">${format_float($details->{halstead}->{effort})}</td></tr>
	 <tr><th>Estimated time to implement</th><td>${format_time($details->{halstead}->{time})}</td></tr>
	 <tr><th>Average clause complexity</th>
	     <td>${format_float($details->{complexity}->{average_complexity})}
                 <span style="color: $complexity_rating->{color}">($complexity_rating->{long})</span>
	     </td></tr>
       </table>

       <table class="summaryTable">
	 <tr><td colspan="2" class="hdr">
	    <a class="detailsShowHideLink" href="#">Show details &gt;&gt;</a>
	    Package coupling metrics</th></tr>
	 <tr><th>Fan-in</th><td>$details->{relationships}->{fan_in}</td></tr>
	 <tr><th>Fan-out</th><td>$details->{relationships}->{fan_out}</td></tr>
	 <tr id="couplingDetails"><td colspan="2" class="detailsHolder">
 	    <table class="hiddenDetails">
	    <tr>
	       <th class="inSummaryDetailsHdr">Consulted by:</th>
	       <th class="inSummaryDetailsHdr">Consults:</th>
	    </tr>
_END
    my $i = 0;
    while (defined $incoming[$i] || defined $outgoing[$i] || $i <= 0) {
	my ($incLink, $outLink);
	if (@incoming == 0 && $i == 0) {
	    $incLink = "(none)";
	} elsif (defined $incoming[$i]) {
	    my $page = package_page_name($incoming[$i]);
	    $incLink = "<a href=\"$page\">$incoming[$i]</a>";
	};
	if (@outgoing == 0 && $i == 0) {
	    $outLink = "(none)";
	} elsif (defined $outgoing[$i]) {
	    my $page = package_page_name($outgoing[$i]);
	    $outLink = "<a href=\"$page\">$outgoing[$i]</a>";
	};
	$i++;
	print OUTPUT <<_END;
	    <tr>
		<td>$incLink</td>
		<td>$outLink</td>
	    </tr>		
_END
    }
    print OUTPUT <<_END;
	    </table></tr></td>
       </table>

    <h3>Predicates</h3>

    Click on a predicate name to view details on its clauses.

    <table class="detailsTable">
    <tr class="mainHdr">
      <th rowspan="2" class="lastInGroup">Predicate</th>
      <th rowspan="2" class="lastInGroup">Clauses</th>
      <th colspan="6" class="lastInGroup">Halstead metrics</th>
      <th colspan="5" >Complexity</th>
    </tr>
    <tr class="subHdr">
      <th>Length</th><th>Vocabulary</th><th>Difficulty</th><th>Volume</th><th>Effort</th><th class="lastInGroup">Time</th>
      <th colspan="2">Average</th>
      <th colspan="2">Maximum</th>
      <th>Sum</th>
    </tr>    
_END

    my $trClass = "odd";
    my $pn = 0;
    for my $p (@predicates) {
	my $clauses = $p->{local}->{partitions};
	my $n_clauses = @$clauses;
	my $est_time = ${format_time($p->{halstead}->{time})};
	my $av_compl_rating = rate::local_complexity($p->{local}->{average});
	my $mx_compl_rating = rate::local_complexity($p->{local}->{max});
	my $t_compl_rating  = rate::total_complexity($p->{local}->{sum});
	my $diff_rating = rate::difficulty($p->{halstead}->{difficulty});
	my $effort_rating = rate::predicate_effort($p->{halstead}->{effort});
	my $volume_rating = rate::predicate_volume($p->{halstead}->{volume});

        print OUTPUT <<_END;
    <tr class="$trClass">
	<td class="mainCell lastInGroup"><a class="cdShowHide" cdid="$pn">$p->{name}</a></td>
	<td class="lastInGroup">$n_clauses</td>
	<td>$p->{halstead}->{length}</td>
	<td>$p->{halstead}->{vocabulary}</td>
	<td class="numeric" style="color: $diff_rating->{color}">${format_float($p->{halstead}->{difficulty})}</td>
	<td class="numeric" style="color: $volume_rating->{color}">${format_float($p->{halstead}->{volume})}</td>
	<td class="numeric" style="color: $effort_rating->{color}">${format_float($p->{halstead}->{effort})}</td>
	<td class="lastInGroup">$est_time</td>
	<td class="right numeric">${format_float($p->{local}->{average})}</td>
	<td class="left" style="color: $av_compl_rating->{color}" 
	    title="$av_compl_rating->{long}">($av_compl_rating->{short})</td>
	<td class="right numeric">${format_float($p->{local}->{max})}</td>
	<td class="left" style="color: $mx_compl_rating->{color}"
	    title="$mx_compl_rating->{long}">($mx_compl_rating->{short})</td>
	<td style="color: $t_compl_rating->{color}">$p->{local}->{sum}</td>
    </tr>
    <tr><td colspan="13" class="detailsHolder">
      <div class="clausesDetails" id="cd_$pn">
        <table class="detailsTable">
	   <tr class="mainHdr">
	     <th rowspan="2" class="lastInGroup">#</td>
	     <th rowspan="2" class="lastInGroup">Type</td>
	     <th colspan="4" class="lastInGroup">Local complexity details</th>
	     <th rowspan="2" colspan="2">Complexity</th>
	   </tr>
	   <tr class="subHdr">
	     <th>Sub</th>
	     <th>Dat</th>
	     <th>Var</th>
	     <th class="lastInGroup">Rel</th>
	   </tr>
_END
        my $inTrClass = 'odd';
        for my $c (@$clauses) {
	    my $compl = $c->{subproblems} + $c->{new_entities} + $c->{new_variables} + $c->{relations_complexity};
	    my $compl_rating = rate::local_complexity($compl);
	    print OUTPUT <<_END;
	    <tr class="$inTrClass">
		<td class="lastInGroup">${\($c->{id}+1)}</td>
		<td class="lastInGroup">&nbsp;</td>
		<td>$c->{subproblems}</td>
		<td>$c->{new_entities}</td>
		<td>$c->{new_variables}</td>
		<td class="lastInGroup">$c->{relations_complexity}</td>
		<td class="right">$compl</td><td class="left" style="color: $compl_rating->{color}">($compl_rating->{long})</td>
	    </tr>
_END
            $inTrClass = ($inTrClass eq 'odd') ? 'even' : 'odd';
        }
	print OUTPUT <<_END;
	</table>
    </td></tr>
_END
        $trClass = ($trClass eq 'even') ? 'odd' : 'even';
	$pn++;
    }

    print OUTPUT <<_END;
    </table>
_END
    html::footer(\*OUTPUT);
}

sub project_overall_info($) {
    my ($data, $deps) = @_;

    my $loc = 0;
    my $eloc = 0;
    my $cloc = 0;
    my $total_effort = 0;
    my $total_volume = 0;
    my $total_time = 0;
    my $total_complexity = 0;
    my $total_predicates = 0;

    my $pkgs = util::get_packages($data);
    my $n_packages = @$pkgs;
    for my $pkg (@$pkgs) {
	my $info = package_info($pkg, $data->{$pkg}, $deps);
	
	$loc += $info->{code}->{loc}, 
	$eloc += $info->{code}->{effective_loc},
	$cloc += $info->{code}->{loc_comments}, 

	$total_effort += $info->{halstead}->{effort};
	$total_volume += $info->{halstead}->{volume};
	$total_predicates += $info->{predicates}->{number};
	$total_complexity += $info->{complexity}->{average_complexity} * $info->{predicates}->{number};
	$total_time += $info->{halstead}->{time};
    }

    return { 
	code => {
	    loc => $loc, 
	    eloc => $eloc,
	    comments_per_line => $eloc == 0 ? 0 : $cloc / $eloc,
	}, 
	packages => {
	    number => $n_packages, 
	    loc_per_package => $n_packages == 0 ? 0 : $loc / $n_packages,
	}, 
	halstead => {
	    volume => $total_volume, 
	    effort => $total_effort, 
	    time => $total_time * (log($n_packages+1) / log(2)),
	}, 
	predicates => {
	    number => $total_predicates, 
	    ave_loc => $total_predicates == 0 ? 0 : $loc / $total_predicates, 
	    ave_complexity => $total_predicates == 0 ? 0 : $total_complexity / $total_predicates,
	},
    };
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
	    time   => $overall->{total_effort} / 10 * (log($n_predicates + 1) / log(2)),
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


sub format_time($) {
    my ($seconds) = @_;

    my $spm = 60;
    my $sph = $spm * 60;
    my $spd = $sph * 8;

    my $days = int($seconds / $spd);
    my $hours = int(($seconds - $spd * $days) / $sph);
    my $mins = int(($seconds - $spd * $days - $sph * $hours) / $spm);
    my $secs = int($seconds - $spd * $days - $sph * $hours - $spm * $mins);

    my @result = ();
    push @result, "$days days" if $days > 0;
    push @result, "$hours hours" if $hours > 0; 
    push @result, "$mins minutes" if $mins > 0;
    push @result, "$secs seconds" if $mins + $days + $hours == 0;

    return \(join ', ', @result);
}

sub format_float($) {
    my ($f) = @_;
    return \(sprintf "%.2f", $f);
}
