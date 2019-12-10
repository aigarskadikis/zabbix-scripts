#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use ServiceNow::ITIL::Ticket;
use Test::Simple tests => 2;
my $CONFIG = ServiceNow::Configuration->new();

print "############### create/insert\n";

print "######## using GlideRecord object\n\n";

my $gr = ServiceNow::GlideRecord->new($CONFIG, "ticket");
$gr->setValue("short_description", "test test test");
$gr->setValue("category", "hardware");
my $sysid = $gr->insert();
print "sys_id = " . $sysid . "\n";
print "number = " . $gr->getValue("number") . "\n";

print "\n######## ServiceNow->createTicket\n";

my $SN = ServiceNow->new($CONFIG);
my $number = $SN->createTicket({"short_description" => "this is the short description", "category" => "hardware"});
ok(defined($number),'Successfuly created a new Ticket');

$gr = ServiceNow::ITIL::Ticket->new($CONFIG);
$gr->insert();

my $gr2 = ServiceNow::ITIL::Ticket->new($CONFIG);
$gr2->insert();

ok($gr->getValue('sys_id') ne $gr2->getValue('sys_id'), 'Successfully created and maintained two copies of Ticket');


1;