#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 2;
my $CONFIG = ServiceNow::Configuration->new();

print "\n############### query\n";

print "\n######## using GlideRecord object\n\n";
my $SN = ServiceNow->new($CONFIG);

my $number = $SN->createTicket({"short_description" => "this is the short description"});
print "number = " . $number . "\n";

$gr = ServiceNow::GlideRecord->new($CONFIG, "ticket");
$gr->addQuery("number", $number);
#$gr->addQuery("assignment_group", "Service Desk");
#$gr->addQuery("category", "Hardware");
#$gr->addQuery("number", "XXX");
$gr->query();
while($gr->next() eq TRUE) {
	print "number=" . $gr->getValue("number") . "\n";
	print "sd=" . $gr->getValue("short_description") . "\n";
}

print "\n######## ServiceNow->queryTicket\n\n";

#my @tickets = $SN->queryTicket({'assignment_group' => 'Service Desk'});
#my @tickets = $SN->queryTicket({'category' => 'Hardware'});
my @tickets = $SN->queryTicket({'number' => $number});
my $count = scalar(@tickets); 
print "number of tickets=" . $count . "\n";
foreach my $ticket (@tickets) {
    print "Ticket number: $ticket->{'number'}\n";
    print "Assignent Group: $ticket->{'assignment_group'}\n";
    print "SD:       $ticket->{'short_description'}\n";
    print "\n"
}

ok($tickets[0]->{'number'} eq $number,'Successfully queried a Ticket');

@tickets = undef;

@tickets = $SN->queryTicket({'number' => $number.'xxxx'});

ok(!@tickets,'Successfully failed to find ticket with bogus query');
1;