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
my $number = $SN->createIncident();

my $ret1;
$ret1 = $SN->reassignIncident($number,"Database");
ok(defined($ret1), 'Reassigned incident without user');


my $ret = $SN->reassignIncident($number,"Database","Fred Luddy");
ok(defined($ret) , 'Reassigned incident with user');

$ret = undef;

$ret = $SN->reassignIncident($number.'xx');

ok(!defined($ret),'Successfully failed to reassign bogus Incident');



1;