package GenRtf;

#	GenRtf.pm
#	(c) 2020, B D Stephenson
#	(for British Chess Problem Society)
#	bds@bstephen.me.uk

#	This package the routines to generate rtf lists of active members or contributors from the
#	BCPS subscriber database.

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
use Readonly;

our $VERSION = 1.1;

Readonly::Scalar my $FALSE   => 0;
Readonly::Scalar my $TRUE    => 1;
Readonly::Scalar my $MID     => 0;
Readonly::Scalar my $LNAME   => 1;
Readonly::Scalar my $FNAMES  => 2;
Readonly::Scalar my $ADDR1   => 3;
Readonly::Scalar my $ADDR2   => 4;
Readonly::Scalar my $ADDR3   => 5;
Readonly::Scalar my $ADDR4   => 6;
Readonly::Scalar my $ADDR5   => 7;
Readonly::Scalar my $ADDR6   => 8;
Readonly::Scalar my $ADDR7   => 9;
Readonly::Scalar my $EMAIL   => 10;
Readonly::Scalar my $OPTIONS => 11;
Readonly::Scalar my $CLASS   => 12;
Readonly::Scalar my $CREDIT  => 13;
Readonly::Scalar my $M_SQL =>
  'select mid, lname, fnames, addr1, addr2, addr3, addr4, addr5, addr6, addr7, email '
  . 'options, class, credit from members '
  . 'where (class != \'contributor\') and (active = 1) '
  . 'order by lname, fnames';
Readonly::Scalar my $C_SQL =>
  'select mid, lname, fnames, addr1, addr2, addr3, addr4, addr5, addr6, addr7, email '
  . 'options, class, credit from members '
  . 'where (class = \'contributor\') '
  . 'order by lname, fnames';

my @records;

sub gen_rtf {
    my ( $member, $contrib, $debug, $dbh ) = @_;
    my $rv;

    ( $debug == $TRUE ) && ( $rv = say 'GenRtf::gen_rtf()' );

    collect_data( $member, $contrib, $debug, $dbh );

    return;
}

sub collect_data {
    my ( $member, $contrib, $debug, $dbh ) = @_;
    my $rv;
    my $r_row;
    my $sth;
    my $sql = ( $member == $TRUE ) ? $M_SQL : $C_SQL;

    ( $debug == $TRUE ) && ( $rv = say 'GenRtf::collect_data()' );

    $sth = $dbh->prepare($sql);
    $sth->execute();

    while ( $r_row = $sth->fetchrow_arrayref ) {
        my $r_hash = {};
        $r_hash->{MID}     = $r_row->[$MID];
        $r_hash->{LNAME}   = $r_row->[$LNAME];
        $r_hash->{FNAMES}  = $r_row->[$LNAME];
        $r_hash->{ADDR1}   = $r_row->[$ADDR1];
        $r_hash->{ADDR2}   = $r_row->[$ADDR2];
        $r_hash->{ADDR3}   = $r_row->[$ADDR3];
        $r_hash->{ADDR4}   = $r_row->[$ADDR4];
        $r_hash->{ADDR5}   = $r_row->[$ADDR5];
        $r_hash->{ADDR6}   = $r_row->[$ADDR6];
        $r_hash->{ADDR7}   = $r_row->[$ADDR7];
        $r_hash->{EMAIL}   = $r_row->[$EMAIL];
        $r_hash->{OPTIONS} = $r_row->[$OPTIONS];
        $r_hash->{CLASS}   = $r_row->[$CLASS];
        $r_hash->{CREDIT}  = $r_row->[$CREDIT];

        push @records, $r_hash;
    }

    $sth->finish();

    return;
}

1;
