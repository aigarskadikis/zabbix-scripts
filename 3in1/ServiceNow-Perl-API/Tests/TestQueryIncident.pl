#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests =>2;
my $CONFIG = ServiceNow::Configuration->new();

print "\n############### query\n";

print "\n######## using GlideRecord object\n\n";

$gr = ServiceNow::GlideRecord->new($CONFIG, "incident");
$gr->addQuery("number", "INC0010175");
#$gr->addQuery("assignment_group", "Service Desk");
#$gr->addQuery("category", "Hardware");
#$gr->addQuery("number", "XXX");
$gr->query();
while($gr->next()) {
	print "number=" . $gr->getValue("number") . "\n";
	print "sd=" . $gr->getValue("short_description") . "\n";
	print "opened_by Display Value= " . $gr->getDisplayValue("opened_by") . "\n";
	print "opened_by sys_id= " . $gr->getValue('opened_by');
}

print "\n######## ServiceNow->queryIncident\n\n";

my $SN = ServiceNow->new($CONFIG);
#my @incidents = $SN->queryIncident({'assignment_group' => 'Service Desk'});
#my @incidents = $SN->queryIncident({'category' => 'Hardware'});
my $number = $SN->createIncident();
my @incidents = $SN->queryIncident({'number' => $number});
my $count = scalar(@incidents); 
print "number of incidents=" . $count . "\n";
foreach my $incident (@incidents) {
    print "Incident number: $incident->{'number'}\n";
    print "Assignent Group: $incident->{'assignment_group'}\n";
    print "Opened by:       $incident->{'opened_by'}\n";
    print "Opened by DV:    $incident->{'dv_opened_by'}\n";
    print "SD:       $incident->{'short_description'}\n";
    print "TW:       $incident->{'time_worked'}\n";
    print "\n"
}
ok($incidents[0]->{'number'} eq $number,'query of incident successful');

@incident = undef;
@incident = $SN->queryIncident({'number' => $number.'xxx'});

ok(!@incident, 'Successfully failed to find Incident with bogus query');

1;