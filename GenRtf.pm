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
use RTF::Writer qw(rtfesc);
use Readonly;

our $VERSION = 1.1;

Readonly::Scalar my $FALSE     => 0;
Readonly::Scalar my $TRUE      => 1;
Readonly::Scalar my $FN_PREFIX => 'BCPS';
Readonly::Scalar my $FN_SUFFIX => '.rtf';
Readonly::Scalar my $YEAR_BASE => 1900;
Readonly::Scalar my $MID       => 0;
Readonly::Scalar my $LNAME     => 1;
Readonly::Scalar my $FNAMES    => 2;
Readonly::Scalar my $ADDR1     => 3;
Readonly::Scalar my $ADDR2     => 4;
Readonly::Scalar my $ADDR3     => 5;
Readonly::Scalar my $ADDR4     => 6;
Readonly::Scalar my $ADDR5     => 7;
Readonly::Scalar my $ADDR6     => 8;
Readonly::Scalar my $ADDR7     => 9;
Readonly::Scalar my $EMAIL     => 10;
Readonly::Scalar my $OPTIONS   => 11;
Readonly::Scalar my $CLASS     => 12;
Readonly::Scalar my $CREDIT    => 13;
Readonly::Scalar my $M_SQL =>
  'select mid, lname, fnames, addr1, addr2, addr3, addr4, addr5, addr6, addr7, email, '
  . 'options, class, credit from members '
  . 'where (class != \'contributor\') and (active = 1) '
  . 'order by lname, fnames';
Readonly::Scalar my $C_SQL =>
  'select mid, lname, fnames, addr1, addr2, addr3, addr4, addr5, addr6, addr7, email, '
  . 'options, class, credit from members '
  . 'where (class = \'contributor\') '
  . 'order by lname, fnames';

my @records;
my $fname;
my $rtf;

sub gen_rtf {
    my ( $member, $contrib, $debug, $dbh ) = @_;
    my $rv;

    ( $debug == $TRUE ) && ( $rv = say 'GenRtf::gen_rtf()' );

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime time;
    $fname = sprintf '%s_%4d_%02d_%02d%s', $FN_PREFIX, $year + $YEAR_BASE, $mon + 1, $mday, $FN_SUFFIX;
    ( $debug == $TRUE ) && ( $rv = say "$fname" );

    write_header( $member, $contrib, $debug );
    collect_data( $member, $contrib, $debug, $dbh );

    write_data( $debug, $dbh, $member );
    write_footer( $member, $contrib, $debug );

    return;
}

sub write_header {
    my ( $member, $contrib, $debug ) = @_;
    my $title = sprintf 'BCPS: List Of %s', ( $member == $TRUE ) ? 'Active Subscribers' : 'Contributors';
    my $rv;

    ( $debug == $TRUE ) && ( $rv = say 'GenRtf::write_header()' );

    $rtf = RTF::Writer->new_to_file($fname);
    $rtf->prolog(
        'title' => $title,
        'fonts' => 'Courier new',
        'deff'  => 0
    );

    $rtf->print( \'\margl900 \margr900 \margt900 \margb900 \cols2 \linebetcol' );

    $rtf->printf( \'{\header \pard\ql\fs24\f0 %s - page \chpgn \par}', $title );

    return;
}

sub write_data {
    my ( $debug, $dbh, $member ) = @_;
    my $rv;

    ( $debug == $TRUE ) && ( $rv = say 'GenRtf::write_data()' );

    foreach my $r_hash (@records) {
        my $address;
        my $email;
        my $foren;
        my $credit;
        my $mid   = sprintf "    MID: %4d\n", $r_hash->{MID};
        my $lname = sprintf "  LNAME: %s\n",  $r_hash->{LNAME};

        if ( defined $r_hash->{FNAMES} ) {
            $foren = sprintf " FNAMES: %s\n", $r_hash->{FNAMES};
        }
        else {
            $foren = sprintf " FNAMES:\n";
        }

        if ( defined $r_hash->{ADDR1} ) {
            my $addr  = q{};
            my @lines = (
                $r_hash->{ADDR1}, $r_hash->{ADDR2}, $r_hash->{ADDR3}, $r_hash->{ADDR4},
                $r_hash->{ADDR5}, $r_hash->{ADDR6}, $r_hash->{ADDR7},
            );

          ADDR_LOOP:
            foreach my $line (@lines) {
                ( !defined $line ) && ( last ADDR_LOOP );
                $addr .= ( $line . ', ' );
            }

            chop $addr;
            chop $addr;

            #$addr =~ s/^ //xms;
            $addr =~ s/\s\s/ /gxms;

            $address = sprintf "ADDRESS: %s\n", $addr;
        }
        else {
            $address = "ADDRESS:\n";
        }

        if ( defined $r_hash->{EMAIL} ) {
            $email = sprintf "  EMAIL: %s\n", $r_hash->{EMAIL};
        }
        else {
            $email = "  EMAIL:\n";
        }

        my $options = sprintf "OPTIONS: %s\n", $r_hash->{OPTIONS};
        my $class   = sprintf "  CLASS: %s\n", $r_hash->{CLASS};

        if ( $member == $TRUE ) {
            if ( defined $r_hash->{CREDIT} ) {
                $credit = sprintf " CREDIT: %s\n", $r_hash->{CREDIT};
            }
            else {
                $credit = " CREDIT:\n";
            }

            $rtf->paragraph( \'\sa10\fs16\f0\keep',
                $mid, $lname, $foren, $email, $address, $options, $class, $credit );
        }
        else {
            $rtf->paragraph( \'\sa10\fs16\f0\keep',
                $mid, $lname, $foren, $email, $address, $options, $class );
        }
    }

    return;
}

sub write_footer {
    my ( $member, $contrib, $debug ) = @_;
    my $rv;

    ( $debug == $TRUE ) && ( $rv = say 'GenRtf::write_footer()' );
    $rtf->close();

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
        $r_hash->{FNAMES}  = $r_row->[$FNAMES];
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
