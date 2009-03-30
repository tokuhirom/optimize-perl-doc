#!/usr/bin/perl -w
use Benchmark 'cmpthese';

my $max = 100_000;
cmpthese(
    1000 => {
        cached  => sub { my $a; for (0..$max) {$a = 3; } },
        nocache => sub { for (0..$max) {my $a = 3; } },
    }
);

__END__

=head1 for 文の前であらかじめ変数を宣言しておく

激しくまわる for 文の中で my を宣言すると、領域の確保/開放のコストが増加してしまうため、あらかじめ宣言しておくと速くなったりする場合もある。

激しく可読性がおちるので、素人にはおすすめしないし、よほどパフォーマンスが気になるときにだけつかうべき技である。

=head2 結果

                    Rate nocache  cached
          nocache 58.7/s      --    -23%
          cached  76.4/s     30%      --

