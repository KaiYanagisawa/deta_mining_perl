#!/usr/bin/perl

use strict;
use Encode;
use utf8;

main();

sub main
{
   my @list = (12,68,24,38,55,11,50,65,74,95,80,89,78);
   my @slist = sort_list(@list);  # この関数を実装せよ。
   foreach my $s (@slist)
   {
	    print "$s\n";
   }
}

sub sort_list
{
    my @list = @_;   # 引数として指定した配列を @list にコピー
    my $max = 0;
    for(my $i = 0; $i <= $#list - 1; $i++){
        for(my $j = $i; $j <= $#list; $j++){
            if($list[$i] >= $list[$j]){
                my $tmp = $list[$i];
                $list[$i] = $list[$j];
                $list[$j] = $tmp;
            }
        }
    }
    return @list;
}