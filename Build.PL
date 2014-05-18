#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Module::Build;

my $build = new Module::Build(
	dist_name => 'hardhat-perl',
	dist_version => '1.0.1',
	dist_abstract => 'Wrapper for libhardhat',
	module_name => 'Hardhat',
	license => 'perl',
	create_makefile_pl => 'passthrough',
	build_requires => {'ExtUtils::CBuilder' => 0},
	extra_linker_flags => '-lhardhat',
);

$build->create_build_script;
