#!/usr/bin/perl

use strict;
use Encode;
use utf8;

main();

sub main
{
    my $s_code = $ARGV[0];

    # test.list のデータをハッシュに格納する関数 (M1Mac環境上では絶対パスでの指定でないとopen関数が指定ファイルを認識しない)
    my %DataHash = mkDataHash("/Users/yanagisawakai/college2023_1/data_mining/college_perl_project/test.list");
    my $f_name = $DataHash{$s_code};
    print "$s_code -> $f_name\n";
}

sub mkDataHash
{
    my $input_file = $_[0];
    my %data_hash;
    open (my $IN, $input_file) or die "cannot open $input_file \n";

    while(my $line = <$IN>)
    {
        chomp($line);
        my $str = decode_utf8($line);
        my @cord_file_name = split(/,/, $str);
        $data_hash{$cord_file_name[0]} = $cord_file_name[1];
    }
    close ($IN);

    return %data_hash;
}