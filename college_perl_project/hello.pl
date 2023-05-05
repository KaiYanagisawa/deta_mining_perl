use strict;
use Encode;
use utf8;

main();  # main関数の実行（# 以降の一文はコメント）

sub main
{
    print encode_utf8("hello world\n");
}