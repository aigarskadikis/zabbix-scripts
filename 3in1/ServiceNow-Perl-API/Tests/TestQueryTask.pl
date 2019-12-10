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

my $number = $SN->createTask({"short_description" => "this is the short description"});
print "number = " . $number . "\n";

$gr = ServiceNow::GlideRecord->new($CONFIG, "sc_task");
$gr->addQuery("number", $number);
$gr->query();
while($gr->next() eq TRUE) {
	print "number=" . $gr->getValue("number") . "\n";
	print "sd=" . $gr->getValue("short_description") . "\n";
}

print "\n######## ServiceNow->queryTask\n\n";


my @tasks = $SN->queryTask({'number' => $number});
my $count = scalar(@tasks); 
print "number of tasks=" . $count . "\n";
foreach my $task (@tasks) {
    print "Incident number: $task->{'number'}\n";
    print "Assignent Group: $task->{'assignment_group'}\n";
    print "Opened by:       $task->{'opened_by'}\n";
    print "SD:       $task->{'short_description'}\n";
    print "TW:       $task->{'time_worked'}\n";
    print "\n"
}

ok($tasks[0]->{'number'} eq $number,'Successfully queried task');

@tasks = undef;

@tasks = $SN->queryTask({'number' => $number.'xxxx'});

ok(!@tasks, 'Successfully failed to find Task with bogus query');
1;