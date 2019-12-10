use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ServiceNow',
    AUTHOR              => q{davidloo <david.loo@service-now.com>},
    VERSION_FROM        => 'lib/ServiceNow.pm',
    ABSTRACT_FROM       => 'lib/ServiceNow.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ServiceNow-*' },
);
