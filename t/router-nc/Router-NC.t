package t::Router::NC;
use t::;

sub _require : Test(startup => 1) {
    require_ok 'Router::NC';
}

sub _builder : Test(1) {
    my $builder = Router::NC->builder;
    isa_ok $builder, 'Router::NC::Builder';
}

sub _new : Test(1) {
    my $router = Router::NC->new;
    isa_ok $router, 'Router::NC';
}

sub _match : Test(8) {
    my $builder = Router::NC->builder;
    $builder->get('/', 1);
    $builder->post('/', 2);
    $builder->get('/var/:var', 3);
    $builder->variable(int => '[0-9]+', sub { $_ + 0 });
    $builder->get('/int/:int', 4);
    my $router = $builder->build;

    for (
        [ 'GET', '/', '', 200, { }, 1 ],
        [ 'HEAD', '/', '', 200, { }, 1 ],
        [ 'POST', '/', '', 200, { }, 2 ],
        [ 'DELETE', '/', '', 405 ],
        [ 'GET', '/var/12345', '', 200, { var => '12345' }, 3 ],
        [ 'GET', '/int/12345', '', 200, { int => 12345 }, 4 ],
        [ 'GET', '/not_found', '', 404 ],
        [ 'GET', '/hoge/', '/hoge', 200, { }, 1 ],
    ) {
        my ($method, $uri, $script_name, @expected) = @$_;
        my @got = $router->match({
            REQUEST_METHOD => $method,
            REQUEST_URI    => $uri,
            SCRIPT_NAME    => $script_name,
        });
        eq_or_diff [@got], [@expected];
    }
}
