use strict;
use warnings FATAL => 'all';
use bytes;

package Hardhat;

use base qw(DynaLoader);

bootstrap Hardhat;

1;

__END__

=pod

=encoding utf8

=head1 Hardhat

Hardhat is a wrapper around the libhardhat library, and provides
read-only access to hardhat databases.

All functions and methods die() should an error be encountered.
Use eval {} as required.

=head2 Usage

=head3 $hh = new Hardhat($filename)

Creates a new Hardhat object from the file named by $filename.

=head3 $hh->exists($key)

Check if the named key exists.

=head3 $hh->get($key)

Retrieve the specified key. In scalar context, returns the data
associated with the specified key (or undef if it doesn't exist).
In list context, returns the canonicalized key, the data and a unique
numeric identifier for this datum (or the empty list if the key was not
found).

=head3 $hh->getn($key, $limit)

Like $hh->get($key), but returns only at most $limit bytes of the data.

=head3 $cc = $hh->find($key)

Start a recursive listing for $key. Returns a Hardhat::Cursor object.

=head3 $cc = $hh->ls($key)

Start a shallow listing for $key. Returns a Hardhat::Cursor object.

=head1 Hardhat::Cursor

Hardhat::Cursor is a cursor (or iterator) over entries in a hardhat
database.

=head2 Usage

=head3 $cc->fetch()

Fetch the next entry for this cursor. In scalar context, returns the data
associated with the specified key (or undef if no more entries are
available). In list context, returns the canonicalized key, the data and a
unique numeric identifier for this datum (or the empty list if no more
entries are available).

=head3 $cc->fetchn($limit)

Like $cc->fetch(), but returns only at most $limit bytes of the data.

=head3 $cc->read()

Returns the current entry for this cursor. If $cc->fetch() hasn't been
called yet on this cursor, it will act as $hh->get().

In scalar context, returns the data associated with the specified key (or
undef if no entry was available). In list context, returns the
canonicalized key, the data and a unique numeric identifier for this datum
(or the empty list if no entry was available).

=head3 $cc->readn($limit)

Like $cc->read(), but returns only at most $limit bytes of the data.

=head1 Copyright information

Copyright (c) 2011,2012 Wessel Dankers <wsl@fruit.je>.

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
