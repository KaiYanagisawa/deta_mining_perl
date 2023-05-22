#!/usr/bin/perl

# modelファイルからナイーブベイズ学習式のパラメータを読み出し
# テスト用ファイルの新規事例をクラス分類

use strict;   # Perl pragma to restrict unsafe constructs
use Encode;   # character encodings in Perl
use utf8;     # Perl pragma to enable/disable UTF-8 in source code


main();


sub main
{   
    my $test_file = $ARGV[0];  # テスト用ファイルを指定
    my $model_file = $ARGV[1]; # modelファイル（bayes_learnで生成）を指定

    # modelファイルから事前確率 P(c) を復元
    # hash{○} = P(○)
    my %PH = getPriorProbabilty($model_file);

    # modelファイルから条件付き確率 P(e_{n}|c) を復元
    # hash{○}->{天気:晴} = P(天気:晴|○)
    my %PE = getConditionalProbabilty($model_file);

    # 新規事例データの読み込み
    open(IN,$test_file);

    # 属性を取得
    my $tag_utf8 = <IN>;
    chomp($tag_utf8);
    my $tag_data = decode_utf8($tag_utf8);

    my $product_pe = 1;

    while(my $data_utf8 = <IN>)
    {
        chomp($data_utf8);
        my $new_data = decode_utf8($data_utf8);

        print encode_utf8("新規事例データ →\t$new_data\n");

        my $best_like = 0;
        my $argmax_det;

        # 尤度を計算
		foreach my $det (keys %PH)
		{
	    	my $prior = $PH{$det};           # 事前確率: P(c)
	    	my %conditional = %{$PE{$det}};  # 条件付き確率: P(e_{n}|c)

	    	# P(e_{n}|c)の直積を計算
            my $product_pe = calc_likelihood($new_data,$tag_data,%conditional);

            # 尤度 P(c|E)を計算
	    	my $like = $prior*$product_pe;

            print encode_utf8("\t$det\t尤度：$like\n");

            # argmax_{c} P(c|E) 
            # 尤度の最も大きい c を求める
            if($like > $best_like )
            {
                $best_like = $like;
                $argmax_det = $det;
            }
		}

        # 尤度の最も大きい c を出力
        print encode_utf8("判定：$argmax_det \n");
    }
    close(IN);
}




# modelファイルから事前確率 P(c) を復元
sub getPriorProbabilty
{
    my($model_file) = @_;

    open(MODEL,$model_file); 

    my %PH;
    while(my $data_utf8 = <MODEL>)
    {
        chomp($data_utf8);
        my($tag,$det,$p) = split(/\t/,decode_utf8($data_utf8));

        if($tag eq "<prior>")
        {
	   		$PH{$det} = $p;
		}
    }
    close(MODEL);

    return %PH;
}


# modelファイルから条件付き確率 P(e_{n}|c) を復元
sub getConditionalProbabilty
{
    my($model_file) = @_;
    open(MODEL,$model_file); 

    my %PE;
    while(my $data_utf8 = <MODEL>)
    {
        chomp($data_utf8);
        my($tag,$det,$clause,$p) = split(/\t/,decode_utf8($data_utf8));

        if($tag eq "<conditional>")
        {
	    	$PE{$det}->{$clause} = $p;
		}
    }
    close(MODEL);

    return %PE;
}


# 機能：P(e_{n}|c)の直積を計算
# 引数：
#   $new_data：属性値列（晴      涼      高      有）
#   $tag_data：属性列（天気    温度    湿度    風）
#   %conditional：P(e_{n}|c)を格納したハッシュ
# 戻値：P(e_{n}|c)の直積
sub calc_likelihood
{
    my($new_data,$tag_data,%conditional) = @_;

    # 属性（例： 天気）
    my @Tag = split(/\t/,$tag_data);

    my $product_pe = 1;

    # 属性値（例： 晴）
    my @Data = split(/\t/,$new_data);

    my $i;
    for($i=0; $i<@Data; $i++)
    {
		my $tag = $Tag[$i];
		my $data = $Data[$i];

        # 属性：属性値　（例　天気：晴）
		my $clause = $tag.":".$data;

        # 各属性値の条件付き確率 P(e_{n}|c) の直積
        $product_pe *= $conditional{$clause};
    }
    undef @Data;

    return $product_pe;
}

