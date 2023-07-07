#!/usr/bin/perl

use strict;
use Encode;
use utf8;

# 形態素解析器 MeCab
use MeCab;

# MeCabを宣言（一度、宣言すればよい）
my $model = new MeCab::Model();
my $c = $model->createTagger();

main();

sub main()
{
    my $string_utf8 = $ARGV[0];

    # MeCabを実行（出力はUTF-8なので、Perlの内部コードに変換する必要有り）
    my $mecab_results = decode_utf8($c->parse($string_utf8));

    # print encode_utf8("$mecab_results");
    my @POS = split(/\n/,$mecab_results);

    foreach my $result (@POS)
    {
        my @data = ;
        my @pos = ;
        
        if ()
        {
            print encode_utf8("$result \n");
        }
    }
}
