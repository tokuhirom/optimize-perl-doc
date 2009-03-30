#!/usr/bin/perl -w
use Benchmark 'cmpthese';

{
    package Hige;
    sub new { bless ['Megane'], shift }
    sub copy { my ($self, $arg) = @_; $self->[0] = $arg; }
    sub nocopy { $_[0]->[0] = $_[1] }
}

my $higemegane = Hige->new();
cmpthese(
    1000000 => {
        copy   => sub { $higemegane->copy(1) },
        nocopy => sub { $higemegane->nocopy(1) },
    }
);

__END__

=head1 引数をそのままつかう

Perl では、@_ に格納されている変数は、引数としてわたされた sv そのものです。
そのものなので、これを変更すると、コールスタックの上の方にある変数に直接影響をあたえることになってしまいます。

そこで、通常使用では

    my $self = shift;

としたり

    my ($arg1, $arg2) = @_;

などのように書いて、引数をコピーしてつかうことが推奨されています。

しかし、チューニングが必要不可欠な場合においては、これを直接つかうことで、パフォーマンスが向上します。

パフォーマンスチューニングの最初の一歩は、どのタイミングで sv のコピーがおきるかを知るところからはじまります。

=head2 結果

この場合だと、70% ほど高速であるということがわかります。

                        Rate   copy nocopy
            copy    746269/s     --   -41%
            nocopy 1265823/s    70%     --

