#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use MIME::Base64;
use IO::Pipe;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use File::Temp;
use Data::Dumper;

my $tmp = File::Temp->newdir;

BEGIN { use_ok('File::Hardhat') or BAIL_OUT('need File::Hardhat to run') }
BEGIN { use_ok('File::Hardhat::Maker') or BAIL_OUT('need File::Hardhat::Maker to run') }

do {
	my $x = '../..';
	my $y = hardhat_normalize($x);
	is($x, '../..', "hardhat_normalize() in scalar context does not modify its argument");
	is($y, '', "hardhat_normalize() in scalar context returns the normalized value");
	$x = '../..';
	my @y = hardhat_normalize($x);
	is($x, '../..', "hardhat_normalize() in list context does not modify its argument");
	is_deeply(\@y, [''], "hardhat_normalize() in list context returns the normalized value");
	hardhat_normalize($x);
	is($x, '', "hardhat_normalize() in void context modifies its argument");
};

foreach my $path (
		['foo' => 'foo'],
		['foo/bar' => 'foo/bar'],
		['foo/.' => 'foo'],
		['foo/..' => ''],
		['foo/../..' => ''],
		['..' => ''],
		['../..' => ''],
		['foo//bar' => 'foo/bar'],
		['/foo/bar' => 'foo/bar'],
		['//foo/bar' => 'foo/bar'],
		['./foo/bar' => 'foo/bar'],
		['.//foo/bar' => 'foo/bar'],
		['foo/./bar' => 'foo/bar'],
		['foo//./bar' => 'foo/bar'],
		['foo/.//bar' => 'foo/bar'],
		['foo//.//bar' => 'foo/bar'],
		['../foo//.//bar' => 'foo/bar'],
		['./..//foo//.//bar' => 'foo/bar'],
		['.//..//foo//.//bar' => 'foo/bar'],
		['/.//..//foo//.//bar' => 'foo/bar'],
		['/..//foo//.//bar' => 'foo/bar'],
		['//..//foo//.//bar' => 'foo/bar'],
		['foo/bar/../bar' => 'foo/bar'],
		['foo/bar//../bar' => 'foo/bar'],
		['foo/bar/..//bar' => 'foo/bar'],
		['foo/bar//..//bar' => 'foo/bar'],
		['foo/bar/./../bar' => 'foo/bar'],
		['foo/bar/.././bar' => 'foo/bar'],
		['foo/bar/bar/..' => 'foo/bar'],
		['foo/bar/bar//..' => 'foo/bar'],
		['foo/bar/bar/../.' => 'foo/bar'],
		['foo/bar/bar/..//.' => 'foo/bar'],
		['foo/bar/bar//..//.' => 'foo/bar'],
		['foo/bar/bar//../.' => 'foo/bar'],
		['foo/bar/' => 'foo/bar'],
		['foo/bar//' => 'foo/bar'],
		['foo/bar//.' => 'foo/bar'],
		['foo/bar/./' => 'foo/bar'],
		['foo/bar/.//' => 'foo/bar'],
	) {
		my ($u, $n) = @$path;
		is(hardhat_normalize($u), $n, "normalize \"$u\"");
}

my $testhat_ne = "$tmp/testdata_ne.hh";
my $testhat_le = "$tmp/testdata_le.hh";
my $testhat_be = "$tmp/testdata_be.hh";

do {
	my $hhm = new_ok('File::Hardhat::Maker', [$testhat_ne]) or BAIL_OUT('need a File::Hardhat::Maker object to run');

	$hhm->add('', '');
	$hhm->add('bar', 'BBBBBBBBBB');
	$hhm->add('foo', 'AAAAAAAAAA');
	$hhm->add('dir/bar', 'DDDDDDDDDD');
	$hhm->add('dir/foo', 'CCCCCCCCCC');
	$hhm->add('dir/sub/bar', 'FFFFFFFFFF');
	$hhm->add('dir/sub/foo', 'EEEEEEEEEE');
	$hhm->parents;
	$hhm->finish;
};

do {
	my $data = decode_base64(<<'EOT');
H4sIALS8sVMCA+3ZMUvDQBjG8WujpipoEHGKUsjmYmenRlvJUhBxdNAgDU6BStWh4CaIuDuLKOgm
IkXwI7iJkyB+gk7u3nFvj+LoIEX+v+XhfXMXwmW6u8Uk3qgl8WYhqmendy89pVRROeuSQT8fbFak
riQ2y1KXpa5KXTUTx807L2du2goAAAAAAPy5w+ysM1BOKC/daa040mvmeezYnr+711rSY2vOQF+P
X3Vsf9L099upmbPm/Him59Ud+0Weftb/Ol/G8dsAAAAAAPgld79fkryQDCXlwj+Q+/3gSnJbssMa
AgAAAAAwvKbjk3eTYfp5r8Nbvn3LdI7mfsOcAZQOuq+zOv2j+V5DZ+E8mTrWOfJ4/fWhc+x5a8Gc
ERRZSQAAAAAAhlfYjCKzn4+f5rpmn8+KAAAAAADw/3wD/SKyVgBQAAA=
EOT
	gunzip(\$data => $testhat_be)
		or die "gunzip(data => $testhat_be): $GunzipError\n";
};

do {
	my $data = decode_base64(<<'EOT');
H4sIAP7CsVMCA+3aMUvDQBiA4aupTW1AioOLxYodlC52LJ2MtpJJRFwcBC2iiGCkKoj4B1xd1ElB
B1Hc/BsdxEkQXF2KIE5Ofkm/HuLmIkXeB8LbXO5KuEylKQb+fDXwF96at0frtUKix6g5bbade60p
tRNozYiea82kLtP2yRF95+jH7pABAAAAAAB/bracWep8zsjhmPpKY8rSsbUw9K14zDWrG40JmVu1
vo3L/GkrHvfi8Z29erRmxvpxTdbVrPienOia3p/bmcdjAwAAAADg9/R//bT2VJvTlrSB9kq7rD3M
soUAAAAAAHS7XPO82CsdLl8vJqWD495+SnqS2jpISI/H8heO9P3m8S4t3X7+fHKlrYHKa/Re/8tl
f4tdBAAAAACgu216YT76PV+oPJwl2Q4AAAAAAP6lL4SLWIYAUAAA
EOT
	gunzip(\$data => $testhat_le)
		or die "gunzip(data => $testhat_le): $GunzipError\n";
};

foreach my $testhat ($testhat_ne, $testhat_le, $testhat_be) {
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
}

done_testing();
