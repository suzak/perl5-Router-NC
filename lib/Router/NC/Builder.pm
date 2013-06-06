package Router::NC::Builder;
use v5.10;
use strict;
use utf8;
use warnings;

use Router::NC::Tree;

sub new {
    my ($class) = @_;
    my $self = bless {
        tree => Router::NC::Tree->new,
        variables => { },
    }, $class;
    return $self;
}

sub variable {
    my ($self, $name, $re, $code) = @_;
    $self->{variables}->{$name} = {
        re   => $re,
        code => $code,
    };
}

sub route {
    my ($self, $path, $method, @args) = @_;
    $self->{tree}->add($path,
        method    => $method,
        args      => \@args,
        variables => $self->{variables},
    );
}

for my $method (qw(get post put delete)) {
    no strict 'refs';
    *$method = sub {
        my ($self, $path, @args) = @_;
        $self->route($path, uc $method, @args);
    };
}

sub build {
    my ($self) = @_;
    my ($re, $routes) = $self->{tree}->build($self->{variables});

    require Router::NC;
    my $router = Router::NC->new(
        re        => qr<^$re$>msx,
        routes    => $routes,
        variables => { map {
            $_ => $self->{variables}->{ $_ }->{code},
        } keys %{ $self->{variables} } },
    );
    return $router;
}

1;
__END__
