#!/usr/bin/perl

use strict;
use Encode;
use utf8;


main();

sub main
{
    my $train_file = "/Users/yanagisawakai/college2023_1/data_mining/college_perl_project/implementationNaiveBayes/train.list";
    createModelFile($train_file);
}

sub createModelFile
{
    my $train_file = $_[0];
    open(my $IN, $train_file) or die("error :$!");

    # ファイルデータを変数へ格納
    my @ClassList;
    my %Occur;
    my $tag_sum;
    while (my $data_utf8 = <$IN>)
    {
        chomp($data_utf8);

        my @FileInfo = split(/ /, decode_utf8($data_utf8));
        my @Tag = split(/,/, $FileInfo[2]);

        my $file_name = $FileInfo[0];
        my $class_name = $FileInfo[1];

        push(@ClassList, $class_name);

        $tag_sum += $#Tag + 1;
        for (my $i = 0; $i <= $#Tag; $i++)
        {
            $Occur{$class_name}{$Tag[$i]}++;
        }
    }

    my %ClassProbability;
    # 各クラスの事前確率計算 P(c)
    my $class_sum = $#ClassList + 1;
    for (my $i = 0; $i <= $#ClassList; $i++)
    {
        $ClassProbability{$ClassList[$i]}++; 
    }
    foreach my $class_pro (keys %ClassProbability)
    {
        $ClassProbability{$class_pro} /= $class_sum;
    }

    # 各クラスにおける名詞の条件付き確率 P(e|c)
    foreach my $class_name (keys %Occur)
    {
        my $tag_sum;
        foreach my $tag (keys %{$Occur{$class_name}})
        {
            $tag_sum += $Occur{$class_name}{$tag};
        }
        foreach my $tag (keys %{$Occur{$class_name}})
        {
            $Occur{$class_name}{$tag} /= $tag_sum;
        }
    }
    close($IN);

    # ファイルへの書き出し
    open(my $OUT, ">model");
    print $OUT encode_utf8("<feature> $tag_sum\n");
    foreach my $class_name (keys %ClassProbability)
    {
        print $OUT encode_utf8("<prior> $class_name $ClassProbability{$class_name}\n");
    }
    foreach my $class_name (keys %Occur)
    {
        foreach my $tag (keys %{$Occur{$class_name}})
        {
            print $OUT encode_utf8("<conditional> $class_name $tag $Occur{$class_name}{$tag}\n");
        }
    }
}