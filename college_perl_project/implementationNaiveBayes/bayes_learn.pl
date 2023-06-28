#!/usr/bin/perl

use strict;
use Encode;
use utf8;


main();

sub main
{
    my $train_file = "/Users/yanagisawakai/college2023_1/data_mining/college_perl_project/implementationNaiveBayes/train.list";
    createModelFile($train_file);
}

sub createModelFile
{
    my $train_file = @_;

    open(my $IN, $train_file);

    my $data_utf8 = <IN>;
    chomp($data_utf8);
    my @Tag = split(/,/, decode_utf8($data_utf8));

    my @TrainData;

    while (my $data_utf8 = <IN>)
}