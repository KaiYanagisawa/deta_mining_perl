#!/usr/bin/perl

use strict;
use utf8;
use Encode;

main();

sub main 
{
    my @list1 = ("赤","青","黄","紫","緑","黒");
    my @list2 = ("白","黒","青","紫","橙","赤");

    my %hash;
    for (my $i = 0; $i <= $#list1; $i++)
    {
        $hash{$list1[$i]} = $i;
    }

    my @list3;
    foreach my $elem (@list2) 
    {
        if (exists $hash{$elem})
        {
            push @list3, $elem;
        }
    }
    undef %hash;

    foreach my $color (@list3)
    {
        print encode_utf8("$color\n");
    }
    undef @list3;

}