#!/usr/bin/perl -w

use Test::More tests => 1;

BEGIN {
    use_ok( 'ServiceNow' ) || print "Bail out!
";
}

diag( "Testing ServiceNow $ServiceNow::VERSION, Perl $], $^X" );
