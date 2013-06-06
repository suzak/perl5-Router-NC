requires 'Carp';
requires 'Exporter::Lite';
requires 'List::Util';

on test => sub {
    requires 'Devel::Caller';
    requires 'Encode::Locale';
    requires 'Test::Builder';
    requires 'Test::Class';
    requires 'Test::Differences';
    requires 'Test::Fatal';
    requires 'Test::More';
    requires 'parent';
};
