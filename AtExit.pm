##############################################################################
# AtExit.pm -- a Perl5 module to provide C-style atexit() processing
#
# Copyright (c) 1996 Andrew Langmead. All rights reserved.
# This file is part of "AtExit". AtExit is free software;
# you can redistribute it and/or modify it under the same
# terms as Perl itself.
##############################################################################

package AtExit;

require 5.002;
$VERSION = 1.02;

=head1 NAME

atexit -- Register a subroutine to be invoked at program-exit time.

rmexit -- Unregister a subroutine that was registered with atexit.

=head1 SYNOPSIS

 use AtExit;
 
 sub cleanup {
     my @args = @_;
     print "cleanup() executing: args = @args\n";
 }
 
 $_ = atexit(\&cleanup, "This call was registered first");
 print "first call to atexit() returned $_\n";

 $_ = atexit("cleanup", "This call was registered second");
 print "second call to atexit() returned $_\n";

 $_ = atexit("cleanup", "This call should've been unregistered by rmexit");
 rmexit($_)  ||  warn "couldnt' unregister exit-sub $_!";

 END {
     print "*** Now performing program-exit processing ***\n";
 }

=head1 DESCRIPTION

The B<AtExit> module provides ANSI-C style exit processing modeled after
the C<atexit()> function in the standard C library (see L<atexit(3C)>).
Various exit processing routines may be registered by calling
C<atexit()> and passing it the desired subroutine along with any
desired arguments. Then, at program-exit time, the subroutines registered
with C<atexit()> are invoked with their given arguments in the
I<reverse> order of registration (last one registered is invoked first).
Registering the same subroutine more than once will cause that subroutine
to be invoked once for each registration.

The C<atexit()> function exported by B<AtExit> should be passed a
subroutine name or reference, optionally followed by the list of
arguments with which to invoke it at program-exit time.  Anonymous
subroutine references passed to C<atexit()> act as "closures" (which are
described in L<perlref>).  If a subroutine I<name> is specified (as
opposed to a subroutine reference) then, unless the subroutine name has
an explicit package prefix, it is assumed to be the name of a subroutine
in the caller's current package.  A reference to the specified
subroutine is obtained, and, if invocation arguments were specified, it
is "wrapped up" in a closure which invokes the subroutine with the
specified arguments.  The resulting subroutine reference is prepended to
the front of the C<@AtExit::EXIT_SUBS> list of exit-handling subroutines
and the reference is then returned to the caller (just in case you might
want to unregister it later using C<rmexit()>). If the given subroutine could
I<not> be registered, then the value zero is returned.

The C<rmexit()> function exported by B<AtExit> should be passed one or
more subroutine references, each of which was returned by a previous
call to C<atexit()>. For each argument given, C<rmexit()> will look for
it in the C<@AtExit::EXIT_SUBS> list of exit-handling subroutines and
remove the first such match from the list. The value returned will be
the number of subroutines that were successfully unregistered.

At program-exit time, the C<END{}> block in the B<AtExit> module
iterates over the subroutine references in the C<@AtExit::EXIT_SUBS>
array and invokes each one in turn (each subroutine is removed from the
front of the queue immediately before it is invoked).  Note that the
subroutines in this queue are invoked in first-to-last order (the
I<reverse> order in which they were registered with C<atexit()>).

=head2 Invoking C<atexit()> and C<rmexit()> during program-exit

The variable C<$AtExit::IGNORE_WHEN_EXITING> specifies how calls to
C<atexit()> will be handled if they occur during the time that
subroutines registered with C<atexit()> are being invoked.  By default,
this variable is set to a non-zero value, which causes C<atexit()> to
I<ignore> any calls made to it during this time (a value of zero
will be returned). This behavior is consistent with that of the standard
C library function of the same name. If desired however, the user may
enable the registration of subroutines by C<atexit()> during this time
by setting C<$AtExit::IGNORE_WHEN_EXITING> to zero or to the empty
string. Just remember that any subroutines registered with C<atexit()>
during program-exit time will be placed at the I<front> of the queue of
yet-to-be-invoked exit-processing subroutines.

Regardless of when it is invoked, C<rmexit()> will I<always> attempt to
unregister the given subroutines (even when called during program-exit
processing). Keep in mind however that if it is invoked during program-exit
processing then it will I<fail> to unregister any exit-processing
subroutines that have I<already been invoked> by the C<END{}> block in
the B<AtExit> module (since those subroutine calls have already been
removed from the C<@AtExit::EXIT_SUBS> list).

The variable C<$AtExit::EXITING> may be examined to determine if
routines registered using C<atexit()> are currently in the process of
being invoked. It will be non-zero if they are and zero otherwise.

=head1 NOTES

The usual Perl way of doing exit processing is through the use of
C<END{}> blocks (see L<perlmod/"Package Constructors and Destructors">).
The B<AtExit> module implements its exit processing with an C<END{}>
block that invokes all the subroutines registered by C<atexit()> in the
array C<@AtExit::EXIT_SUBS>.  If any other C<END{}> block processing is
specified in the user's code or in any other packages it uses, then the
order in which the exit processing takes place is subject to Perl's
rules for the order in which C<END{}> blocks are processed. This may
affect when subroutines registered with C<atexit()> are invoked with
respect to other exit processing that is to be performed. In particular,
if C<atexit()> is invoked from within an C<END{}> block that executes
I<after> the C<END{}> block in the B<AtExit> module, then the corresponding
subroutine that was registered will never be invoked by the B<AtExit>
module's exit-processing code.

=head2 C<END{}> block processing order

C<END{}> blocks, including those in other packages, get called in the
reverse order in which they appear in the code. (C<atexit()> subroutines
get called in the reverse order in which they are registered.) If a
package gets read via "use", it will act as if the C<END{}> block was
defined at that particular part of the "main" code.  Packages read via
"require" will be executed after the code of "main" has been parsed and
will be seen last so will execute first (they get executed in the
context of the package in which they exist).

It is important to note that C<END{}> blocks only get called on normal
termination (which includes calls to C<die()> or C<Carp::croak()>). They
do I<not> get called when the program terminates I<abnormally> (due to a
signal for example) unless special arrangements have been made by the
programmer (e.g. using a signal handler -- see L<perlvar/"%SIG{expr}">).

=head1 SEE ALSO

L<atexit(3C)> describes the C<atexit()> function for the standard C
library (the actual Unix manual section in which it appears may differ
from platform to platform - try sections 3C, 3, 2C, and 2).  Further
information on anonymous subroutines ("closures") may be found in
L<perlref>.  For more information on C<END{}> blocks, see
L<perlmod/"Package Constructors and Destructors">.  See
L<perlvar/"%SIG{expr}"> for handling abnormal program termination.

=head1 AUTHOR

Andrew Langmead E<lt>aml@world.std.comE<gt> (initial draft).

Brad Appleton E<lt>Brad_Appleton-GBDA001@email.mot.comE<gt> (final version).

=cut

use vars qw($VERSION @ISA @EXPORT @EXIT_SUBS $EXITING $IGNORE_WHEN_EXITING);
use strict;
#use diagnostics;
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(atexit rmexit);

@EXIT_SUBS = ();
$EXITING = 0;
$IGNORE_WHEN_EXITING = 1;

sub version {
    return  $VERSION;
}

sub atexit {
    return  0  if ($EXITING  &&  $IGNORE_WHEN_EXITING);
    my $exit_sub = shift;
    my @args = @_;
    local($_);
    unless (ref $exit_sub) {
       ## Caller gave us a sub name instead of a sub reference.
       ## Need to make sure we have the callers package prefix
       ## prepended if one wasnt given.
       my $pkg = '';
       $pkg = (caller)[0] . "::"  unless $exit_sub =~ /::/o;
       ## Now turn the sub name into a hard sub reference.
       $exit_sub = eval "\\&$pkg$exit_sub";
       undef $exit_sub  if ($@);
    }
    return  0  unless (defined $exit_sub) && (ref($exit_sub) eq 'CODE');
    ## If arguments were given, wrap the invocation up in a closure
    $_ = (@args > 0) ? sub { &$exit_sub(@args); } : $exit_sub;
    ## Now put this sub-ref on the queue
    unshift(@EXIT_SUBS, $_);
    ## Return what we just registered
    return  $_;
}

sub rmexit {
    my @subrefs = @_;
    my ($unregistered, $i) = (0, 0);
    local $_;
    ## Unregister each sub in the give list.
    ##   [ I suppose I could come up with a faster way to do this than
    ##     doing a separate iteration for each argument, but I wont
    ##     worry about that just yet. ]
    ##
    for (@subrefs) {
        next  0  unless (ref($_) eq 'CODE');
        ## Iterate over the queue and remove the first match
        for ($i = 0; $i <= $#EXIT_SUBS; ++$i) {
            if ($_ == $EXIT_SUBS[$i]) {
                splice(@EXIT_SUBS, $i, 1);
                ++$unregistered;
                last;
            }
        }
    }
    return  $unregistered;
}

sub do_atexit {
    $EXITING = 1;
    my $exit_sub;
    ## Handle atexit() stuff in reverse order of registration
    while (@EXIT_SUBS > 0) {
        $exit_sub = shift(@EXIT_SUBS);
        &$exit_sub();
    }
    $EXITING = 0;
}

END {
    &do_atexit;
}

1;
