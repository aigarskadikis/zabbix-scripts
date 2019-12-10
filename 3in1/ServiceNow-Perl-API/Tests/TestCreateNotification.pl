#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use ServiceNow::ImportSet::Notification;
use Test::Simple tests => 2;

my $CONFIG = ServiceNow::Configuration->new();
#print "######## using GlideRecord object\n\n";
#
#my $gr = ServiceNow::GlideRecord->new($CONFIG, "imp_notification");
#$gr->setValue("message", "test test test");
#$gr->setValue("uuid", "abc123");
#my $sysid = $gr->insert();
#print "sys_id = " . $sysid . "\n";
#print "number = " . $gr->getValue("display_value") . "\n";

print "\n######## ServiceNow->createImpNotification\n";

my $SN = ServiceNow->new($CONFIG);
my @result = $SN->createNotification({"message" => "this is the short description", "uuid" => "abcd1234"});

my $kount = @result; 
for my $i (0 .. ($kount - 1)) {
  my $number = $result[$i]{'display_value'};
  ok(defined($number),'Successfully created Imp Notification: ' . $number);
}


my $gr = ServiceNow::ImportSet::Notification->new($CONFIG);
$gr->insert();

my $gr2 = ServiceNow::ImportSet::Notification->new($CONFIG);
$gr2->insert();

ok($gr->getValue('sys_id') ne $gr2->getValue('sys_id'), 'Successfully created and maintained two copies of RequestedItem');

1;