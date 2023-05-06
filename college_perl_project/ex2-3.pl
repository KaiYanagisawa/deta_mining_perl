#!/usr/bin/perl

use strict;
use Encode;
use utf8;

main();

sub main
{
    my $s_code = $ARGV[0];

    # test.list のデータをハッシュに格納する関数
    my %DataHash = mkDataHash("test.list");
    my $f_name = $DataHash{$s_code};
    print "$s_code -> $f_name\n";
}

sub mkDataHash
{
    my $input_file = $_[0];
    my %data_hash;
    open (my $IN, $input_file);
    my $line = <$IN>;
    print encode_utf8("$line $input_file");

    while(my $line = <$IN>)
    {
        print encode_utf8("111");
        my $str = decode_utf8($line);
        chomp($str);
        print encode_utf8("$str\n");
        my @cord_file_name = split(/,/, $str);
        $data_hash{$cord_file_name[1]} = $cord_file_name[0];
        print encode_utf8("$cord_file_name[0], $cord_file_name[1]");
    }
    close ($IN);

    return %data_hash;
}