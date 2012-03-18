use strict;
use warnings FATAL => 'all';
use bytes;

package Hardhat;

use base qw(DynaLoader);

our $VERSION = 1.00;

bootstrap Hardhat;

1;
