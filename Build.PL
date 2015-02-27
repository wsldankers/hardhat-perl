#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Module::Build;
use File::Find;

do {
	# create the MANIFEST file on the fly
	open my $fh, '>', 'MANIFEST' or die "open(MANIFEST): $!\n";
	find({wanted => sub { return unless -f; print $fh "$_\n" or die "write(MANIFEST): $!\n" }, no_chdir => 1, follow => 0}, 'lib');
	close $fh or die "close(MANIFEST): $!\n";
};

my $build = new Module::Build(
	dist_name => 'hardhat-perl',
	dist_version => '2.1.0',
	dist_abstract => 'Wrapper for libhardhat',
	module_name => 'File::Hardhat',
	license => 'perl',
	create_makefile_pl => 'passthrough',
	build_requires => {'ExtUtils::CBuilder' => 0},
	extra_linker_flags => '-lhardhat',
);

$build->create_build_script;
