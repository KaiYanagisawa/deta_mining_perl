#!/usr/bin/perl

use strict;
use Encode;
use utf8;

main();

sub main
{
    my @text;
    $text[0] = "Peter Piper picked a peck of pickled peppers";
    $text[1] = "A peck of pickled peppers Peter Piper picked";
    $text[2] = "If Peter Piper picked a peck of pickled peppers";
    $text[3] = "Where is the peck of pickled peppers Peter Piper picked";
    # 以降を実装せよ 

    my $search_word_count = 0;
    my $all_word_count = 0;
    my $search_word = decode_utf8($ARGV[0]);

    for(my $i = 0; $i <= $#text; $i++){
        my @word_list = split(/ /, $text[$i]);
        for(my $i = 0; $i <= $#word_list; $i++){
            $all_word_count++;
            if($word_list[$i] eq $search_word){
                $search_word_count++;
            }
        }
    }

    my $appearance_probability = $search_word_count / $all_word_count;
    print encode_utf8("$appearance_probability ($search_word_count / $all_word_count)\n");
}