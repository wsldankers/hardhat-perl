/******************************************************************************

	Hardhat::Maker - Create hardhat databases in Perl
	Copyright (c) 2012 Wessel Dankers <wsl@fruit.je>

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

******************************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <hardhat/maker.h>

static void *find_magic(SV *sv, MGVTBL *vtable) {
	MAGIC *mg;

	if(!sv)
		return NULL;

	if(!SvMAGICAL(sv))
		return NULL;

	for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
		if(mg->mg_virtual == vtable)
			return SvPV_nolen(mg->mg_obj);

	return NULL;
}

static void *attach_magic(SV *sv, MGVTBL *vtable, const char *name, void *data, STRLEN len) {
	SV *obj = newSVpvn(data, len);
	sv_magicext(sv, obj, PERL_MAGIC_ext, vtable, name, 0);
	return SvPV_nolen(obj);
}

static int free_magic_hardhat_maker(pTHX_ SV *sv, MAGIC *mg) {
	void **obj = (void *)SvPV_nolen(mg->mg_obj);
	if(obj)
		hardhat_close(*obj);
	SvREFCNT_dec(mg->mg_obj);
	return 0;
}

STATIC MGVTBL hardhat_maker_vtable = {
	.svt_free = free_magic_hardhat_maker
};

MODULE = Hardhat::Maker  PACKAGE = Hardhat::Maker

PROTOTYPES: ENABLE

SV *
new(char *class, const char *filename)
PREINIT:
	HV *hash;
	void *hhm;
CODE:
	hhm = hardhat_maker_new(filename);
	if(!hhm)
		croak("Can't create %s: %s\n", filename, strerror(errno));
	hash = newHV();
	attach_magic((SV *)hash, &hardhat_maker_vtable, "hardhat_maker", &hhm, sizeof hhm);
	RETVAL = sv_bless(newRV_noinc((SV *)hash), gv_stashpv(class, 0));
OUTPUT:
	RETVAL


