#!/usr/bin/perl

# k-means法によるクラスタリング

use strict;
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

# 高速化のため、一度、計算した類似度を記録
my %SimilarityHash;

# データの読み込み
my @TextList = glob("./data/*.txt");

# テキストファイルの総数
my $N = @TextList;

# データのテキストファイルを形態素解析し、ベクトル化して格納
my %VectorHash = createVectorHash(@TextList);

# 文書頻度の取得
my %DocumentFrequency = createDocumentFrequency(%VectorHash);

main();


sub main
{
    # クラスタ数の指定
    my $claster_size = 20;

    # データの読み込み
    my @TextList = glob("./data/*.txt");

    # initial.listを読み込んで、初期クラスタを得る              
    # $ClasterHash{group5} =  2012-01-16_0 2011-12-12_0 2012-05-02_0 ...
    my %ClasterHash = getInitializeClaster();
    
    # 初期クラスタを得る
    # 単純にファイルリストの最初から、指定クラスタ数に均等に配分
    # $ClasterHash{group5} =  2012-01-16_0 2011-12-12_0 2012-05-02_0 ...
    # my %ClasterHash =  getInitializeClasterNaive($claster_size,\@TextList);
    

    # 収束するまでループ(念のため1000回で終了)
    for(my $loop=1; $loop<=1000; $loop++)
    {
	my %BestDist;
	my %BestCraster;

	foreach my $g_name (keys %ClasterHash)
	{
	    #  クラスタ $g_name の平均ベクトル＝代表ベクトルを得る
	    my @g_list = split(/ /,$ClasterHash{$g_name});
	    my %vec_mean = getVectorMean(@g_list);
	    

	    # 各事例データと代表ベクトルとの距離を計算し、
	    # 各事例ごとに最も近い距離のクラスタ（$g_name）を格納
	    foreach my $b_name (keys %VectorHash)
	    {    
		# ベクトル文字列をTF・IDFハッシュに変換
		# キー：名詞　値：TF・IDF値
		my $vector = $VectorHash{$b_name};
		my %vec = VectorStr_toHash($vector);

		# 平均ベクトル＝代表ベクトルとの距離を計算
		my $cosin = calc_cosin(\%vec,\%vec_mean);

		# 各事例ごとに最も近い距離のクラスタ（$g_name）を格納
		if($BestDist{$b_name} < $cosin)
		{
		    $BestDist{$b_name} = $cosin;
		    $BestCraster{$b_name} = $g_name;
		}
	    }
	}
	
	# クラスタを再構築
	my %NewClasterHash;
	foreach my $b_name (keys %VectorHash)
	{
	    my $g_name = $BestCraster{$b_name};
	    $NewClasterHash{$g_name} .= $b_name." ";

	    my $c_list = $NewClasterHash{$g_name};
	    print "$g_name -> $c_list\n";
	}

	print encode_utf8("\nクラスタを再構築\n");
	print encode_utf8("ループ　$loop 回目 終了\n");

	# 不要なハッシュを開放
	undef %BestDist;
	undef %BestCraster;

	# 再構築したクラスタと、前のクラスタが同じか？
	my $eva = evaluateClater(\%ClasterHash,\%NewClasterHash);
	if($eva == 1)
	{
	    # 同じであれば収束しているため終了
	    last;
	}
	else
	{
	    undef %ClasterHash;
	    %ClasterHash = %NewClasterHash;
	}
    }

    # 最終的な出力
    open(OUT,">claster.list");
    foreach my $g_name (keys %ClasterHash)
    {
	my $g_list = $ClasterHash{$g_name}; 
	print OUT "$g_name\t$g_list\n";
    }
    close(OUT);
}


# 機能：再構築したクラスタと、前のクラスタが同じかを判定
# 引数
#  - $ref_OLD : 前のクラスタを格納したハッシュのリファレンス
#  - $ref_NEW : 再構築したクラスタを格納したハッシュのリファレンス
# 戻値：同じときは1、異なるときは0を返す
sub evaluateClater
{
    my($ref_OLD,$ref_NEW) = @_;

    foreach my $g_name (keys %{$ref_OLD})
    {
	my @old_list = split(/ /,$$ref_OLD{$g_name});
	my @new_list = split(/ /,$$ref_NEW{$g_name});

	my %Hash;
	foreach my $b_name (@old_list)
	{
	    $Hash{$b_name}++;
	}

	foreach my $b_name (@new_list)
	{
	    $Hash{$b_name}++;
	}

	foreach my $b_name (keys %Hash)
	{
	    # 異なる事例が含まれていた
	    if($Hash{$b_name} == 1)
	    {
		return 0;
	    }
	}

	undef @old_list;
	undef @new_list;
    }
    
    # 全て一致した
    return 1;
}


# 機能：クラスタの平均ベクトル＝代表ベクトルを得る
# 引数
#  - @glist：クラスタに属する記事リスト
# 戻値：平均ベクトルを格納したハッシュ（$Hash{単語}=平均値）
sub getVectorMean
{
    my @glist = @_;

    my %vec_sum;
    my $size=0;  # クラスタに属している記事数

    foreach my $b_name (@glist)
    {
	# ベクトル文字列をTF・IDFハッシュに変換
	# キー：名詞　値：TF・IDF値
	my $vector = $VectorHash{$b_name};
        my %vec = VectorStr_toHash($vector);

	foreach my $t (keys %vec)
	{
	    $vec_sum{$t} += $vec{$t};
	}
	undef %vec;
	
	$size++;
    }

    # ベクトルの平均
    my %vec_mean;
    foreach my $t (keys %vec_sum)
    {
	my $sum_tfidf = $vec_sum{$t};
	$vec_mean{$t} = $sum_tfidf/$size;

	# print encode_utf8("$t $vec_mean{$t} \n");
    }

    return %vec_sum;
}


# initial.listを読み込んで、初期クラスタを得る              
# $ClasterHash{group185} =  2012-01-16_0 2011-12-12_0 2012-05-02_0 ...
sub getInitializeClaster
{
    open(LIST,"initial.list") || die "Can't open initial.list\n";

    my %ClasterHash;
    while(my $data = <LIST>)
    {
	chomp($data);
	my($g_name,$list) = split(/\t/,$data);

	# print "$g_name -> $list \n";

	$ClasterHash{$g_name} = $list;
    }
    close(LIST);

    return %ClasterHash;
}


# 機能：２つのベクトルのcosin距離の計算
# 引数：
#  -$ref_HashX : 単語ベクトルハッシュX
#  -$ref_HashY : 単語ベクトルハッシュY
# 戻値：cosin距離
sub calc_cosin
{
    my($ref_HashX,$ref_HashY) = @_;

    my %Hash;

    # ノルムＸを計算
    my $X;
    foreach my $term (keys %{$ref_HashX})
    {
        my $tfidf = $$ref_HashX{$term};
        $X += $tfidf**2;

        $Hash{$term}++;
    }

    # ノルムＹを計算
    my $Y;
    foreach my $term (keys %{$ref_HashY})
    {
        my $tfidf = $$ref_HashY{$term};
        $Y += $tfidf**2;

        $Hash{$term}++;
    }

    # 内積を計算
    my $P;
    foreach my $term (keys %Hash)
    {
        if($Hash{$term} > 1)
        {
	    my $tfidf_x = $$ref_HashX{$term};
            my $tfidf_y = $$ref_HashY{$term};

            $P +=  $tfidf_x*$tfidf_y;
        }
    }
    undef %Hash;

    my $cos = $P/sqrt($X)/sqrt($Y);
    return $cos;
}


# 機能：ベクトル文字列（単語:頻度 単語:頻度...）をTF・IDFハッシュに変換
# 引数
#  -$vec：ベクトル文字列（単語:頻度 単語:頻度...）
# 戻値：%Hash{名詞} = TF・IDF値
sub VectorStr_toHash
{
    my($vec) = @_;

    my @TermList = split(/ /,$vec);

    my %TFIDF;

    foreach my $ttf (@TermList)
    {
	my($term,$tf) = split(/:/,$ttf);
	
        my $df;
        if(defined $DocumentFrequency{$term})
        {
	    $df = $DocumentFrequency{$term};
        }
        else
        {
            $df = 1;   # df=0になることを防ぐため
        }

        my $tfidf = $tf*log($N/$df)/log(2);
        $TFIDF{$term} = $tfidf;

	# print encode_utf8("$term -> $tf * log($N / $df) = $tfidf\n");
    }
    undef @TermList;

    return %TFIDF;
}


# 機能：初期クラスタを得る。
# 引数
#  - $claster_size：指定したクラスタ数
#  - @TestList：記事ファイルリスト
# 戻値：初期クラスタを格納したハッシュ（$Hash{group1} = "2012-03-05_0 2011-11-22_2 ..."）
sub getInitializeClasterNaive
{
    my($claster_size,$ref_TestList) = @_;

    my @TestList = @{$ref_TestList};

    # クラスタを生成
    my %ClasterHash;
    my $t=1;
    my $i;
    for($i=1; $i<=$#TestList; $i++)
    {
	# ファイルのベース名を取得(2011-10-31_0.txt → 2011-10-31_0)
	my $file = $TestList[$i];
        my($bname) = split(/\./,basename($file));

	my $g_name = "group"."$t";
	$ClasterHash{$g_name} .= $bname." ";

	# print "$g_name -> $ClasterHash{$g_name}\n";

	if($t == $claster_size)
	{
	    $t=1;
	}
	else
	{
	    $t++;
	}
    }

    return %ClasterHash;
}

# --------------- 


# 文書頻度の取得
sub createDocumentFrequency
{
    my %VectorHash = @_;

    my %DocumentFrequency;

    foreach my $bname (keys %VectorHash)
    {
        my $vec = $VectorHash{$bname};
        my @TermList = split(/ /,$vec);

        foreach my $ttf (@TermList)
        {
	    my($term,$tf) = split(/:/,$ttf);
            $DocumentFrequency{$term}++;
        }
        undef @TermList;
    }

    return %DocumentFrequency;
}


# 機能：データのテキストファイルを形態素解析し、ベクトル化して格納
# 引数：
#   - @TextList : テキストファイルのリスト
# 戻値：ベクトルハッシュ
#   - $Hash{ファイル名} = 単語ベクトル（「単語:頻度 単語:頻度...」）
sub createVectorHash
{
    my @TextList = @_;

    my %VectorHash;

    foreach my $file (@TextList)
    {
	# fileの形態素解析を行い、名詞を取り出す
        my %TermFrequency = get_POS_data($file);
        
        # ハッシュをベクトルに変換
        my $vec = createVector(%TermFrequency);

	# ファイルのベース名を取得(2011-10-31_0.txt → 2011-10-31_0)
        my($bname) = split(/\./,basename($file));

	$VectorHash{$bname} = $vec;

	undef %TermFrequency;
    }

    return %VectorHash;
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

        foreach my $s (@Str)
        {
            my($term,$pos_info) = split(/\t/,$s);    

            # 品詞を取得
            my($pi) = split(/,/,$pos_info);

	    # ２文字以上の名詞のみとする
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
    open(IN,$file) || die "Can't open $file\n";

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

