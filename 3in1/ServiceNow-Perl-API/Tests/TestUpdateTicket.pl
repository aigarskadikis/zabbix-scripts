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
my $number = $SN->createTicket({"short_description" => "this is the short description", "category" => "hardware"});
print "number = " . $number . "\n";

$gr = ServiceNow::GlideRecord->new($CONFIG, "ticket");
$gr->addQuery("number", $number);
$gr->query();
if ($gr->next() eq TRUE) {
	$gr->setValue("short_description", "from GlideRecord");
	my $ss = $gr->update();
	print "ticket " . $ss . " updated\n";
}

print "\n######## ServiceNow->updateIncident\n\n";

my $ret = $SN->updateTicket($number, {"short_description" => "from ServiceNow->updateIncident"});

ok(defined($ret), 'Ticket Successfully updated');

$ret = undef;

$ret = $SN->updateTicket($number.'xxx',{"short_description" => "from ServiceNow->updateIncident"});

ok(!defined($ret), 'Successfully failed to update bogus ticket');


1;