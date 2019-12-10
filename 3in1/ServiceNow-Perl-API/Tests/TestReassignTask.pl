#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 3;
my $CONFIG = ServiceNow::Configuration->new();

print "\n###############reassign\n";

print "\n######## using GlideRecord object\n\n";

my $SN = ServiceNow->new($CONFIG);
my $number = $SN->createTask();
my $ret = $SN->reassignTask($number,"Database","Fred Luddy");
ok(defined($ret), 'Task reassigned with user');

my $ret1;
$ret1 = $SN->reassignTask($number,"Database");
ok(defined($ret1),'Task reassigned without user');

$ret1 = undef;

$ret1 = $SN->reassignTask($number.'xxx');

ok(!defined($ret1), 'Successfully failed to reassign bogus Task');

1;