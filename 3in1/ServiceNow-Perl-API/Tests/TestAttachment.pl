#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::Attachment;
use ServiceNow::WSResult;
use ServiceNow::ITIL::Incident;
use Test::Simple tests => 3;

my $CONFIG = ServiceNow::Configuration->new();
my $attachment = ServiceNow::Attachment->new($CONFIG);
my $sysid = $attachment->create("/Users/davidloo/Desktop/test_files/number_test.xls", "incident", "9d385017c611228701d22104cc95c371");
ok(defined($sysid), 'attachment successfully created');

my $incident = ServiceNow::ITIL::Incident->new($CONFIG);
$incident->setValue("short_description", "test incident for attachment");
my $inc_sys_id = $incident->insert();
$sysid = $attachment->create("/Users/davidloo/Desktop/test_files/number_test.xls", "incident", $inc_sys_id);
ok(defined($sysid), 'attachment successfully created 2');

$incident = ServiceNow::ITIL::Incident->new($CONFIG);
$incident->setValue("short_description", "test incident for attachment 2");
$incident->insert();
$sysid = $incident->attach("/Users/davidloo/Desktop/test_files/number_test.xls");
ok(defined($sysid), 'attachment successfully created 3');

1;