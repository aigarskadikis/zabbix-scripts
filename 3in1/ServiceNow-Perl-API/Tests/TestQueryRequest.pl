
#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 2;
my $CONFIG = ServiceNow::Configuration->new();


print "\n######## ServiceNow->queryRequest\n\n";

my $SN = ServiceNow->new($CONFIG);
my $gr;
$gr = ServiceNow::GlideRecord->new($CONFIG, "sc_request");
$gr->insert();
my $number = $gr->getValue('number');


my @requests = $SN->queryRequest({'number' => $number}); 


  foreach my $request (@requests) {
      print "Request number:       $request->{'number'}\n";
      print "Request state:        $request->{'request_state'}\n";
      print "Assigned to:          $request->{'assigned_to'}\n";
      print "Special instructions: $request->{'special_instructions'}\n";
      print "\n"
  }

ok(@requests, 'Successfully queried a request');
@requests = $SN->queryRequest({'number' => $number .'xxx'});

ok(!@requests, 'Successfully failed to query a bogus request'); 

1;