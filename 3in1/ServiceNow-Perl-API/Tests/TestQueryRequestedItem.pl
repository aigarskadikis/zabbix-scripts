
#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 2;
my $CONFIG = ServiceNow::Configuration->new();

print "\n############### query\n";

print "\n######## using GlideRecord object\n\n";

$gr = ServiceNow::GlideRecord->new($CONFIG, "sc_req_item");
$gr->addQuery("number", "RITM0000002");
#$gr->addQuery("assignment_group", "Service Desk");
#$gr->addQuery("category", "Hardware");
#$gr->addQuery("number", "XXX");
$gr->query();
while($gr->next() eq TRUE) {
	print "number=" . $gr->getValue("number") . "\n";
	print "sd=" . $gr->getValue("short_description") . "\n";
}

print "\n######## ServiceNow->queryRequestedItem\n\n";

my $SN = ServiceNow->new($CONFIG);
my @reqItems = $SN->queryRequestedItem({'number' => 'RITM0000002'});
ok(@reqItems, 'Found Requested Item with Query');
my $count = scalar(@reqItems); 
print "number of Requested Items=" . $count . "\n";
foreach my $reqItem (@reqItems) {
    print "Requested Item number: $reqItem->{'number'}\n";
    print "Assigned to: $reqItem->{'assigned_to'}\n";
    print "\n";
}
@reqItems = undef;

@reqItems = $SN->queryRequestedItem({'number' => 'RITMxxxxx'});
ok(!@reqItems,'Successfully failed to find Requested Item with bogus query');
1;