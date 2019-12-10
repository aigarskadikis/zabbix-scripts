#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 2;


my $CONFIG = ServiceNow::Configuration->new();
my $SN = ServiceNow->new($CONFIG);
my @journals = $SN->queryJournal('INC0010023');

ok(@journals,'Found Journal and Incident');

@journals = undef;

@journals = $SN->queryJournal('INCxxxxx');

ok(!defined($journals[0]), 'Successfully failed to find Journal with bogus query');

1;