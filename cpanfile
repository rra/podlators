requires 'Pod::Simple', '3.26';

on 'test' => sub {
    requires 'JSON::PP';
    requires 'Perl6::Slurp';
    requires 'Perl::Critic';
    requires 'Test::CPAN::Changes';
    requires 'Test::Kwalitee';
    requires 'Test::MinimumVersion';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Spelling';
    requires 'Test::Strict';
    requires 'Test::Synopsis';
};
