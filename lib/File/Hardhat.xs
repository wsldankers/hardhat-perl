/******************************************************************************

	File::Hardhat - Access hardhat databases in Perl
	Copyright (c) 2011,2012 Wessel Dankers <wsl@fruit.je>

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

#include <hardhat/reader.h>

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

static int free_magic_hardhat(pTHX_ SV *sv, MAGIC *mg) {
	void **obj = (void *)SvPV_nolen(mg->mg_obj);
	if(obj)
		hardhat_close(*obj);
	SvREFCNT_dec(mg->mg_obj);
	return 0;
}

STATIC MGVTBL hardhat_vtable = {
	.svt_free = free_magic_hardhat
};

struct cursorwrapper {
	hardhat_cursor_t *cursor;
	SV *hardhat;
	bool recursive;
};

static int free_magic_hardhat_cursor(pTHX_ SV *sv, MAGIC *mg) {
	struct cursorwrapper *obj = (void *)SvPV_nolen(mg->mg_obj);
	if(obj) {
		hardhat_cursor_free(obj->cursor);
		SvREFCNT_dec(obj->hardhat);
	}
	SvREFCNT_dec(mg->mg_obj);
	return 0;
}

STATIC MGVTBL hardhat_cursor_vtable = {
	.svt_free = free_magic_hardhat_cursor
};

static SV *generic_cursor(SV *self, SV *key, bool recursive) {
	void *hh;
	void **obj;
	struct cursorwrapper w;
	hardhat_cursor_t *c;
	STRLEN len;
	char *k;
	HV *hash;

	obj = find_magic(self, &hardhat_vtable);
	if(!obj)
		croak("Invalid hardhat object");
	w.hardhat = SvRV(self);

	hh = *obj;
	if(!hh)
		croak("Invalid hardhat object");

	k = SvPV(key, len);
	c = hardhat_cursor(hh, k, len);
	if(!c)
		croak("Can't lookup %s: %s\n", k, strerror(errno));
	w.cursor = c;
	w.recursive = recursive;
	hash = newHV();
	attach_magic((SV *)hash, &hardhat_cursor_vtable, "hardhat_cursor", &w, sizeof w);
	SvREFCNT_inc(w.hardhat);
	return sv_bless(newRV_noinc((SV *)hash), gv_stashpv("File::Hardhat::Cursor", 0));
}

static hardhat_cursor_t *generic_lookup(SV *self, SV *key) {
	void *hh;
	hardhat_cursor_t *c;
	void **obj;
	STRLEN len;
	char *k;

	obj = find_magic(self, &hardhat_vtable);
	if(!obj)
		croak("Invalid hardhat object");

	hh = *obj;
	if(!hh)
		croak("Invalid hardhat object");

	k = SvPV(key, len);
	c = hardhat_cursor(hh, k, len);
	if(!c)
		croak("Can't lookup %s: %s\n", k, strerror(errno));
	return c;
}

static SV *generic_get(SV *self, SV *key, bool limit, STRLEN max) {
	SV *res;
	hardhat_cursor_t *c;
	c = generic_lookup(self, key);
	res = c->data ? newSVpvn(c->data, limit && c->datalen > max ? max : c->datalen) : &PL_sv_undef;
	hardhat_cursor_free(c);
	return res;
}

static SV *generic_exists(SV *self, SV *key) {
	SV *res;
	hardhat_cursor_t *c;
	c = generic_lookup(self, key);
	res = c->data ? &PL_sv_yes : &PL_sv_no;
	hardhat_cursor_free(c);
	return res;
}

static SV *generic_read(hardhat_cursor_t *c, bool limit, STRLEN max) {
	return newSVpvn(c->data, limit && c->datalen > max ? max : c->datalen);
}

MODULE = File::Hardhat  PACKAGE = File::Hardhat

PROTOTYPES: ENABLE

SV *
new(char *class, const char *filename)
PREINIT:
	HV *hash;
	void *hh;
CODE:
	hh = hardhat_open(filename);
	if(!hh)
		croak("Can't open %s: %s\n", filename, strerror(errno));
	hash = newHV();
	attach_magic((SV *)hash, &hardhat_vtable, "hardhat", &hh, sizeof hh);
	RETVAL = sv_bless(newRV_noinc((SV *)hash), gv_stashpv(class, 0));
OUTPUT:
	RETVAL

SV *
exists(SV *self, SV *key)
CODE:
	RETVAL = generic_exists(self, key);
OUTPUT:
	RETVAL

SV *
get(SV *self, SV *key)
PREINIT:
	hardhat_cursor_t *c;
PPCODE:
	c = generic_lookup(self, key);
	if(!c->data) {
		hardhat_cursor_free(c);
		XSRETURN_EMPTY;
	}

	if(GIMME_V == G_ARRAY) {
		mXPUSHs(newSVpvn(c->key, c->keylen));
		mXPUSHs(generic_read(c, false, 0));
		mXPUSHs(newSVuv(c->cur));
		hardhat_cursor_free(c);
		XSRETURN(3);
	} else {
		mXPUSHs(generic_read(c, false, 0));
		hardhat_cursor_free(c);
		XSRETURN(1);
	}

SV *
getn(SV *self, SV *key, STRLEN max)
PREINIT:
	hardhat_cursor_t *c;
PPCODE:
	c = generic_lookup(self, key);
	if(!c->data) {
		hardhat_cursor_free(c);
		XSRETURN_EMPTY;
	}

	if(GIMME_V == G_ARRAY) {
		mXPUSHs(newSVpvn(c->key, c->keylen));
		mXPUSHs(generic_read(c, true, max));
		mXPUSHs(newSVuv(c->cur));
		hardhat_cursor_free(c);
		XSRETURN(3);
	} else {
		mXPUSHs(generic_read(c, true, max));
		hardhat_cursor_free(c);
		XSRETURN(1);
	}

SV *
find(SV *self, SV *key)
CODE:
	RETVAL = generic_cursor(self, key, true);
OUTPUT:
	RETVAL

SV *
ls(SV *self, SV *key)
CODE:
	RETVAL = generic_cursor(self, key, false);
OUTPUT:
	RETVAL

SV *
hardhat_normalize(SV *in)
PREINIT:
	SV *out;
	char *bytes;
	STRLEN len;
PPCODE:
	if(GIMME_V == G_VOID) {
		sv_force_normal(in);
		SvPV_force(in, len);
		bytes = SvPVX(in);
		SvCUR_set(in, hardhat_normalize(bytes, bytes, len));
		XSRETURN_EMPTY;
	} else {
		out = newSVsv(in);
		sv_force_normal(out);
		SvPV_force(out, len);
		bytes = SvPVX(out);
		SvCUR_set(out, hardhat_normalize(bytes, bytes, len));
		mXPUSHs(out);
		XSRETURN(1);
	}

MODULE = File::Hardhat  PACKAGE = File::Hardhat::Cursor

SV *
fetch(SV *self)
PREINIT:
	hardhat_cursor_t *c;
	struct cursorwrapper *w;
PPCODE:
	w = find_magic(self, &hardhat_cursor_vtable);
	if(!w)
		croak("Invalid hardhat cursor object");

	c = w->cursor;
	if(!hardhat_fetch(c, w->recursive))
		XSRETURN_EMPTY;

	if(GIMME_V == G_ARRAY) {
		mXPUSHp(c->key, c->keylen);
		mXPUSHs(generic_read(c, false, 0));
		mXPUSHu(c->cur);
		XSRETURN(3);
	} else {
		mXPUSHp(c->key, c->keylen);
		XSRETURN(1);
	}

SV *
fetchn(SV *self, STRLEN max)
PREINIT:
	hardhat_cursor_t *c;
	struct cursorwrapper *w;
PPCODE:
	w = find_magic(self, &hardhat_cursor_vtable);
	if(!w)
		croak("Invalid hardhat cursor object");

	c = w->cursor;
	if(!hardhat_fetch(c, w->recursive))
		XSRETURN_EMPTY;

	if(GIMME_V == G_ARRAY) {
		mXPUSHp(c->key, c->keylen);
		mXPUSHs(generic_read(c, true, max));
		mXPUSHu(c->cur);
		XSRETURN(3);
	} else {
		mXPUSHp(c->key, c->keylen);
		XSRETURN(1);
	}

SV *
read(SV *self)
PREINIT:
	hardhat_cursor_t *c;
	struct cursorwrapper *w;
PPCODE:
	w = find_magic(self, &hardhat_cursor_vtable);
	if(!w)
		croak("Invalid hardhat cursor object");

	c = w->cursor;
	if(!c->data)
		XSRETURN_EMPTY;

	if(GIMME_V == G_ARRAY) {
		mXPUSHp(c->key, c->keylen);
		mXPUSHs(generic_read(c, false, 0));
		mXPUSHu(c->cur);
		XSRETURN(3);
	} else {
		mXPUSHs(generic_read(c, false, 0));
		XSRETURN(1);
	}

SV *
readn(SV *self, STRLEN max)
PREINIT:
	hardhat_cursor_t *c;
	struct cursorwrapper *w;
PPCODE:
	w = find_magic(self, &hardhat_cursor_vtable);
	if(!w)
		croak("Invalid hardhat cursor object");

	c = w->cursor;
	if(!c->data)
		XSRETURN_EMPTY;

	if(GIMME_V == G_ARRAY) {
		mXPUSHp(c->key, c->keylen);
		mXPUSHs(generic_read(c, true, max));
		mXPUSHu(c->cur);
		XSRETURN(3);
	} else {
		mXPUSHs(generic_read(c, true, max));
		XSRETURN(1);
	}
