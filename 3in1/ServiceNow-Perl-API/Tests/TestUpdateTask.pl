#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 2;

my $CONFIG = ServiceNow::Configuration->new();

print "\n###############update\n";

print "\n######## using GlideRecord object\n\n";


my $SN = ServiceNow->new($CONFIG);
my $number = $SN->createTask();
my $ret = $SN->updateTask($number, {"short_description" => "from ServiceNow->updateTask"});
ok(defined($ret), 'Task successfully updated');

$ret = undef;

$ret = $SN->updateTask($number.'xx');

ok(!defined($ret), 'Task successfully failed to update bogus task');

1;