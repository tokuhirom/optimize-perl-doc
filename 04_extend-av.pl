#!/usr/bin/perl -w
use Benchmark 'cmpthese';

my $max = 1_000_000;
cmpthese(
    10 => {
        normal => sub { my @a; for my $i (0..$max) { $a[$i] = $i } },
        filled => sub { my @a; $#a=$max; for my $i (0..$max) { $a[$i] = $i } },
    }
);

__END__

=head1 大きな配列をつくるときはあかじめ拡張しておく

巨大な配列に随時 push すると、あらかじめ確保した領域の上限になるたびに配列のメモリ領域が拡張されるため、速度の低下をまねく。

巨大な配列になることがわかっており、かつその大きさが想定可能である場合には先に領域を確保しておくことが可能である。

=head2 OP ツリーによる解析

$#a は、pp_av2arylen($a) になっているのがわかる。

pp_av2arylen は配列の大きさそのものをあらわす変数をスタックにつむ op code である(see pp.c)。この変数は PERL_MAGIC_arylen フラッグがついており、これに代入されると、av_fill() が呼ばれて、拡張され、代入された数のぶんだけ undef でうめられる。

    % perl -MO=Terse -e 'my @a; $#a = 1000'
    LISTOP (0x819c068) leave [1] 
        OP (0x8194178) enter 
        COP (0x819c088) nextstate 
        OP (0x819bbe0) padav [1] 
        COP (0x819bef8) nextstate 
        BINOP (0x819bed8) sassign 
            SVOP (0x819bf40) const [2] IV (0x817f920) 1000 
            UNOP (0x819bc18) av2arylen 
                OP (0x819be40) padav [1] 

=head2 結果

とおもったらむしろ遅くなってる！

                  Rate filled normal
         filled 3.31/s     --    -7%
         normal 3.56/s     7%     --

