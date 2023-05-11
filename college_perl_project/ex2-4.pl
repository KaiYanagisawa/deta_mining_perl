#!/usr/bin/perl

use strict;
use Encode;
use utf8;

main();

sub main
{
    my $input_file = "/Users/yanagisawakai/college2023_1/data_mining/college_perl_project/test.csv";
    my %DataHash = mkDataHash($input_file);

    foreach my $tag (keys %DataHash)
    {
        foreach my $data (keys %{$DataHash{$tag}})
        {
            foreach my $det (keys %{$DataHash{$tag}{$data}})
            {
                my $td = $DataHash{$tag}->{$data}->{$det};
                print encode_utf8("$tag -> $data -> $det = $td\n");
            }
        }
    }
}

sub mkDataHash
{
    my $input_file = $_[0];
    open(my $IN, $input_file) or die "cannot open $input_file\n";

    my %TrainData;
    my @tag_list;
    my $zero_line = 1;
    while (my $line = <$IN>)
    {
        chomp($line);
        my $str =  decode_utf8($line);
        my @file_line = split(/\t/, $str);

        if ($zero_line)
        {
            for (my $i = 0; $i <= $#file_line; $i++)
            {
                $tag_list[$i] = $file_line[$i];
            }
            $zero_line = 0;
        }
        else
        {
            my $golf_play = pop(@file_line);
            for (my $i = 0; $i < $#tag_list; $i++)
            {
                my $tag = $tag_list[$i];
                my $data = $file_line[$i];

                $TrainData{$tag}->{$data}->{$golf_play}++;
            }
        }
    }

    return %TrainData;    
}