#############################################################################
# test.pl -- simple testing script for AtExit.pm
#
# Copyright (c) 1996 Andrew Langmead. All rights reserved.
# This file is part of "AtExit". AtExit is free software;
# you can redistribute it and/or modify it under the same
# terms as Perl itself.
#############################################################################

use strict;
use diagnostics;
use AtExit;
#require AtExit; *atexit = *AtExit::atexit; *rmexit = *AtExit::rmexit;
 
sub cleanup {
    my @args = @_;
    print "cleanup() executing: args = @args\n";
}

sub weird {
    my @args = @_;
    print "weird() executing: args = @args\n";
    local $_;
    print "\tcalling atexit() during exit processing:\n";
    $_ = atexit(\&cleanup, "This call was registered during exit processing");
    print "\tatexit() returned " . (defined $_ ? $_ : "`undef'") . "\n";
}

#$AtExit::IGNORE_WHEN_EXITING = 0;
$_ = atexit(\&cleanup, "This call was registered first");
print "first call to atexit() returned $_\n";

$_ = atexit('cleanup', "This call was registered second");
print "second call to atexit() returned $_\n";

$_ = atexit(\&weird, "This call was registered third");
print "third call to atexit() returned $_\n";

$_ = atexit("cleanup", "This call should have been unregistered by rmexit");
rmexit($_)  ||  warn "couldnt unregister exit-sub!";

END {
    print "*** Now performing program-exit processing ***\n";
}

