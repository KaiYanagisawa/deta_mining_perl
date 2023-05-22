#!/usr/bin/perl

use strict;
use Encode;
use utf8;

main();

sub main
{
    my $fo = $ARGV[0];
    my $fx = $ARGV[1];

    my $Po = $fo / ($fo + $fx);
    my $Px = $fx / ($fo + $fx);
    
    my $lo = - $Po * log($Po) / log(2);
    my $lx = - $Px * log($Px) / log(2);
    my $H = $lo + $lx;

    print "H = $H\n";

    my $a = $H - 0.5;
    my $b = $H - 0.951;
    my $c = $H - 0.607;
    print " 煙の色 = $a, プラント圧力 = $b, 銅の色 = $c\n";
}