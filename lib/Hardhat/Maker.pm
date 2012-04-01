use strict;
use warnings FATAL => 'all';
use bytes;

package Hardhat::Maker;

use base qw(DynaLoader);

our $VERSION = 1.00;

bootstrap Hardhat::Maker;

1;

__END__

=pod

=encoding utf8

=head1 Hardhat::Maker

Hardhat::Maker is a wrapper around the libhardhat library, and provides
a way to generate hardhat databases.

All functions and methods die() should an error be encountered.
Use eval {} as required.

=head2 Usage

=head3 $hh = new Hardhat::Maker($filename)

Creates a new Hardhat::Maker object. A database will be created at
$filename.

=head3 FIXME

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
