#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Data::Dumper;
use IO::Pipe;

BEGIN { use_ok('File::Hardhat') or BAIL_OUT('need File::Hardhat to run') }
BEGIN { use_ok('File::Hardhat::Maker') or BAIL_OUT('need File::Hardhat::Maker to run') }

my $testhat = '/tmp/testdata.hh';

unlink($testhat) or $!{ENOENT}
	or BAIL_OUT("Can't unlink $testhat: $!");

my $hhm = new_ok('File::Hardhat::Maker', [$testhat]) or BAIL_OUT('need a File::Hardhat::Maker object to run');

$hhm->add('', '');
$hhm->add('bar', 'BBBBBBBBBB');
$hhm->add('foo', 'AAAAAAAAAA');
$hhm->add('dir/bar', 'DDDDDDDDDD');
$hhm->add('dir/foo', 'CCCCCCCCCC');
$hhm->add('dir/sub/bar', 'FFFFFFFFFF');
$hhm->add('dir/sub/foo', 'EEEEEEEEEE');
$hhm->parents;
$hhm->finish;
undef $hhm;

my $hh = new_ok('File::Hardhat', [$testhat]) or BAIL_OUT('need a File::Hardhat object to run');

is(scalar $hh->get(''), '', "lookup the root node (scalar)");
is_deeply([$hh->get('')], ['', '', 0], "lookup the root node");

is(scalar $hh->get('foo'), 'AAAAAAAAAA', "lookup the foo node (scalar)");
is_deeply([$hh->get('foo')], ['foo', 'AAAAAAAAAA', 3], "lookup foo root node");

do {
	my $c = $hh->ls('dir');
	is(scalar $c->read, '', "immediate cursor lookup (scalar)");
	is_deeply([$c->read], ['dir', '', 2], "immediate cursor lookup");
	my %res;
	while(my ($key, $val) = $c->fetch) {$res{$key} = $val}
	is_deeply(\%res, {
		'dir/foo' => 'CCCCCCCCCC',
		'dir/bar' => 'DDDDDDDDDD',
		'dir/sub' => '',
	}, "shallow listing");
};

do {
	my $c = $hh->ls('dir');
	is(scalar $c->readn(5), '', "immediate cursor lookup (scalar)");
	is_deeply([$c->readn(5)], ['dir', '', 2], "immediate cursor lookup");
	my %res;
	while(my ($key, $val) = $c->fetchn(5)) {$res{$key} = $val}
	is_deeply(\%res, {
		'dir/foo' => 'CCCCC',
		'dir/bar' => 'DDDDD',
		'dir/sub' => '',
	}, "shallow listing limited to 5 bytes");
};

do {
	my $c = $hh->ls('dir');
	is(scalar $c->readn(15), '', "immediate cursor lookup (scalar)");
	is_deeply([$c->readn(15)], ['dir', '', 2], "immediate cursor lookup");
	my %res;
	while(my ($key, $val) = $c->fetchn(15)) {$res{$key} = $val}
	is_deeply(\%res, {
		'dir/foo' => 'CCCCCCCCCC',
		'dir/bar' => 'DDDDDDDDDD',
		'dir/sub' => '',
	}, "shallow listing limited to 15 bytes");
};

do {
	my $c = $hh->find('dir');
	is(scalar $c->read, '', "immediate cursor lookup (scalar)");
	is_deeply([$c->read], ['dir', '', 2], "immediate cursor lookup");
	my %res;
	while(my ($key, $val) = $c->fetch) {$res{$key} = $val}
	is_deeply(\%res, {
		'dir/foo' => 'CCCCCCCCCC',
		'dir/bar' => 'DDDDDDDDDD',
		'dir/sub' => '',
		'dir/sub/foo' => 'EEEEEEEEEE',
		'dir/sub/bar' => 'FFFFFFFFFF',
	}, "recursive listing");
};

do {
	my $c = $hh->find('dir');
	my $key = $c->fetch;
	is($key, 'dir/bar', "scalar fetch");
	is(scalar $c->read, 'DDDDDDDDDD', "scalar read");
};

do {
	ok($hh->exists('dir/foo'), "testing for a key that exists");
	ok(!$hh->exists('lol/wut'), "testing for a key that does not exist");
};

done_testing();
