/******************************************************************************

	File::Hardhat::Maker - Create hardhat databases in Perl
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

	if(!sv || !SvROK(sv))
		return NULL;

	sv = SvRV(sv);
	if(!sv || !SvMAGICAL(sv))
		return NULL;

	mg = mg_findext(sv, PERL_MAGIC_ext, vtable);
	if(!mg)
		return NULL;

	return SvPV_nolen(mg->mg_obj);
}

static void *attach_magic(SV *sv, MGVTBL *vtable, const char *name, void *data, STRLEN len) {
	SV *obj = newSVpvn(data, len);
	sv_magicext(sv, obj, PERL_MAGIC_ext, vtable, name, 0);
	return SvPV_nolen(obj);
}

static int free_magic_hardhat_maker(pTHX_ SV *sv, MAGIC *mg) {
	void **obj = (void *)SvPV_nolen(mg->mg_obj);
	if(obj)
		hardhat_maker_free(*obj);
	SvREFCNT_dec(mg->mg_obj);
	return 0;
}

STATIC MGVTBL hardhat_maker_vtable = {
	.svt_free = free_magic_hardhat_maker
};

static hardhat_maker_t *find_magic_hardhat_maker(SV *sv) {
	void **obj;
	hardhat_maker_t *hhm;

	obj = find_magic(sv, &hardhat_maker_vtable);
	if(!obj)
		croak("Invalid hardhat_maker object");

    hhm = *obj;
	if(!hhm)
		croak("Invalid hardhat_maker object");

	if(hardhat_maker_fatal(hhm))
		croak("Invalid hardhat_maker object");

	return hhm;
}

MODULE = File::Hardhat::Maker  PACKAGE = File::Hardhat::Maker

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

void
add(SV *self, SV *key, SV *data)
PREINIT:
	void *keybuf, *databuf;
	STRLEN keylen, datalen;
	hardhat_maker_t *hhm;
CODE:
    hhm = find_magic_hardhat_maker(self);

	keybuf = SvPV(key, keylen);
	databuf = SvPV(data, datalen);

	if(keylen > 65535)
		croak("Key too large (%lu > 65535 bytes)", (unsigned long)keylen);

	if(!hardhat_maker_add(hhm, keybuf, keylen, databuf, datalen))
		croak("%s", hardhat_maker_error(hhm));

void
parents(SV *self, ...)
PREINIT:
	SV *data;
	void *databuf;
	STRLEN datalen;
	hardhat_maker_t *hhm;
CODE:
    hhm = find_magic_hardhat_maker(self);

	if(items == 1) {
		databuf = NULL;
		datalen = 0;
	} else if(items == 2) {
		data = ST(1);
		databuf = SvPV(data, datalen);
	} else {
		croak("Too many arguments to File::Hardhat::Maker::parents()");
	}

	if(!hardhat_maker_parents(hhm, databuf, datalen))
		croak("%s", hardhat_maker_error(hhm));

void
finish(SV *self)
PREINIT:
	hardhat_maker_t *hhm;
CODE:
    hhm = find_magic_hardhat_maker(self);

	if(!hardhat_maker_finish(hhm))
		croak("%s", hardhat_maker_error(hhm));
