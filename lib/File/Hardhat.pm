use strict;
use warnings FATAL => 'all';
use bytes;

package File::Hardhat;

use parent qw(DynaLoader);
use Exporter qw(import);

our @EXPORT =
our @EXPORT_OK = qw(hardhat_normalize);

bootstrap File::Hardhat;

1;

__END__

=pod

=encoding utf8

=head1 NAME

File::Hardhat - wrapper for reading libhardhat files

=head1 SYNOPSIS

File::Hardhat is a wrapper around the libhardhat library, and provides
read-only access to hardhat databases.

All functions and methods die() should an error be encountered.
Use eval {} as required.

=head1 USAGE

=head2 $hh = new File::Hardhat($filename)

Creates a new File::Hardhat object from the file named by $filename.

=head2 $hh->exists($key)

Check if the named key exists.

=head2 $hh->get($key)

Retrieve the specified key. In scalar context, returns the data
associated with the specified key (or undef if it doesn't exist).
In list context, returns the canonicalized key, the data and a unique
numeric identifier for this datum (or the empty list if the key was not
found).

=head2 $hh->getn($key, $limit)

Like $hh->get($key), but returns only at most $limit bytes of the data.

=head2 $cc = $hh->find($key)

Start a recursive listing for $key. Returns a File::Hardhat::Cursor object.

=head2 $cc = $hh->ls($key)

Start a shallow listing for $key. Returns a File::Hardhat::Cursor object.

=head2 $norm = hardhat_normalize($str)

Returns a normalized version of $str, that is, with leading and trailing
slashes removed and all "." and ".." path components resolved.

=head2 hardhat_normalize($str)

If you use hardhat_normalize() in void context, it operates on the argument
(in-place).

=head1 COPYRIGHT

Copyright (c) 2011,2012,2014 Wessel Dankers <wsl@fruit.je>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
