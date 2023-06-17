#!/usr/bin/perl

use strict;
use utf8;
use Encode;

main();

sub calc_cosin 
{
    my ($ref_HashX, $ref_HashY) = @_;
    my %HashX = %{$ref_HashX};
    my %HashY = %{$ref_HashY};
    my %Hash;

    # ノルムXを計算(分母)
    my $X;
    foreach my $term (keys %HashX)
    {
        my $rfidf = $HashX{$term};
        $X += $rfidf;
        $Hash{$term} = 1;
    }

    # ノルムYを計算(分母)
    my $Y;
    foreach my $term (keys %HashY)
    {
        my $rfidf = $HashY{$term};
        $Y += $rfidf;
        $Hash{$term}++;
    }

    # 内積を計算(分子)
    my $P;
    foreach my $term (keys %Hash)
    {
        if($Hash{$term} == 2)
        {
            my $tfidf_x = $HashX{$term};
            my $tfidf_y = $HashY{$term};
            $P += $tfidf_x * $tfidf_y;
        }
    }

    my $cos = $P / sqrt($X) / sqrt($Y);
    return $cos;
}

sub main
{
    my %hashX = (1 => 0, 2 => 0, 3 => 1, 4 => 1, 5 => 0, 6 => 1, 7 => 0, 8 => 1, 9 => 1, 10 => 0);
    my %hashY = (1 => 1, 2 => 0, 3 => 1, 4 => 0, 5 => 0, 6 => 1, 7 => 0, 8 => 1, 9 => 1, 10 => 0);
    print encode_utf8(calc_cosin(\%hashX, \%hashY));
}