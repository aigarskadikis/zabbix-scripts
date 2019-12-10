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
my $number = $SN->createTicket();
my $ret = $SN->reassignTicket($number,"Database","Fred Luddy");
ok(defined($ret),'Ticket Reassigned with user');

my $ret1;

$ret1 = $SN->reassignTicket($number,"Database");
ok(defined($ret1),'Ticket Reassigned without user');

$ret1 = undef;

$ret1 = $SN->reassignTicket($number.'xxx');

ok(!defined($ret1), 'Successfully failed to reassign bogus ticket');
1;