#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use Test::Simple tests => 2;
my $CONFIG = ServiceNow::Configuration->new();
my $SN = ServiceNow->new($CONFIG);

my $number = $SN->createTask({"short_description" => "this is the short description"});
print "number = " . $number . "\n";

my $ret1 = $SN->closeTask($number);
unless($ret1) {
	print "task " . $number . " not closed\n";
} else {
	print "task " . $number . " closed\n";
}

my $ret2;
$ret2 = $SN->reopenTask($number);

ok(defined($ret2),'Task successfully reopened');

$ret2 = undef;

$ret2 = $SN->reopenTask($number.'xxx');

ok(!defined($ret2), 'Successfully failed to reopen bogus task');


1;