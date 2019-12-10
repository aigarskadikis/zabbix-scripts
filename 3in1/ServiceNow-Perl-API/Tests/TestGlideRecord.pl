#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 1;

my $CONFIG = ServiceNow::Configuration->new();

print "############### create/insert\n";

print "######## using GlideRecord object\n\n";

my $gr = ServiceNow::GlideRecord->new($CONFIG, "incident");
my $sysid = $gr->insert();
print "sys_id = " . $sysid . "\n";
print "gr1 number = " . $gr->getValue("sys_id") . "\n";

my $gr2 = ServiceNow::GlideRecord->new($CONFIG, "incident");

$sysid = $gr2->insert();
print "sys_id = " . $sysid . "\n";
print "gr2 number = " . $gr2->getValue("sys_id") . "\n";

print "gr1 number = " . $gr->getValue("sys_id") . "\n";

ok($gr2->getValue("sys_id") ne $gr->getValue("sys_id"), 'Successfully Created and maintained two copies of Glide Record.');






1;