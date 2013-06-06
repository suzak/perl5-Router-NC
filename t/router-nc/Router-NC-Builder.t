package t::Router::NC::Builder;
use t::;
no feature 'unicode_strings'; # v5.10 相当

sub require : Test(startup => 1) {
    require_ok 'Router::NC::Builder';
}

sub _new : Test(2) {
    my $builder = Router::NC::Builder->new;
    isa_ok $builder, 'Router::NC::Builder';
    eq_or_diff $builder->{variables}, { };
}

sub _variable : Test(1) {
    my $builder = Router::NC::Builder->new;
    $builder->variable(hoge => 'hoge|fuga');
    eq_or_diff $builder->{variables}, {
        hoge => {
            re => 'hoge|fuga',
            code => undef,
        },
    };
}

sub _route : Test(5) {
    my $builder = Router::NC::Builder->new;
    my $args;

    local *Router::NC::Tree::add = sub { (my $class, @$args) = @_ };
    $builder->route('/:hoge', 'GET', 1, 2);
    eq_or_diff $args, [ '/:hoge',
        method    => 'GET',
        args      => [ 1, 2 ],
        variables => { },
    ];
    $args = undef;

    for my $method (qw(get post put delete)) {
        $builder->$method('/:hoge', 1, 2);
        eq_or_diff $args, [ '/:hoge',
            method    => uc $method,
            args      => [ 1, 2 ],
            variables => { },
        ];
        $args = undef;
    }
}

sub _build : Test(4) {
    my $builder = Router::NC::Builder->new;
    my $code = sub { $_ };
    $builder->variable(var => 'hoge|fuga', $code);
    $builder->get('/', 1);
    $builder->get('/:var', 2);

    my $router = $builder->build;
    isa_ok $router, 'Router::NC';
    is $router->{re}, qr<^\/(?:(?<_0>)|(?<var>hoge|fuga)(?<_1>))$>msx;
    eq_or_diff $router->{routes}, [
        { GET => [ 1 ] },
        { GET => [ 2 ] },
    ],
    eq_or_diff $router->{variables}, { var => $code };
}
