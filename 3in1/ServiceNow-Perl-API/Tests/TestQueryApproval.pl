#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 2;
my $CONFIG = ServiceNow::Configuration->new();
my $SN = ServiceNow->new($CONFIG);
 my @approvals = $SN->queryApproval({"approver.user_name" => 'fred.luddy'});

 ok(@approvals,'Approval found with query');
  
 foreach my $approval (@approvals) {
      print "Approval for: $approval->{'sysapproval'}\n";
      print "Comments: $approval->{'comments'}\n";
      print "Approver: $approval->{'approver'}\n";
      print "State: $approval->{'state'}\n";
      print "\n"
  }

@approvals = undef;
@approvals = $SN->queryApproval({'approver.user_name' => 'some bogus user name'});

ok(!@approvals, 'Successfully failed to find approval with bogus query');

1;