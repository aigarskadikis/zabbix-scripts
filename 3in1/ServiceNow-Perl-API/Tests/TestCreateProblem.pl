#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use ServiceNow::ITIL::Task;
use ServiceNow::ITIL::SC_Task;
use Test::Simple tests => 3;

my $CONFIG = ServiceNow::Configuration->new();

print "############### create/insert\n";

print "######## using GlideRecord object\n\n";

my $gr = ServiceNow::GlideRecord->new($CONFIG, "sc_task");
$gr->setValue("short_description", "test test test");
$gr->setValue("category", "hardware");
my $sysid = $gr->insert();
print "sys_id = " . $sysid . "\n";
print "number = " . $gr->getValue("number") . "\n";

print "\n######## ServiceNow->createTask\n";

my $SN = ServiceNow->new($CONFIG);
my $number = $SN->createTask({"short_description" => "this is the short description", "category" => "hardware"});
ok(defined($number),'Successfully created a new task');

$gr = ServiceNow::ITIL::Task->new($CONFIG);
$gr->insert();

my $gr2 = ServiceNow::ITIL::Task->new($CONFIG);
$gr2->insert();

ok($gr->getValue('sys_id') ne $gr2->getValue('sys_id'), 'Successfully created and maintained two copies of Task');

$gr = ServiceNow::ITIL::SC_Task->new($CONFIG);
$gr->insert();

$gr2 = ServiceNow::ITIL::SC_Task->new($CONFIG);
$gr2->insert();

ok($gr->getValue('sys_id') ne $gr2->getValue('sys_id'), 'Successfully created and maintained two copies of SC_Task');
1;