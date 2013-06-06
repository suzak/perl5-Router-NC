package Router::NC::DSL;
use v5.10;
use strict;
use utf8;
use warnings;

use Carp ();
use Exporter::Lite;  # import;
use Router::NC;

our @METHODS = qw(GET POST PUT DELETE);
our @EXPORT = (qw(route var filter), @METHODS);

our $_var;
our $_filter;
our $_method = { };

sub route (&) {
    my $builder = Router::NC->builder;
    local $_var = sub {
        my ($name, $re, $code) = @_;
        $builder->variable($name, $re, $code);
    };
    my $filter;
    local $_filter = sub { $filter = $_[0] };
    local @$_method{@METHODS} = map {
        my $m = $_;
        sub {
            my ($path, @args) = @_;
            if ($filter) {
                local $Carp::CarpLevel += 1;
                @args = $filter->(@args);
            }
            $builder->route($path, $m, @args);
        }
    } @METHODS;
    $_[0]->();
    return $builder->build;
}

sub var ($$;$) { $_var->(@_) }
sub filter (&) { $_filter->(@_) }
for my $method (@METHODS) {
    no strict 'refs';
    *$method = sub ($@) { goto \&{ $_method->{$method} } };
}
($_var, $_filter, @$_method{@METHODS}) = (sub {
    Carp::croak("var/filter/GET/POST/PUT/DELETE should be called inside router {} block");
}) x (@METHODS + 2);

1;
__END__
