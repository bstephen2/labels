#!/usr/bin/perl
#	labels.pl
#	(c) 2020, B D Stephenson
#	(for British Chess Problem Society)
#	bds@bstephen.me.uk

#	This script generates rtf lists of active members or contributors from the
#	BCPS subscriber database.

#	USAGE:
#		"labels.pl --member [--debug] " OR
#		"labels.pl --contrib [--debug]"

#	Except as otherwise stated, this Perl script meets the default standards
#	set by 'Perl Best Practices' by Damian Conway (O'Reilly). It has been
#	tested by Perl::Critic and has passed with no violations.

#	VERSION HISTORY
#
#	1.1	2015/06/25	Initial Release

use warnings;
use English '-no_match_vars';
use strict;
use feature qw(switch say);
use Getopt::Long;
use DBI;
use Readonly;
use GenRtf;

our $VERSION = 1.1;

Readonly::Scalar my $PROG   => 'labels.pl';
Readonly::Scalar my $AUTHOR => 'Brian Stephenson';
Readonly::Scalar my $EMAIL  => 'brian@bstephen.me.uk';
Readonly::Scalar my $YEARS  => '2020';
Readonly::Scalar my $FALSE  => 0;
Readonly::Scalar my $TRUE   => 1;

my $server   = 'localhost';
my $db       = 'bcpsmembers';
my $user     = 'bstephen';
my $password = 'rice37';
my $debug    = $FALSE;
my $member   = $FALSE;
my $contrib  = $FALSE;
my $togo;
my $dbh;

GetOptions( 'member' => \$member, 'contrib' => \$contrib, 'debug' => \$debug );

$togo = check_args();

if ( $togo == $TRUE ) {
    connect_to_db();
    GenRtf::gen_rtf( $member, $contrib, $debug, $dbh );
    disconnect_from_db();
}
else {
    display_usage();
}

exit 0;

sub check_args {
    my $rv;

    ( $debug == $TRUE ) && ( $rv = say 'main::check_args()' );
    ( ( $member == $FALSE ) && ( $contrib == $FALSE ) ) && ( return $FALSE );
    ( ( $member == $TRUE )  && ( $contrib == $TRUE ) )  && ( return $FALSE );

    return $TRUE;
}

sub display_usage {
    my $rv;

    $rv = say 'USAGE:';
    $rv = say "\t\'labels.pl --member [--debug]\' OR";
    $rv = say "\t\'labels.pl --contrib [--debug]\'";

    return;
}

sub connect_to_db {
    my $rv;

    ( $debug == $TRUE ) && ( $rv = say 'main::connect_to_db()' );

    $dbh = DBI->connect( "dbi:mysql:$db:$server", $user, $password );
    ( defined $dbh ) || die "Can't connect to bcps database\n";

    return;
}

sub disconnect_from_db {
    my $rv;

    ( $debug == $TRUE ) && ( $rv = say 'main::disconnect_from_db()' );

    $dbh->disconnect();

    return;
}

