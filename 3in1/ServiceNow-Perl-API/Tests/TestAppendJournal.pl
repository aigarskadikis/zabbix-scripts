#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 1;

my $CONFIG = ServiceNow::Configuration->new();
my $SN = ServiceNow->new($CONFIG);
my $number = $SN->createIncident({"short_description" => "this is the short description", "category" => "hardware"});
my $journal = $SN->appendJournal($number,'comments','we know this works but it isnt shown in gui');
ok($journal, 'Journal successfully created');

1;