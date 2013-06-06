package Router::NC;
use v5.10;
use strict;
use utf8;
use warnings;

use Router::NC::Builder;

sub builder {
    my ($class) = @_;
    my $builder = Router::NC::Builder->new;
    return $builder;
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        re        => $args{re},
        routes    => $args{routes},
        variables => $args{variables},
    }, $class;
    return $self;
}

sub match {
    my ($self, $env) = @_;
    local $env->{REQUEST_METHOD} = $env->{REQUEST_METHOD} eq 'HEAD' ? 'GET' : $env->{REQUEST_METHOD};
    my ($path_info) = ($env->{REQUEST_URI} =~ qr/^@{[ $env->{SCRIPT_NAME} || '' ]}(.*?)(?:\?.*)?$/);
    $path_info =~ $self->{re};
    my $index;
    my $match = { };
    for my $key (keys %+) {
        if ($key =~ /^_(\d+)$/) {
            die if defined $index;
            $index = $1 + 0;
            next
        }
        my $code = $self->{variables}->{ $key };
        local $_ = $+{ $key };
        $match->{ $key } = $code ? $code->() : $_;
    }
    return (404) unless defined $index;
    my $route = $self->{routes}->[ $index ];
    return (500) unless $route;
    $route = $route->{ $env->{REQUEST_METHOD} };
    return (405) unless $route;
    return (200, $route, $match);
}

1;
__END__
