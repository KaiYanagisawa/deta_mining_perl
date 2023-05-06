#!/usr/bin/perl

use strict;
use Encode;
use utf8;

main();

sub main
{
    my $file_name = $ARGV[0];

    # ファイルのオープン。IN はファイルハンドル
    open(my $IN,$file_name);
    
    # ファイルを１行ずつ読み込み（ファイルはUTF-8コードという想定）
    while(my $line = <$IN>)  
    {
        my $str = decode_utf8($line); # Perl内部コードに変換
        chomp($str);   # 改行コードを削除
        print encode_utf8("$str\n");
    }
    close($IN);
}

