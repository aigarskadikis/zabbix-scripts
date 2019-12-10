#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 4;
my $CONFIG = ServiceNow::Configuration->new();
my $CONFIG2 = ServiceNow::Configuration->new();

print "############### create/insert\n";

print "######## using GlideRecord object\n\n";

my $gr = ServiceNow::GlideRecord->new($CONFIG, "incident");
$gr->setValue("short_description", "test test test");
$gr->setValue("category", "hardware");
my $sysid = $gr->insert();
print "sys_id = " . $sysid . "\n";
print "number = " . $gr->getValue("number") . "\n";
my $gr2 = ServiceNow::GlideRecord->new($CONFIG2, "incident");
$gr2->setValue("short_description", "test test test");
$gr2->setValue("category", "hardware");
$sysid = $gr2->insert();

print "number2 = " . $gr2->getValue("number") . "\n";
print "number = " . $gr->getValue("number") . "\n";
 
print "\n######## ServiceNow->createIncident\n";

my $SN = ServiceNow->new($CONFIG);

my $number = $SN->createIncident({"short_description" => "this is the short description", "category" => "hardware"});

my $number2 = $SN->createIncident({"short_description" => "this is the short description", "category" => "hardware"});

print $number ." and ". $number2 ."\n";
ok (defined($number), 'Incident successfully created');
$gr = ServiceNow::ITIL::Incident->new($CONFIG);
$gr->insert();

$gr2 = ServiceNow::ITIL::Incident->new($CONFIG);
$gr2->insert();

ok($gr->getValue('sys_id') ne $gr2->getValue('sys_id'), 'Successfully created and maintained two copies of Incident');

my $psysid = $gr2->createProblem();
#print $psysid;
ok(defined($psysid), 'Successfully created problem from incident');

my $csysid = $gr->createChange();
#print $csysid;
ok(defined($csysid), 'Successfully created change from incident');

1;