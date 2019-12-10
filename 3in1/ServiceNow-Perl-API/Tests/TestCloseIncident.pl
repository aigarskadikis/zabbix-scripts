#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 2;

my $CONFIG = ServiceNow::Configuration->new();

my $SN = ServiceNow->new($CONFIG);
my $number = $SN->createIncident({"short_description" => "this is the short description", "category" => "hardware"});
print "number = " . $number . " created\n";

my $ret1 = $SN->closeIncident($number, {"comments" => "closing incident"});

ok(defined($ret1),'incident ' . $number . " closed");

$ret1 = undef;

$ret1 = $SN->closeIncident($number.'xx');

ok(!defined($ret1),'Successfully failed to close bogus incident');


1;