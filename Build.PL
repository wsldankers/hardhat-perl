#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Module::Build;

my $build = new Module::Build(
	module_name => 'Hardhat',
	dist_abstract => 'Wrapper for libhardhat',
	license => 'perl',
	create_makefile_pl => 'passthrough',
	build_requires => {'ExtUtils::CBuilder' => 0},
	extra_linker_flags => '-lhardhat',
);

$build->create_build_script;
