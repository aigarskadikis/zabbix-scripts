#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 4;

my $CONFIG = ServiceNow::Configuration->new();


my $SN = ServiceNow->new($CONFIG);
my $number = $SN->createRequestedItem('BlackBerry', "fred.luddy", {'description' => 'Some description', 'group' => 'SOME_GROUP'});

ok(defined($number),'Successfully created new Requested Item');

my @requestedItem = $SN->queryRequestedItem({number => $number});

my $requestNumber = $requestedItem[0]->{'request'};

ok(defined($requestNumber), 'Successfully created new Request: ' . $requestNumber);

@requestedItem = undef;
@requestedItem = $SN->queryRequestedItem({number => $number.'xxx'});

$requestNumber = $requestedItem[0]->{'request'};

ok(!defined($requestNumber), 'Successfully fail to find bogus Request');

$gr = ServiceNow::ITIL::RequestedItem->new($CONFIG);
$gr->insert();

my $gr2 = ServiceNow::ITIL::RequestedItem->new($CONFIG);
$gr2->insert();

ok($gr->getValue('sys_id') ne $gr2->getValue('sys_id'), 'Successfully created and maintained two copies of RequestedItem');


1;