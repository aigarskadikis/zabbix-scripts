#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 2;
my $CONFIG = ServiceNow::Configuration->new();

print "\n###############update\n";

print "\n######## using GlideRecord object\n\n";

$gr = ServiceNow::GlideRecord->new($CONFIG, "incident");
$gr->addQuery("number", "INC0000055");
$gr->query();
if ($gr->next() eq TRUE) {
	$gr->setValue("short_description", "from GlideRecord");
	my $ss = $gr->update();
	print "incident " . $ss . " updated\n";
}

print "\n######## ServiceNow->updateIncident\n\n";

my $SN = ServiceNow->new($CONFIG);
$number = $SN->createIncident();
my $ret = $SN->updateIncident($number, {"short_description" => "from ServiceNow->updateIncident"});

ok(defined($ret), 'Incident successfully updated');

$ret = undef;

$ret = $SN->updateIncident($number.'xxx');

ok(!defined($ret), 'Successfully failed to update bogus incident');

1;