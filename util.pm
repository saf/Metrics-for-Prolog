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
