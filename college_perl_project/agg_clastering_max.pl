#!/usr/bin/perl

# 凝集型クラスタリングによるクラスタリング

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

# 指定したクラスタ数になるまで併合したら終了
our $Threshold = 10;

# 高速化のため、一度、計算した類似度を記録
our %SimilarityHash;

# 記事データの読み込み
my @TextList = glob("./data/*.txt");

# 記事総数
my $N = @TextList;

main();

sub main
{
    # データのテキストファイルを形態素解析し、ベクトル化して格納
    my %VectorHash = createVectorHash(@TextList);

    # 文書頻度の取得
    my %DocumentFrequency = createDocumentFrequency(%VectorHash);

    # 最初は、各テキストファイルを１つのクラスタとする
    my %ClasterHash;
    my $id = 1;
    my $claster_size = 0;
    foreach my $basename (keys %VectorHash)
    {
	# グループ名を生成
	my $g_name = "group".$id;

	$ClasterHash{$g_name} = $basename;

	$id++;
	$claster_size++;
    }

    while($claster_size > $Threshold)
    {
	my $best_sim = 0;

	my $agg_claster1;
	my $agg_claster2;

	# グループ名のリストを取得
	my @ClasterList = keys (%ClasterHash);

	my $i;
	for($i=0; $i<$#ClasterList; $i++)
	{
	    my $g_name1 = $ClasterList[$i];
	    my $g_list1 = $ClasterHash{$g_name1};

	    my $j;
	    for($j=$i+1; $j<=$#ClasterList; $j++)
	    {
		my $g_name2 = $ClasterList[$j];
		my $g_list2 = $ClasterHash{$g_name2};

		# 単連結法に基づいてグループ間の類似度を計算
		my $similarity = calc_similarity_of_cluster($g_list1,$g_list2,\%DocumentFrequency,\%VectorHash);

		# print "$g_list1 $g_list2 $similarity\n";

		# 類似度が最大の２つのグループ名を取得
		if($similarity > $best_sim)
		{
		    $best_sim = $similarity;
		    $agg_claster1 = $g_name1;
		    $agg_claster2 = $g_name2;
		}
	    }
	}

	print encode_utf8("併合クラスタ $agg_claster1 ←  $agg_claster2 $best_sim \n");

	# クラスタを併合して（agglomerative）、ClasterHashを更新
	my $g_list1 = $ClasterHash{$agg_claster1}; 
	my $g_list2 = $ClasterHash{$agg_claster2};

	$ClasterHash{$agg_claster1} = $g_list1." ".$g_list2;
	delete $ClasterHash{$agg_claster2};

	$claster_size--;
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

# 機能：単連結法に基づいてグループ間の類似度を計算
# 引数：
#  -$g_list1: グループ１の記事リスト（スペース区切り）
#  -$g_list2: グループ２の記事リスト（スペース区切り）
#  -$ref_DocumentFrequency: 文書頻度を格納したハッシュ
#  -$$ref_VectorHash: 全ての記事をベクトル化して格納したハッシュ
# 戻値：類似度
sub calc_similarity_of_cluster
{
    my($g_list1,$g_list2,$ref_DocumentFrequency,$ref_VectorHash) = @_;

    my @GList1 = split(/ /,$g_list1);
    my @GList2 = split(/ /,$g_list2);

    my $best_cos=1;   # 類似度の最大値

    foreach my $file_name1 (@GList1)
    {
        foreach my $file_name2 (@GList2)
        {
            # cosin距離の計算
            my $cosin;
            my $key = $file_name1."-".$file_name2;

            if(defined $SimilarityHash{$key})
            {
                $cosin = $SimilarityHash{$key};
            }
            else
            {
                my $vector1 = $$ref_VectorHash{$file_name1};
                my $vector2 = $$ref_VectorHash{$file_name2};

                # ベクトル文字列をTF・IDFハッシュに変換
                # キー：名詞　値：TF・IDF値
                my %vec1_tfidf = VectorStr_toHash($vector1,$N,$ref_DocumentFrequency);
                my %vec2_tfidf = VectorStr_toHash($vector2,$N,$ref_DocumentFrequency);
                # 類似度を計算
                $cosin = calc_cosin(\%vec1_tfidf,\%vec2_tfidf);

                # 計算した類似度をキャッシュ
                $SimilarityHash{$key} = $cosin;

                undef %vec1_tfidf;
                undef %vec2_tfidf;
            }
	    
            # 最大の類似度を求める
            if($cosin < $best_cos)
            {
                $best_cos = $cosin;
            }
        }
    }
    
    return $best_cos;
}


# 機能：文書頻度（Document Frequency）の取得
# 引数：
#  -%VectorHash : 全ての記事をベクトル化して格納したハッシュ
# 戻値：文書頻度を格納したハッシュ（$Hash{単語} = 文書頻度）
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

        $Hash{$term}+=1;
    }

    # ノルムＹを計算
    my $Y;
    foreach my $term (keys %{$ref_HashY})
    {
        my $tfidf = $$ref_HashY{$term};
        $Y += $tfidf**2;

        $Hash{$term}+=1;
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
#  -$N：文書数
#  -%DocumentFrequyency：文書頻度
# 戻値：%Hash{名詞} = TF・IDF値
sub VectorStr_toHash
{
    my($vec,$N,$ref_DocumentFrequency) = @_;

    my @TermList = split(/ /,$vec);

    my %TFIDF;

    foreach my $ttf (@TermList)
    {
	my($term,$tf) = split(/:/,$ttf);
	
        my $df;
        if(defined $$ref_DocumentFrequency{$term})
        {
	    $df = $$ref_DocumentFrequency{$term};
        }
        else
        {
            $df = 1;   # df=0になることを防ぐため
        }

        my $tfidf = $tf*log($N/$df)/log(2);
        $TFIDF{$term} = $tfidf;
    }
    undef @TermList;

    return %TFIDF;
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

