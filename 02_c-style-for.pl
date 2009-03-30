#!/usr/bin/perl -w
use Benchmark 'cmpthese';

my $max = 100_000;
cmpthese(
    1000 => {
        c_style => sub { for (my $i=0; $i<$max; $i++) { } },
        iter    => sub { for my $i (0..$max) { } },
    }
);

__END__

=head1 C-style の for 文よりもイテレータをつかう

C-style の for 文では、ループのたびに sv の比較/インクリメントなどの操作がはいるため、イテレータをつかった foreach ループよりも格段に速度が落ちる。

=head2 Terse

OP Tree の解析結果は以下のようになる。あきらかに c-style for の方が分量が多い(分量が多い方が遅いというわけではないが)。

c-style for をよくみると、pp_lt($i<10000) や pp_preinc($i++) などの処理がはいっているのがよくわかる。

    % perl -MO=Terse -e 'for ($i=0;$i<10000;$i++) { }'
    LISTOP (0x8296fc8) leave [1]
        OP (0x8194188) enter
        COP (0x8217508) nextstate
        BINOP (0x8183bb0) sassign
            SVOP (0x819c1a0) const [5] IV (0x817f920) 0
            UNOP (0x819c008) null [15]
                PADOP (0x819a150) gvsv  GV (0x81987c8) *i
        LISTOP (0x8230420) lineseq
            COP (0x8265f08) nextstate
            BINOP (0x8230400) leaveloop
                LOOP (0x82666a8) enterloop
                UNOP (0x8266098) null
                    LOGOP (0x8266078) and
                        BINOP (0x81a4340) lt
                            UNOP (0x819c9d8) null [15]
                                PADOP (0x8236788) gvsv  GV (0x81987c8) *i
                            SVOP (0x819c098) const [6] IV (0x81987e8) 10000
                        LISTOP (0x8265800) lineseq
                            LISTOP (0x82657e0) scope
                                OP (0x8195198) stub
                            UNOP (0x8236930) preinc [4]
                                UNOP (0x8236910) null [15]
                                    PADOP (0x81a4360) gvsv  GV (0x81987c8) *i
                            OP (0x81b7d10) unstack

一方、イテレータをつかっている場合は、インクリメント、デクリメントは perl 内部でおこなわれる。これにより、OP よびだしが節約できるし、カウンタは通常の perl 変数としてはアクセスされないので、tie されたり変更されたりする心配がないので、処理が迅速におこなえる。

    % perl -MO=Terse -e 'for (0..10000) { }' 
    LISTOP (0x819bda8) leave [1] 
        OP (0x81b7d00) enter 
        COP (0x819c088) nextstate 
        BINOP (0x819bf40) leaveloop 
            LOOP (0x8194190) enteriter 
                OP (0x8193b98) null [3] 
                UNOP (0x819bd20) null [142] 
                    OP (0x8194178) pushmark 
                    SVOP (0x819c068) const [4] IV (0x817f920) 0 
                    SVOP (0x819bc18) const [5] IV (0x81987b8) 10000 
                PADOP (0x819be58) gv  GV (0x817f810) *_ 
            UNOP (0x819bed8) null 
                LOGOP (0x819beb8) and 
                    OP (0x819be40) iter 
                    LISTOP (0x819be20) lineseq 
                        OP (0x819bbe0) stub 
                        OP (0x819bc38) unstack 

=head2 結果

                    Rate c_style    iter
          c_style 69.3/s      --    -53%
          iter     147/s    112%      --

