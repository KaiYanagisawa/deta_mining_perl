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

sub merge_list
{
    
}