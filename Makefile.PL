# Makefile.PL -- Makefile template for AtExit.
#
# Copyright (C) 1996 Andrew Langmead. All rights reserved.
# This file is part of "AtExit". AtExit is free software;
# you can redistribute it and/or modify it under the same
# terms as Perl itself.
#

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "AtExit",
    DISTNAME     => "AtExit",
    VERSION_FROM => "AtExit.pm",
    SKIP         => [qw(static dynamic)],
    linkext      => {LINKTYPE => ''},
    INSTALLDIRS  => 'perl',
);
