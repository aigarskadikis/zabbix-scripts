#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use Test::Simple tests =>2;
my $CONFIG = ServiceNow::Configuration->new();
my $SN = ServiceNow->new($CONFIG);

my $number = $SN->createIncident({"short_description" => "this is the short description", "category" => "hardware"});
print "number = " . $number . "\n";

my $ret1 = $SN->closeIncident($number, "600");
unless($ret1) {
	print "incident " . $number . " not closed\n";
} else {
	print "incident " . $number . " closed\n";
}


my $ret2;
$ret2 = $SN->reopenIncident($number);

ok(defined($ret2),'Incident sucessfully reopened');

$ret2 = undef;

$ret2 = $SN->reopenIncident($number.'xxx');

ok(!defined($ret2), 'Successfully failed to reopen bogus incident');

1;