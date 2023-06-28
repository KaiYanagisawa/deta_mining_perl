#!/usr/bin/perl

# ナイーブベイズ学習に基づき、学習式のパラメータを推定する
# 推定したパラメータは model ファイルに保存する

use strict;   # Perl pragma to restrict unsafe constructs
use Encode;   # character encodings in Perl
use utf8;     # Perl pragma to enable/disable UTF-8 in source code

# 学習用データファイルの指定
our $train_file= $ARGV[0];

main();

sub main
{
    createModelFile($train_file);
}


sub createModelFile
{
    my($train_file) = @_;

    # 学習用データファイルのオープン
    open(IN,$train_file);

    # 属性の読み込み
    my $data_utf8 = <IN>;
    chomp($data_utf8);
    my @Tag = split(/\t/,decode_utf8($data_utf8));

    my %TrainData;

    my $N = 0;      # 事例数
    my %Hypo;

    # 訓練データの読み込み
    # 例：$TrainData{○}->{天気:晴} = 頻度
    while (my $data_utf8 = <IN>)
    {
        chomp($data_utf8);
        my @Data = split(/\t/,decode_utf8($data_utf8));

        # ゴルフプレイ（○ or ×）を取得
        my $det = pop(@Data);

        # 学習用データ事例数の総数
        $Hypo{$det}++;
        $N++;

        my $i;
        for ($i=0; $i<@Data; $i++)
        {
            my $tag = $Tag[$i];
            my $data = $Data[$i];

            # 属性：属性値（例　天気:晴） 
            my $clause = $tag.":".$data;

            # 各クラス（○ or ×）における属性値の頻度を格納
            $TrainData{$det}->{$clause}++;
        }
			undef @Data;
    }
    close(IN);

    my %PH;		# 事前確率 P(H=○,×)
    my %PE;     # 属性ごとの条件付き確率 P(E_{n}|H)

    # 学習式におけるパラメータを学習
    foreach my $det (keys %TrainData)
    {
        # 事前確率: P(c)
        my $f_h = $Hypo{$det};
		$PH{$det} = $f_h/$N;

        # 各属性値の条件付き確率 P(e_{i}|c)
        foreach my $clause (keys %{$TrainData{$det}})
        {
            my $f_eh = $TrainData{$det}->{$clause};
            $PE{$det}->{$clause} = $f_eh/$f_h;
        }
    }

    # モデルファイルを表示
   
    # 事前確率を書き出し
    foreach my $det (keys %PH)
    {
        print encode_utf8("<prior>\t$det\t$PH{$det}\n");
    }

    # 各属性値の条件付き確率を書き出し
    foreach my $det (keys %PE)
    {
        foreach my $clause (keys %{$PE{$det}})
        {
            my $P = $PE{$det}->{$clause};
            print encode_utf8("<conditional>\t$det\t$clause\t$P\n");
        }
    }
}

