use strict;
use Encode;
use utf8;

main();

sub main
{
    open(my $IN, "model");

    my %ConditionalHash;
    my %PriorHash;
    my $H = 1;

    # データを変数へ格納
    while (my $data_utf8 = <$IN>)
    {
	    chomp($data_utf8);

        my @Data = split(/ /, decode_utf8($data_utf8));

        if ($Data[0] eq "<conditional>")
        {
            $ConditionalHash{$Data[1]}{$Data[2]} = $Data[3];
        }
        elsif ($Data[0] eq "<prior>")
        {
            $PriorHash{$Data[1]} = $Data[2];
        }
        elsif ($Data[0] eq "<feature>") 
        {
            $H = $Data[1];
        }
    }

    close($IN);

    open($IN,"/Users/yanagisawakai/college2023_1/data_mining/college_perl_project/implementationNaiveBayes/test.list") or die("error :$!");
    while (my $data_utf8 = <$IN>)
    {
        my %NewHash;

	    chomp($data_utf8);

        # test.listのデータ格納
        my($input_file, $class, $word) = split(/ /, decode_utf8($data_utf8));
        my @WordList = split(/,/, $word);

        my $nearest = 0;
        my $nearest_key;

        foreach my $class_key (keys %ConditionalHash)
        {
            # log(P(c)) 計算
            my $c_probability = $PriorHash{$class_key};
            $NewHash{$class_key} = log($c_probability);

            # 学習式 log(P(c))+Σ[i=1..n]log(P(ei|c)) 計算
            foreach my $word_key (@WordList)
            {
                my $e_c_probability = $ConditionalHash{$class_key}{$word_key};
                if($e_c_probability == 0)
                {
                    $e_c_probability = 1 / $H;
                }
                $e_c_probability = log($e_c_probability);
                $NewHash{$class_key} += $e_c_probability;
            }

            # 上の学習式計算結果の最大値をクラス名に選定
            if ($nearest == 0 || $NewHash{$class_key} > $nearest)
            {
                $nearest = $NewHash{$class_key};
                $nearest_key = $class_key;
            }
	    }

        print encode_utf8("$input_file -> $nearest_key\t$nearest\n");
    }

    close($IN);
}