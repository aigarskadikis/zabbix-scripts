#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 3;

my $CONFIG = ServiceNow::Configuration->new();
my $SN = ServiceNow->new($CONFIG);
my $ret = $SN->approve('c4230f8e0a0a0b12003a06b1cb20e2cd', 'Approved','test');
ok($ret eq 'c4230f8e0a0a0b12003a06b1cb20e2cd', 'Approval successfully changed to Approved');

$ret ='';
$ret = $SN->approve('c4230f8e0a0a0b12003a06b1cb20e2cd', 'REJECTED','test');
ok($ret eq 'c4230f8e0a0a0b12003a06b1cb20e2cd', 'Approval successfully changed to REJECTED');

$ret = undef;

$ret = $SN->approve('zxcv', 'Approved', 'test');

ok(!defined($ret), 'Successfully failed to approve bogus approval');

my $test = 1;

if($test) {
	print 'hey';
}

1;