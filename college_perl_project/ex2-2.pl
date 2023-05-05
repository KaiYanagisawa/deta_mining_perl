#!/usr/bin/perl

use strict;
use Encode;
use utf8;

main();

sub main
{
    my @list1 = ("赤","青","黄","紫","緑","黒");
    my @list2 = ("白","黒","青","紫","橙","赤");
    my @list3 = marge_list(\@list1,\@list2);

    foreach my $color (@list3)
    {
        print encode_utf8("$color\n");
    }
    undef @list3;
}

sub marge_list
{
    my $list1 = $_[0];
    my $list2 = $_[1];
    my @list1_ref = @{$list1};
    my @list2_ref = @{$list2};

    my %hash;
    for (my $i = 0; $i <= $#list1_ref; $i++)
    {
        $hash{$list1_ref[$i]} = $i;
    }

    my @list3;
    foreach my $elem (@list2_ref) 
    {
        if (exists $hash{$elem})
        {
            push @list3, $elem;
        }
    }
    undef %hash;

    return @list3;
}