package t::;
use lib qw(lib t/lib);
use strict;
use warnings;

use Encode::Locale ();
use Test::More ();

BEGIN {
    # TAP 出力を utf8
    my @outputs = qw(output failure_output todo_output);
    binmode +Test::More->builder->$_, ':encoding(console_out)' for @outputs;
    my $ORIGINAL_child = \&Test::Builder::child;
    my $child = sub {
        my $builder = $ORIGINAL_child->(@_);
        binmode $builder->$_, ':encoding(console_out)' for @outputs;
        return $builder;
    };

    # Test::Name::FromLine 相当
    my $ORIGINAL_ok = \&Test::Builder::ok;
    my %filecache;
    my $ok = sub {
        # Test::Class が名前なしのテストにメソッド名の名前つけるのを抑制する
        my ($pkg) = caller;
        if ($pkg eq 'Test::Class') {
            require Devel::Caller;
            my (undef, undef, $given_name) = Devel::Caller::caller_args(1);
            $_[2] = undef unless $given_name;
        }

        $_[2] ||= do {
            my ($package, $filename, $lnum) = caller($Test::Builder::Level);
            my $file = $filecache{$filename} ||= do {
                open my $fh, '<:utf8', $filename or die $!;
                [ <$fh> ]
            };
            my $line = $file->[$lnum-1];
            $line =~ s{^\s+|\s+$}{}g;
            "L$lnum: $line";
        };

        goto &$ORIGINAL_ok;
    };

    no warnings 'redefine';
    *Test::Builder::child = $child;
    *Test::Builder::ok = $ok;
}

sub import {
    strict->import;
    utf8->import;
    warnings->import;

    my ($pkg, $file) = caller;

    my $code = qq[
        package $pkg;
        use parent 'Test::Class';
        use Test::More;
        use Test::Fatal;
        use Test::Differences;
    ];

    if ($0 eq $file) {
        $code .= qq[
            END {
                $pkg->runtests;
            }
        ];
    }
    eval $code;
    die $@ if $@;
}

1
__END__
