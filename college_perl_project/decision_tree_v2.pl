#!/usr/bin/perl

use strict;   # Perl pragma to restrict unsafe constructs
use Encode;   # character encodings in Perl
use utf8;     # Perl pragma to enable/disable UTF-8 in source code

my $train_file= $ARGV[0];  # 入力データファイル
my @DecisionList;          # 生成される決定木リスト

main();

sub main
{ 
    # 決定木生成のための学習データを多重ハッシュテーブルに格納
    # 例：$TrainData{天気}->{晴}->{○} = 頻度
    my %TrainData = getTrainData($train_file);

    # 決定木の作成（第一引数は木の深さ）
    genDecitionTree(0,\%TrainData);

}


# 機能：決定木を作成し表示
# 引数
#  - $depth : 木の深さ
#  - $ref_TrainData : 学習データを格納したハッシュのリファレンス
# 戻値：なし
sub genDecitionTree
{
     my($depth,$ref_TrainData) = @_;

     # %TrainDataハッシュを復元
     my %TrainData = %{$ref_TrainData};

     $depth++;  # 木の深さを一つ増加

     # 根の分割属性を取得
     # %RootTag{採用した分割属性}->{属性値} = 情報利得 or ○ or ×
     my %RootTag = getRootTag(%TrainData);

     my($root_tag) = keys %RootTag;  # 採用した分割属性
    
     # 採用した分割属性を表示
     my $is_leef = 1;
     foreach my $data (keys %{$RootTag{$root_tag}})
     {
	    my $det = $RootTag{$root_tag}->{$data};

            # 属性値が全て○か×に属していれば、表示して終了
	    if($det eq "○" || $det eq "×")
	    {
                # 表示において木の深さを表現
                my $i=0;
                for($i=0; $i<$depth; $i++)
                {
                    print "\t";
                }

		print encode_utf8("$root_tag = $data → $det\n");
	    }
	    else
	    {
                # 表示において木の深さを表現
                my $i=0;
                for($i=0; $i<$depth; $i++)
                {
                    print "\t";
                }

		print encode_utf8("$root_tag = $data ↓\n");

                # 採用した分割属性($root_tag)と属性値($data)に応じた
                # 部分集合を取得（テストデータから再度、取得）
	        %TrainData = getSubTrainData($train_file,$root_tag,$data);

                # 採用した分割属性は除去
                foreach my $tag (@DecisionList)
                {
                    delete $TrainData{$tag};
                }

                # 決定木の成長（再帰的に繰り返す）
                genDecitionTree($depth,\%TrainData);

                $is_leef = 0;
	    }
     }

     # 採用した分割属性を記録
     if($is_leef == 1)
     {
	 push(@DecisionList,$root_tag);
     }
}



# 機能：根の分割属性を取得
# 引数：学習用データを格納したハッシュのリファレンス
# 戻値：%RootTag{採用した分割属性}->{属性値} = 情報利得 or ○ or ?
sub getRootTag
{
    my %TrainData = @_;

    my $root_tag;
    my $best_info=0;
    my $fv = 0;

    # 各分割属性の分割後のエントロピーを格納
    my %EntropyHash;

    foreach my $tag (keys %TrainData)
    {
         # 全体のデータ数を取得
	 my $N=0;
	 foreach my $data (keys %{$TrainData{$tag}})
         {
	      my $fo  = $TrainData{$tag}{$data}{"○"};
              my $fx  = $TrainData{$tag}{$data}{"×"};
              $N += ($fo+$fx);
         }
      
         # 各分割属性（「天気」等）のエントロピーを計算
	 my $ave_info;
         my $all_fo=0;
         my $all_fx=0;

         foreach my $data (keys %{$TrainData{$tag}})
         {
	      my $fo  = $TrainData{$tag}{$data}{"○"};
              my $fx  = $TrainData{$tag}{$data}{"×"};

              # 各ノード（i=天気→晴）のエントロピーを計算
              my $info = calcInfo($fo,$fx);

	      $EntropyHash{$tag}{$data} = $info;

              # エントロピーの平均を計算
	      $ave_info += ($fo+$fx)/$N*$info;

              $all_fo += $fo;
              $all_fx += $fx;
         }

         # ノード（i=天気）のエントロピーを計算
         my $root_info = calcInfo($all_fo,$all_fx);

         # 情報利得を計算
         my $info_rate = $root_info - $ave_info;

	 if($fv == 0)
         {
		 #print encode_utf8("\n分割前のエントロピー：$root_info\n");
             $fv=1;
         }
	 # print encode_utf8("情報利得：$tag $info_rate（$root_info - $ave_info）\n");

         # 情報利得が最大の分割属性を取得
         if($info_rate >= $best_info)
         {
	     $root_tag = $tag;
             $best_info = $info_rate;
         }
    }

    # 採用した分割属性の属性値ごとの判定（○?）を確定
    my %RootTag;
    foreach my $data (keys %{$TrainData{$root_tag}})
    {
          # 各ノード（i=天気→晴）の分割後のエントロピー
          my $info = $EntropyHash{$root_tag}{$data};

          # エントロピー = 0の場合は（○ or×）を確定
          if($info == 0)
          {
	     my $fo  = $TrainData{$root_tag}{$data}{"○"};

             if($fo > 0)
             {
                  $RootTag{$root_tag}->{$data} = "○";
             }
             else
             {
                  $RootTag{$root_tag}->{$data} = "×";
             }
          }
          else
          {
             $RootTag{$root_tag}->{$data} = $info;
          }
    }

    return %RootTag;
}


# エントロピーを計算
sub calcInfo
{
    my($fo,$fx) = @_;

    my $Po = $fo/($fo+$fx);
    my $Px = $fx/($fo+$fx);

    my $H;
    if($Po != 0 && $Px != 0)
    {
       my $Io = -1*$Po*log($Po)/log(2);
       my $Ix = -1*$Px*log($Px)/log(2);
       $H = $Io+$Ix;
    }
    else
    {
       $H = 0;
    }

    return $H;
}


# 学習データをハッシュテーブルに格納
sub getTrainData
{
    my($train_file) = @_;

    open(my $IN,$train_file);

    # 分割属性
    my $data_utf8 = <$IN>;   # 一行読み込み
    chomp($data_utf8);      # 改行除去
 
    # タグを区切り文字として、要素を配列に格納
    # 例：$data_utf8="天気	温度	湿度	風	ゴルフプレイ"
    # my @Tag = split(/\t/,decode_utf8($data_utf8)); 
    #   ↓
    # $Tag[0]="天気"
    # $Tag[1]="温度"
    # $Tag[2]="湿度"
    # $Tag[3]="風"
    # $Tag[4]="ゴルフプレイ"

    my @Tag = split(/\t/,decode_utf8($data_utf8)); 

    my %TrainData;   # ハッシュ変数を宣言

    # ファイルの終わりまで一行づつ読み込み
    while(my $data_utf8 = <$IN>)
    {
          chomp($data_utf8);
          my @Data = split(/\t/,decode_utf8($data_utf8));

          # ゴルフプレイ（○ or ×）を取得
          # pop命令：配列の最後の要素を取得
          my $det = pop(@Data);

          my $i;
          for($i=0; $i<=$#Data; $i++)
          {
              my $tag = $Tag[$i];
              my $data = $Data[$i];

              $TrainData{$tag}->{$data}->{$det}++;
          }
          undef @Data;
    }
    close($IN);

    # データを格納したハッシュ変数をもどす
    return %TrainData;
}


# 採用した分割属性に応じた部分集合を取得
sub getSubTrainData
{
    my($train_file,$object_tag,$object_data) = @_;

    open(IN,$train_file) || die "Can't open $train_file\n";

    # 属性
    my $data_utf8 = <IN>;
    chomp($data_utf8);
    my @Tag = split(/\t/,decode_utf8($data_utf8));

    my %TrainData;

    while(my $data_utf8 = <IN>)
    {
          chomp($data_utf8);
          my @Data = split(/\t/,decode_utf8($data_utf8));

          # ゴルフプレイ（○ or ×）を取得
          my $det = pop(@Data);

          my $i;

          #  条件に合致するデータ列か
          my $sd=0;
          for($i=0; $i<=$#Data; $i++)
          {
              my $tag = $Tag[$i];
              my $data = $Data[$i]; 

              if($tag eq $object_tag && $data eq $object_data)
              {
		  $sd = 1;
              }
          }

          # 条件に合致するデータ列であれば、データを格納
          if($sd == 1)
          {
             for($i=0; $i<=$#Data; $i++)
             {
                my $tag = $Tag[$i];
                my $data = $Data[$i];

                if($tag ne $object_tag || $data ne $object_data)
                {
                     # print encode_utf8("$tag -> $data = $det\n");
                     $TrainData{$tag}->{$data}->{$det}++; 
                } 
             }
          }

          undef @Data;
    }
    close(IN);

    return %TrainData;
}
