#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Module::Build;

my $build = new Module::Build(
	module_name => 'Hardhat',
	license => 'perl',
	create_makefile_pl => 'passthrough',
	build_requires => {'ExtUtils::CBuilder' => 0},
	extra_compiler_flags => '-I/opt/hardhat/include',
	extra_linker_flags => '-L/opt/hardhat/lib -Wl,-rpath,/opt/hardhat/lib -lhardhat',
);

$build->create_build_script;
