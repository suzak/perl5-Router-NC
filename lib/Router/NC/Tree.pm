package Router::NC::Tree;
use v5.10;
use strict;
use utf8;
use warnings;

use Carp ();
use List::Util qw(reduce);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        path        => '',
        children    => [],
        is_variable => 0,
        leaf        => undef,
        %args,
    }, $class;
    return $self;
}

sub _common_prefix ($$) {
    my ($r, $l) = @_;
    my @r = split //, $r;
    my @l = split //, $l;
    my $i = 0;
    $i++ while defined $r[$i] and defined $l[$i] and $r[$i] eq $l[$i];
    substr $r, 0, $i;
}

sub add {
    # %args = ( method, args )
    my ($self, $path, %args) = @_;
    my $original_path = delete $args{original_path} // $path;
    for my $child (@{ $self->{children} }) {
        if ($path eq $child->{path}) {
            if (defined $child->{leaf}) {
                if (exists $child->{leaf}->{ $args{method} }) {
                    Carp::confess "$original_path already has routing for method $args{method}";
                }
                $child->{leaf}->{ $args{method} } = $args{args};
                return;
            }
            $child->add('', %args, original_path => $original_path);
            return;
        }
        my $prefix = _common_prefix $path, $child->{path};
        my $len = length $prefix;
        next if $len == 0;
        my $rest = substr $path, $len;
        my $cpath = substr $child->{path}, $len;
        if ($child->{is_variable}) {
            next if $prefix ne $child->{path};
            if ($rest =~ s/^ \( ([^)]+) \) //x) {
                my $re = $1;
                next if $re ne $child->{re};
                $child->add($rest, %args, original_path => $path);
                return;
            }
        }
        if (defined $child->{leaf} || length $cpath) {
            my $is_variable = $child->{is_variable};
            my $clone = Router::NC::Tree->new(%$child, is_variable => 0, path => $cpath);
            $child = Router::NC::Tree->new(
                path        => $prefix,
                is_variable => $is_variable,
                children    => [ $clone ],
            );
        }
        $child->add($rest, %args, original_path => $path);
        return;
    }

    my $segments = [];
    my $rest = $path;
    while (1) {
        (my $seg, $rest) = split /:/, $rest, 2;
        if (!defined $seg) { # if $seg is undefined, $rest is undefined
            push @$segments, Router::NC::Tree->new(path => '');
        } elsif (length $seg) {
            push @$segments, Router::NC::Tree->new(path => $seg);
        }
        last if !length $rest;
        $rest =~ s/^ ([A-Za-z]\w+) (?: \( ([^)]+) \) )? //x;
        push @$segments, Router::NC::Tree->new(path => ":$1", is_variable => 1) if length $1;
        $segments->[-1]->{re} = $2 if $2;
    }
    $segments->[-1]->{leaf} = { $args{method} => $args{args} };
    push @{ $self->{children} }, reduce { $b->{children} = [$a]; $b; } reverse @$segments;
}

sub build {
    my ($self, $variables, $routes) = @_;
    $routes //= [];
    my $re = '';
    if ($self->{is_variable}) {
        my $var = ($self->{path} =~ s/^://r);
        $re .= "(?<$var>";
        if ($self->{re}) {
            $re .= $self->{re};
        } else {
            $re .= $variables->{$var}->{re} || '[^/]+';
        }
        $re .= ')';
    } else {
        $re = quotemeta $self->{path};
    }
    if (defined $self->{leaf}) {
        my $index = scalar @$routes;
        $re .= "(?<_$index>)";
        push @$routes, $self->{leaf};
    } elsif (my @children = @{ $self->{children} }) {
        $re .= '(?:' if @children > 1;
        $re .= join '|', map {
            my ($re) = $_->build($variables, $routes);
            $re;
        } @children;
        $re .= ')' if @children > 1;
    }
    return ($re, $routes);
}

1;
__END__
