#!/usr/bin/perl

use strict;
use Encode;
use utf8;

main();  # main関数の実行（# 以降の一文はコメント）

sub main(){
    my $input = decode_utf8($ARGV[0]);
    my $search_word = decode_utf8($ARGV[1]);

    if($input =~ $search_word){
        print($search_word."is contained in ".$input."\n");
    }else{
        print($search_word."is not contained in ".$input."\n");
    }
}