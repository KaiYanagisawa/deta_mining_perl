#!/usr/bin/perl

# 最近傍法に基づくクラス分類
# 分類ファイル（model）の作成
# このプログラムでは、学習用データの各記事を形態素解析し、
# 各記事に含まれる名詞の頻度を記録する

use strict 'vars';
use Encode;
use utf8;

# ファイル関連
use File::Find;
use File::Basename;

# 形態素解析器 MeCab を使用
use MeCab;

# MeCabを宣言（一度、宣言すればよい）
my $model = new MeCab::Model();
my $c = $model->createTagger();


main();

sub main
{
    # 訓練データの読み込み
    # ./trainディレクトリの拡張子txtのファイル一覧を得る
    my @TrainList = glob("./train/*.txt");

    my $N = @TrainList;  # 訓練データの記事数（配列@TrainListの要素数）

    foreach my $file (@TrainList)
    {
        # ファイルのクラスを取得（例：周辺機器）
        my $class = getPressClass($file);

	# fileの形態素解析を行い、
        # 名詞をキー、対応する頻度を値とするハッシュに格納
        my %TermFrequency = get_POS_data($file);
        
        # ハッシュをベクトルに変換
        # 名詞１:頻度 名詞２:頻度...
        my $vec = createVector(%TermFrequency);

        # ファイルのベース名を取得(2011-10-31_0.txt → 2011-10-31_0)
        my($bname) = split(/\./,basename($file));

        print encode_utf8("$bname\t$class\t$vec\n");
    }
}


# 機能：ハッシュをベクトルに変換
# 引数：
#  -%TermFrequency : $Hash{名詞}=頻度 のハッシュ
# 戻値：単語ベクトル（「単語:頻度 単語:頻度...」）
sub createVector
{
    my %TermFrequency = @_;

    my $vec = "";
    foreach my $term (keys %TermFrequency)
    {
        my $tf = $TermFrequency{$term};
        my $key = $term.':'.$tf;

        $vec .= $key.' ';
    }

    return $vec;
}


# 機能：$fileで指定した記事の形態素解析を行う
# 引数：
#  -$file : ファイルのフルパス
# 戻値：Hash{名詞}=頻度　
sub get_POS_data
{
    my($file) = @_;

    # 本文を取り出す
    my @Sentence = getSentence($file);

    my %POS_Hash;

    foreach my $sentence (@Sentence)
    {
        # MeCabを実行
	my $mecab_results = decode_utf8($c->parse($sentence));
	my @Str = split(/\n/,$mecab_results);

        # 例： $sentence = 「本日は晴天なり」
        # $Str[0] = 本日	名詞,副詞可能,*,*,*,*,本日,ホンジツ,ホンジツ
	# $Str[1] = は	助詞,係助詞,*,*,*,*,は,ハ,ワ
	# $Str[2] = 晴天	名詞,一般,*,*,*,*,晴天,セイテン,セイテン
	# $Str[3] = なり	助動詞,*,*,*,文語・ナリ,基本形,なり,ナリ,ナリ

        foreach my $s (@Str)
        {
            my($term,$pos_info) = split(/\t/,$s);    

            # 品詞を取得
            my($pi) = split(/,/,$pos_info);

            # 対象を（２文字以上の）名詞のみとする
	    if($pi eq "名詞" && length($term) > 1)
	    {
		$POS_Hash{$term}++;
	    }
	}
        undef @Str;
    }
    undef @Sentence;

    return %POS_Hash;
}


# 機能：$fileで指定した記事の本文を取り出す
# 引数：
#  -$file : ファイルのフルパス
# 戻値：本文を格納したリスト
sub getSentence
{
    my($file) = @_;

    my $class;

    # ファイルをオープン
    open(IN,$file);

    my @Sentence;

    while(my $line_utf8 = <IN>)
    {
	my $line = decode_utf8($line_utf8); 
	chomp($line);

	# <id>タグを解析</key>
	next if($line =~ /<id> (.+?) <\/id>/);

	# <date>タグを解析</date>
	next if($line =~ /<date> (.+?) <\/date>/);

        # <company>タグを解析</date>
	next if($line =~ /<company> (.+?) <\/company>/);

	# <title>タグを解析</title>
	next if($line =~ /<title> (.+?) <\/title>/);

        # <class>タグを解析</class>
	if($line =~ /<class> (.+?) <\/class>/)
        {
	    $class = $1;
        }

        # 先頭の全角空白を削除
	$line =~ s/^　//; 

        # 本文としては除外するもの
        next if($line =~ /^※/);
        next if($line =~ /^＊/);
        next if($line =~ /^◆/);
        next if($line =~ /^■/);
        next if($line =~ /^注/);

        next if($line eq "");

        # 文末が句点（。）であれば本文
        if($line =~ /$\。/)
        {
	   push(@Sentence,$line);
        }
    }
    close(IN);

    return @Sentence;
}


# 機能：$fileで指定した記事のクラスを返す
# 引数：
#  -$file : ファイルのフルパス
# 戻値：クラス
sub getPressClass
{
    my($file) = @_;

    open(IN,$file);

    my $class;

    while(my $data_utf8 = <IN>)
    {
        my $data = decode_utf8($data_utf8);
	chomp($data);

        if($data =~ m/<class> (.+?) <\/class>/)
        {
            my($u_class,$d_class) = split(/ /,$1);
            $class = $d_class;
        }
    }
    close(IN);
    
    return $class;
}
