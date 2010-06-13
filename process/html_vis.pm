#!/usr/bin/perl

package html_vis;

use Data::Dumper;
use GraphViz;
use utf8;

use html;
use util;
use rate;

return 1;

sub visualise($) {
    my ($data) = @_;
    
    my $deps = util::get_dependencies($data);
    create_dep_graph($deps);
    project_summary($data, $deps);    

    for my $pkg (sort @{util::get_packages($data)}) {
	package_details($pkg, $data->{$pkg}, $deps);
    }
}

sub project_summary($) {
    my ($data, $deps) = @_;
    my $summary = util::project_overall_info($data, $deps);

    open OVERALL, ">output/index.html";
    html::header(\*OVERALL, "Metrics for Prolog");

    print OVERALL <<_END;
        <h2>Project metrics summary</h2>
	<div class="separator"></div>
_END

    print_project_summary(\*OVERALL, $summary); 
    print_dependency_graph(\*OVERALL);
    print_package_list(\*OVERALL, $data, $deps);
    
    html::footer(\*OVERALL);
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
    my $preds = pl_package::get_predicates($data);
    my @predicates = sort { $a->{name} cmp $b->{name} } @$preds;

    open OUTPUT, ">output/$out";
    html::header(\*OUTPUT, "Package $pkg");
    print OUTPUT <<_END;
    <a class="backLink" href="index.html">Back to package list</a>
    <h2>Package <span class="packageName">$pkg</span></h2>
    <div class="separator"></div>	
_END

    print_package_summary(\*OUTPUT, $pkg, $data, $deps);
    print_predicate_list(\*OUTPUT, \@predicates);
    html::footer(\*OUTPUT);
}

# Output element printing

sub print_project_summary($$) {
    my ($out, $summary) = @_;
    my $compl_rating = rate::local_complexity($summary->{predicates}->{ave_complexity});

    print $out <<_END;
	<h3>Project summary</h3>
	  <table class="summaryTable">
	    <tr><td colspan="2" class="hdr">Code metrics</th></tr>
	    <tr><th>Lines of code</th><td>$summary->{code}->{loc}</td></tr>
            <tr><th>Lines of effective code</th><td>$summary->{code}->{eloc}</td></tr>
            <tr><th title="Number of comments per effective line of code">Comments per line</th><td>${format_float($summary->{code}->{comments_per_line})}</td></tr>
	  </table>
	  <table class="summaryTable">
	    <tr><td colspan="2" class="hdr">Halstead metrics</th></tr>
	    <tr><th title="Sum of all package volumes">Total volume</th><td>${format_float($summary->{halstead}->{volume})}</td></tr>
	    <tr><th title="Sum of all package efforts">Total effort</th><td>${format_float($summary->{halstead}->{effort})}</td></tr>
	    <tr><th title="Sum of all package efforts multiplied by a logarithm of the number of packages">Total time</th><td>${format_time($summary->{halstead}->{time})}</td></tr>
	  </table>
	  <table class="summaryTable">
	    <tr><td colspan="2" class="hdr">Packages</th></tr>
	    <tr><th>Number of packages</th><td>$summary->{packages}->{number}</td></tr>
	    <tr><th>Average LOC per package</th><td>${format_float($summary->{packages}->{loc_per_package})}</td></tr>
	  </table>
	  <table class="summaryTable">
	    <tr><td colspan="2" class="hdr">Predicates</th></tr>
	    <tr><th>Number of predicates</th><td>$summary->{predicates}->{number}</td>
	    <tr><th>Average LOC per predicate</th><td>${format_float($summary->{predicates}->{ave_loc})}</td>
	    <tr><th title="Average local complexity measure for the project's clause">Average complexity</th>
	      <td>${format_float($summary->{predicates}->{ave_complexity})}
                  <span style="color: $compl_rating->{color}">($compl_rating->{long})</span>
              </td></tr>
	  </table>
_END
}
	  
sub print_dependency_graph($) {
    my ($out) = @_;

    print $out <<_END;
	<h3>Package dependency graph</h3>
	  <p class="explanation">The following graph shows relationships between the project modules. 
	    An arrow from package X to package Y means that package X consults Y. </p>
	    <img src="packages.png" />
_END
}

sub print_package_list($$$) {
    my ($out, $data, $deps) = @_;
    my $pkgs = util::get_packages($data);

    print $out <<_END;
	<h3>List of packages</h3>
	  <p class="explanation">The list contains all Prolog files included within the project, along
	    with some top-level statistics of the files. Click on the file name to view details on
	    the package.</p>
	<table class="detailsTable">
	  <tr class="mainHdr">
	    <th class="lastInGroup">Package</th>
	    <th title="Number of packages consulted by this package">Fan-in</th>
	    <th class="lastInGroup" title="Number of packages the package consults">Fan-out</th>
	    <th class="lastInGroup">Predicates</th>
	    <th title="Measure of how big the package is; total of predicate volumes">Volume</th>
	    <th class="lastInGroup" title="Measure of how hard the package is to create or understand; total of all predicate effort measures">Effort</th>
	    <th colspan="2" title="Average local complexity measure of the package's clauses">Average LC</th>
	  </tr>
_END

    my $even = 0;
    for my $pkg (sort @$pkgs) {
	print_package_row($out, $pkg, $data, $deps, $even);
        $even = $even ? 0 : 1;
    };
    
    print $out <<_END;
        </table>
_END
}


sub print_package_row($$$$;$) {
    my ($out, $pkg, $data, $deps, $even) = @_;

    my $pkgpage = package_page_name($pkg);
    my $info = util::package_overall_info($pkg, $data->{$pkg}, $deps);
    my $complexity_rating = rate::local_complexity($info->{average_complexity});
    my $volume_rating = rate::package_volume($info->{total_volume});
    my $effort_rating = rate::package_effort($info->{total_effort});
    my $trClass = $even ? 'even' : 'odd';

    print $out <<_END;
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
}

sub print_package_summary($$$$) {
    my ($out, $pkg, $data, $deps) = @_;

    my $details = util::package_info($pkg, $data, $deps);
    my $complexity_rating = rate::local_complexity($details->{complexity}->{average_complexity});
    my $volume_rating = rate::package_volume($details->{halstead}->{volume});
    my $effort_rating = rate::package_effort($details->{halstead}->{effort});

    print $out <<_END;
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
	 <tr><th title="Sum of volume measures for predicates">Total volume</th><td style="color: $volume_rating->{color}">${format_float($details->{halstead}->{volume})}</td></tr>
	 <tr><th title="Sum of effort measures for predicates">Total effort</th><td style="color: $effort_rating->{color}">${format_float($details->{halstead}->{effort})}</td></tr>
	 <tr><th title="Sum of time estimates for predicates multiplied by a logarithm of the number of predicates">Estimated time to implement</th><td>${format_time($details->{halstead}->{time})}</td></tr>
	 <tr><th>Average clause complexity</th>
	     <td>${format_float($details->{complexity}->{average_complexity})}
                 <span style="color: $complexity_rating->{color}">($complexity_rating->{long})</span>
	     </td></tr>
       </table>

       <table class="summaryTable">
	 <tr><td colspan="2" class="hdr">
	    <a class="detailsShowHideLink">Show details &gt;&gt;</a>
	    Package coupling metrics</th></tr>
	 <tr><th title="Number of packages that consult this one">Fan-in</th><td>$details->{relationships}->{fan_in}</td></tr>
	 <tr><th title="Number of packages this package consults">Fan-out</th><td>$details->{relationships}->{fan_out}</td></tr>
	 <tr id="couplingDetails"><td colspan="2" class="detailsHolder">
_END

    print_links($out, $pkg, $deps);

    print $out <<_END;
         </td></tr>
       </table>
_END
}

sub print_links($$$) {
    my ($out, $pkg, $deps) = @_;
				     
    my @incoming = @{$deps->{incoming}->{$pkg}};
    my @outgoing = @{$deps->{outgoing}->{$pkg}};

    print $out <<_END;
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
	print $out <<_END;
	    <tr>
		<td>$incLink</td>
		<td>$outLink</td>
	    </tr>		
_END
    }
    print $out <<_END;
	    </table>
_END
}

sub print_predicate_list($$) {
    my ($out, $predicates) = @_;

    print $out <<_END;
    <h3>Predicates</h3>

    Click on a predicate name to view details on its clauses.

    <table class="detailsTable">
    <tr class="mainHdr">
      <th rowspan="2" class="lastInGroup" title="Standard Prolog predicate name">Predicate</th>
      <th rowspan="2" class="lastInGroup" title="Number of clauses in the predicate">Clauses</th>
      <th colspan="6" class="lastInGroup">Halstead metrics</th>
      <th colspan="5" >Complexity</th>
    </tr>
    <tr class="subHdr">
      <th title="Number of Prolog tokens">Length</th>
      <th title="Number of unique operators and operands">Vocabulary</th>
      <th title="Error proneness measure; proportional to the number of distinct operators and the average number of occurrences of operands">Difficulty</th>
      <th title="Predicate size measure">Volume</th>
      <th title="Measures how hard it is to write or understand the predicate. Proportional to Volume and Difficulty">Effort</th>
      <th class="lastInGroup" title="Rough estimate of time needed to write the predicate. Proportional to Effort.">Time</th>
      <th colspan="2" title="Average clause complexity">Average</th>
      <th colspan="2" title="Maximum clause complexity">Maximum</th>
      <th title="Sum of the complexities of all clauses">Sum</th>
    </tr>    
_END

    my $pn = 0;
    for my $p (@$predicates) {
	print_predicate_row($out, $p, $pn);
	$pn++;
    }

    print $out <<_END;
    </table>
_END
}


sub print_predicate_row($$$) {
    my ($out, $p, $pn) = @_;

    my $trClass = $pn % 2 ? 'odd' : 'even';

    my $clauses = $p->{local}->{partitions};
    my $n_clauses = @$clauses;
    my $est_time = ${format_time($p->{halstead}->{time})};
    my $av_compl_rating = rate::local_complexity($p->{local}->{average});
    my $mx_compl_rating = rate::local_complexity($p->{local}->{max});
    my $t_compl_rating  = rate::total_complexity($p->{local}->{sum});
    my $diff_rating = rate::difficulty($p->{halstead}->{difficulty});
    my $effort_rating = rate::predicate_effort($p->{halstead}->{effort});
    my $volume_rating = rate::predicate_volume($p->{halstead}->{volume});

    print $out <<_END;
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
_END

      print_clauses_list($out, $clauses, $pn);

    print $out <<_END;
      </td></tr>
_END
}

sub print_clauses_list($$$) {
    my ($out, $clauses, $pn) = @_;

    print $out <<_END;
	<div class="clausesDetails" id="cd_$pn">
          <table class="detailsTable">
	    <tr class="mainHdr">
	      <th rowspan="2" class="lastInGroup" title="Clause number">#</td>
	      <th rowspan="2" class="lastInGroup" title="Fact/Command/Clause">Type</td>
	      <th colspan="4" class="lastInGroup">Local complexity details</th>
	      <th rowspan="2" colspan="2" title="Total complexity of the clause, equal to Sub+Dat+Var+Rel">Complexity</th>
	    </tr>
	    <tr class="subHdr">
	      <th title="Number of subproblems into which the problem is divided">Sub</th>
	      <th title="Number of new data entities introduced in the left hand side of the clause">Dat</th>
	      <th title="Number of new variables introduced in the right hand side of the clause">Var</th>
	      <th class="lastInGroup" title="Measure of the complexity of relations between the subproblems. We add 1 for every disjunction and implication and 2 for every recursive call">Rel</th>
	    </tr>
_END

    my $even = 0;
    for my $c (sort {$a->{id} <=> $b->{id}} @$clauses) {
	print_clause_row($out, $c, $even);
	$even = $even ? 0 : 1;
    };

    print $out <<_END;
          </table>
_END
}

sub print_clause_row($$;$) {
    my ($out, $c, $even) = @_;

    my $compl = $c->{subproblems} + $c->{new_entities} + $c->{new_variables} + $c->{relations_complexity};
    my $compl_rating = rate::local_complexity($compl);
    my $trClass = $even ? 'even' : 'odd';

    print $out <<_END;
	<tr class="$trClass">
	    <td class="lastInGroup">${\($c->{id}+1)}</td>
	    <td class="lastInGroup">$c->{type}</td>
	    <td>$c->{subproblems}</td>
	    <td>$c->{new_entities}</td>
	    <td>$c->{new_variables}</td>
	    <td class="lastInGroup">$c->{relations_complexity}</td>
	    <td class="right">$compl</td><td class="left" style="color: $compl_rating->{color}">($compl_rating->{long})</td>
	</tr>
_END
}


# Utility functions

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

    return \("<nobr>" . (join ', ', @result) . "</nobr>");
}

sub format_float($) {
    my ($f) = @_;
    return \(sprintf "%.2f", $f);
}
