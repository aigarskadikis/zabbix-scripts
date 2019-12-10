#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 2;

my $CONFIG = ServiceNow::Configuration->new();

my $SN = ServiceNow->new($CONFIG);
my $number = $SN->createTask({"short_description" => "this is the short description", "category" => "hardware"});
print "number = " . $number . " created\n";

my $ret1 = $SN->closeTask($number, {"comments" => "closing incident"});

ok(defined($ret1),'task '. $number. '  closed');

$ret1 = undef;

$SN->closeTask($number.'xxx');
ok(!defined($ret1), 'Successfully failed to close bogus task');
1;