package util;

use strict;
use File::Spec;
use Data::Dumper;

use pl_package;

my $base_dir;
my $links = {};

return 1;

sub init_files($) {
    my ($files) = @_;
    $base_dir = main_dir($files);
}

sub add_analysis($$;$) {
    my ($file, $data, $parent) = @_;

    my ($canon_name, $rel_dir) = canon_name_and_dir($file, $base_dir);

    $links->{$canon_name} = [] unless defined $links->{$canon_name};
    if (defined $parent) {
	push @{$links->{$parent}}, { ref => $canon_name };
    }

    unless (defined $data->{$canon_name}) {  # Cycle-safe
	my $pkg_data = pl_package::get_data($file);
	$data->{$canon_name} = $pkg_data;
	my $links = pl_package::get_links($pkg_data);

	for (@$links) {
	    my $linkedfile = package_file_name($_, $rel_dir, $base_dir);
	    add_analysis($linkedfile, $data, $canon_name);
	};
    };
}

sub postprocess_data($) {
    my ($data) = @_;
    
    # Replace simple relative links with canon package names.
    for my $pkg (@{get_packages($data)}) {
	$data->{$pkg}->{links} = $links->{$pkg};
    }
}

sub main_dir($) {
    my ($files) = @_;

    use Data::Dumper;

    my @paths = ();
    for (@$files) {
	my $absolute = File::Spec->file_name_is_absolute($_) ? $_ : File::Spec->rel2abs($_);
	my ($vol, $dirname, $filename) = File::Spec->splitpath($absolute);
	my @path = File::Spec->splitdir($dirname);
	push @paths, [@path];
    }

    my @common;
    if (@paths == 1) {
	@common = @{$paths[0]};
    } else {
	@common = ();
	my $common = 1;
	while ($common) {
	    my $first = 1;
	    my $value;
	    for (@paths) {
		if ($first) {
		    $value = shift(@$_);
		    $first = 0;
		} else {
		    if (shift(@$_) ne $value) {
			$common = 0;
		    };
		};
	    };
	    push @common, $value if $common;
	}
    }

    my $result = File::Spec->catdir(@common);
    return $result;
}

sub canon_name_and_dir($$) {
    my ($filename, $base) = @_;
    
    $filename = File::Spec->rel2abs($filename) if File::Spec->file_name_is_absolute($filename);
    my $relative = File::Spec->abs2rel($filename, $base);
    my ($vol, $reldir, $fname) = File::Spec->splitpath($relative);

    $relative =~ s|\.pl||;
    return ($relative, $reldir);
}

sub package_file_name($$) {
    my ($link, $sourcedir, $basedir) = @_;

    my ($vol, $linkdir, $filename) = File::Spec->splitpath($link);
    $filename .= '.pl' unless $filename =~ /\.pl$/;

    my @linkdir = File::Spec->splitdir($linkdir);
    my @sourcedir = File::Spec->splitdir($sourcedir);
    my @basedir = File::Spec->splitdir($basedir);

    my @reldir = (@basedir, @sourcedir, @linkdir);
    my $reldir = File::Spec->catdir(@reldir);
    my $relpath = File::Spec->catpath("", $reldir, $filename);

    return $relpath;
}

sub get_packages($) {
    my ($data) = @_;
    return [keys %$data];
}

sub project_overall_info($$) {
    my ($data, $deps) = @_;

    my $loc = 0;
    my $eloc = 0;
    my $cloc = 0;
    my $total_effort = 0;
    my $total_volume = 0;
    my $total_time = 0;
    my $total_complexity = 0;
    my $total_predicates = 0;
    my $links = 0;

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

	$links += $info->{relationships}->{fan_in};
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
	    time => $total_time * (log($links+1) / log(2)),
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
