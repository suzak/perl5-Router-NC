package t::Router::NC::Tree;
use t::;

sub _require : Test(startup => 1) {
    require_ok 'Router::NC::Tree';
}

sub _new : Test(2) {
    my $tree = Router::NC::Tree->new;
    isa_ok $tree, 'Router::NC::Tree';
    eq_or_diff { %$tree }, {
        path        => '',
        children    => [],
        is_variable => 0,
        leaf        => undef,
    };
}

sub _common_prefix : Test(5) {
    for (
        ['hoge', 'hoga', 'hog'],
        ['foo', 'foobar', 'foo'],
        ['foobar', 'foo', 'foo'],
        ['', 'hoge', ''],
        ['hoge', '', ''],
    ) {
        my ($r, $l, $e) = @$_;
        is Router::NC::Tree::_common_prefix($r, $l), $e, "common prefix for '$r' and '$l' is '$e'";
    }
}

sub _add : Test(5) {
    my $tree = Router::NC::Tree->new;
    is scalar @{ $tree->{children} }, 0;

    $tree->add('/hoge', method => 'GET', args => 1);
    is scalar @{ $tree->{children} }, 1;

    my $node = $tree->{children}->[0];
    is $node->{path}, '/hoge';
    is $node->{is_variable}, 0;
    is $node->{leaf}->{GET}, 1;
}

sub _add_another_method : Test(6) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/hoge', method => 'GET', args => 1);
    is scalar @{ $tree->{children} }, 1;

    $tree->add('/hoge', method => 'POST', args => 2);
    is scalar @{ $tree->{children} }, 1;

    my $node = $tree->{children}->[0];
    is $node->{path}, '/hoge';
    is $node->{is_variable}, 0;
    is $node->{leaf}->{GET}, 1;
    is $node->{leaf}->{POST}, 2;
}

sub _add_same_method : Test(6) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/hoge', method => 'GET', args => 1);
    is scalar @{ $tree->{children} }, 1;

    like exception { $tree->add('/hoge', method => 'GET', args => 3) }, qr'^/hoge already has routing for method GET';
    is scalar @{ $tree->{children} }, 1;

    my $node = $tree->{children}->[0];
    is $node->{path}, '/hoge';
    is $node->{is_variable}, 0;
    is $node->{leaf}->{GET}, 1;
}

sub _add_another_longer_path : Test(5) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/hoge', method => 'GET', args => 1);

    $tree->add('/hoge/fuga', method => 'GET', args => 4);
    is scalar @{ $tree->{children} }, 1;

    my $node = $tree->{children}->[0];
    is $node->{path}, '/hoge';
    is scalar @{ $node->{children} }, 2;
    is $node->{children}->[0]->{path}, '';
    is $node->{children}->[1]->{path}, '/fuga';
}

sub _add_another_shorter_path : Test(5) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/hoge', method => 'GET', args => 1);

    $tree->add('/', method => 'GET', args => 4);
    is scalar @{ $tree->{children} }, 1;

    my $node = $tree->{children}->[0];
    is $node->{path}, '/';
    is scalar @{ $node->{children} }, 2;
    is $node->{children}->[0]->{path}, 'hoge';
    is $node->{children}->[1]->{path}, '';
}

sub _add_variable_path : Test(8) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/:hoge/fuga', method => 'GET', args => 1);
    is scalar @{ $tree->{children} }, 1;

    my $node = $tree->{children}->[0];
    is $node->{path}, '/';
    is scalar @{ $node->{children} }, 1;

    $node = $node->{children}->[0];
    is $node->{path}, ':hoge';
    is $node->{is_variable}, 1;
    is scalar @{ $node->{children} }, 1;

    $node = $node->{children}->[0];
    is $node->{path}, '/fuga';
    is $node->{leaf}->{GET}, 1;
}

sub _add_variable_path_shorter : Test(9) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/:hoge/fuga', method => 'GET', args => 1);
    $tree->add('/:hoge', method => 'GET', args => 2);

    my $node = $tree->{children}->[0];
    is $node->{path}, '/';
    is scalar @{ $node->{children} }, 1;

    my $node0 = $node->{children}->[0];
    is $node0->{path}, ':hoge';
    is $node0->{is_variable}, 1;
    is scalar @{ $node0->{children} }, 2;

    my $node00 = $node0->{children}->[0];
    is $node00->{path}, '/fuga';
    is $node00->{leaf}->{GET}, 1;

    my $node01 = $node0->{children}->[1];
    is $node01->{path}, '';
    is $node01->{leaf}->{GET}, 2;
}

sub _add_variable_path_longer : Test(9) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/:hoge', method => 'GET', args => 1);
    $tree->add('/:hoge/fuga', method => 'GET', args => 2);

    my $node = $tree->{children}->[0];
    is $node->{path}, '/';
    is scalar @{ $node->{children} }, 1;

    my $node0 = $node->{children}->[0];
    is $node0->{path}, ':hoge';
    is $node0->{is_variable}, 1;
    is scalar @{ $node0->{children} }, 2;

    my $node00 = $node0->{children}->[0];
    is $node00->{path}, '';
    is $node00->{leaf}->{GET}, 1;

    my $node01 = $node0->{children}->[1];
    is $node01->{path}, '/fuga';
    is $node01->{leaf}->{GET}, 2;
}

sub _add_variable_path_with_re : Test(22) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/:hoge(\d+)', method => 'GET', args => 1);
    $tree->add('/:foo(foo)', method => 'GET', args => 2);
    $tree->add('/:hoge(\d+)/2', method => 'GET', args => 3);
    $tree->add('/:foo(foobar)', method => 'GET', args => 4);

    my $node = $tree->{children}->[0];
    is $node->{path}, '/';
    is scalar @{ $node->{children} }, 3;

    my $node0 = $node->{children}->[0];
    is $node0->{path}, ':hoge';
    is $node0->{is_variable}, 1;
    is $node0->{re}, '\d+';
    is scalar @{ $node0->{children} }, 2;

    my $node00 = $node0->{children}->[0];
    is $node00->{path}, '';
    is $node00->{leaf}->{GET}, 1;

    my $node01 = $node0->{children}->[1];
    is $node01->{path}, '/2';
    is $node01->{leaf}->{GET}, 3;

    my $node1 = $node->{children}->[1];
    is $node1->{path}, ':foo';
    is $node1->{is_variable}, 1;
    is $node1->{re}, 'foo';
    is scalar @{ $node1->{children} }, 1;

    my $node10 = $node1->{children}->[0];
    is $node10->{path}, '';
    is $node10->{leaf}->{GET}, 2;

    my $node2 = $node->{children}->[2];
    is $node2->{path}, ':foo';
    is $node2->{is_variable}, 1;
    is $node2->{re}, 'foobar';
    is scalar @{ $node1->{children} }, 1;

    my $node20 = $node2->{children}->[0];
    is $node20->{path}, '';
    is $node20->{leaf}->{GET}, 4;
}

sub _build : Test(2) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/', method => 'GET', args => 1);
    $tree->add('/hoge', method => 'GET', args => 2);
    $tree->add('/hoge', method => 'POST', args => 3);

    my ($re, $routes) = $tree->build;
    is $re, '\/(?:(?<_0>)|hoge(?<_1>))';
    eq_or_diff $routes, [
        { GET => 1 },
        { GET => 2, POST => 3 },
    ];
}

sub _build_variable : Test(2) {
    my $tree = Router::NC::Tree->new;
    $tree->add('/:number(\d+)', method => 'GET', args => 1);
    $tree->add('/:word', method => 'GET', args => 2);
    $tree->add('/:var', method => 'GET', args => 3);

    my ($re, $routes) = $tree->build({
        var => { re => 'foo|bar' },
    });
    is $re, '\/(?:(?<number>\d+)(?<_0>)|(?<word>[^/]+)(?<_1>)|(?<var>foo|bar)(?<_2>))';
    eq_or_diff $routes, [
        { GET => 1 },
        { GET => 2 },
        { GET => 3 },
    ];
}
