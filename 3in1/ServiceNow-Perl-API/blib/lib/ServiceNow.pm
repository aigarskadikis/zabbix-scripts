# ======================================================================
#
#   Copyright 2010 davidloo Service-now.com
#   Copyright 2015 Daniel Hernández Cassel
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# ======================================================================

package ServiceNow;

use ServiceNow::ITIL::Dictionary;
use ServiceNow::ITIL::Incident;
use ServiceNow::ITIL::Ticket;
use ServiceNow::ITIL::RequestedItem;
use ServiceNow::ITIL::Request;
use ServiceNow::ITIL::SC_Task;
use ServiceNow::ITIL::Approval;
use ServiceNow::ImportSet::Notification;

$VERSION = '1.00';
my $CONFIG;
my $INSTANCE_ID;

=pod

=head1 ServiceNow module

Service-now Perl API - ServiceNow perl module

=head1 Desciption

ServiceNow module is a collection of Perl subroutines that provides convenient and direct access to the Service-now platform

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=head1 Constructor

=head3 new

new(Configuration object, optional Instance ID)

Example:

  $config = ServiceNow::Configuration->new();
  $SN = ServiceNow->new($config);
    
Sets up an instance of the ServiceNow object using a Configuration object and an optional Instance ID.

=cut

sub new {
  my ($class, $conf, $id) = (shift, shift, shift);
  my $me = {};
  
  # setting globals
  $CONFIG = $conf;
  $INSTANCE_ID = $id;
  bless($me,$class);
  return $me;
}

# ======================================================================
#
# private subroutines, usually not publically accessible
#
# ======================================================================

sub _query {
  my ($me, $target, $params) = (shift, shift, shift);
  my @results;
  
  my $count = 0;
  $target->query($params);
  while($target->next()) {
    my %record = $target->getRecord();
    foreach my $key (keys %record) {
      $results[$count]{$key} = $record{$key};
    }
    
    $count++;
  }
  
  return @results;
}

sub _update {
  my ($me, $target, $number, $params) = (shift, shift, shift, shift);
  
  $target->addQuery("number", $number);
  $target->query();
  if ($target->next()) {
	my $ss = $target->update($params);
	return $ss;
  }
  
  return undef;
}

sub _close {
	my ($me, $target, $number, $secs) = (shift, shift, shift, shift);
	
	if (defined($secs)) {
	  $secs = "00:00:" . $secs;
      return $target->close($number, {"time_worked" => $secs});
	} else {
      return $target->close($number);		
	}
}

# ======================================================================
#
# Incident related functions
#
# ======================================================================

=head1 Subroutines

=head2 Incident

=head3 createIncident

createIncident(optional paramaters)

Example:

  $number = $SN->createIncident({"short_description" => "this is the short description"});
   
Create an incident.
Returns an incident number upon success. On failure returns undef. 

=cut

sub createIncident {
  my ($me, $params) = (shift, shift);
  
  #my $incident = ServiceNow::ImportSet::ImpIncident->new($CONFIG);
  my $incident = ServiceNow::ITIL::Incident->new($CONFIG);
  return $incident->create($params);
}

=head3 queryIncident

queryIncident(Reference to named parameters hash of Incident fields and exact values)

Example:

  @results = $SN->queryIncident({'number' => 'INC0000054'});
 
Query for Incidents matching specified criteria.    
Returns an array of incident records.

=cut

sub queryIncident {
  my ($me, $params) = (shift, shift);
  
  my $target = ServiceNow::ITIL::Incident->new($CONFIG);;
  return $me->_query($target, $params);
}

=head3 updateIncident

updateIncident($number, optional hash of Incident fields and values to update)

Example:

  $ret = $SN->updateIncident($number,{$field => $value});
   
Update a ServiceNow incident 
Returns undef on failure, all other values indicate success.

=cut

sub updateIncident {
  my ($me, $number, $params) = (shift, shift, shift);
  
  my $target = ServiceNow::ITIL::Incident->new($CONFIG);;
  return $me->_update($target, $number, $params);
}

=head3 closeIncident

closeIncident(incident number, optional hash of Incident fields and values to update)

Example:

  $number = $SN->closeIncident($number, {$field => $value});
   
Close a ServiceNow Incident and optionally specify work effort. 
Returns the incident number on success, undef on failure.

=cut

sub closeIncident {
	my ($me, $number, $params) = (shift, shift, shift);
	
  my $target = ServiceNow::ITIL::Incident->new($CONFIG);;
  return $me->_close($target, $number, $params);
}

=head3 reopenIncident

reopenIncident(incident number)

Example:

  my $ret = $SN->reopenIncident('INC99999');
   
Reopen a closed ServiceNow incident.
Returns the incident number on success, undef on failure.

=cut

sub reopenIncident {
	my ($me, $number) = (shift, shift);
	
	my $incident = ServiceNow::ITIL::Incident->new($CONFIG);	
    return $incident->reopen($number);
}

=head3 reassignIncident

reassignIncident(Incident number, assignment group, optional assigned to)

Example:

  my $ret = $SN->reassignIncident('INC99999', 'SOME_GROUP');
  my $ret = $SN->reassignIncident('INC99999', 'SOME_GROUP', 'username');
   
Reassign a ServiceNow Incident to a new assignment_group.(and optionally specify an assigned_to)
Returns the incident number on success, undef on failure.

=cut

sub reassignIncident {
  my ($me,$number,$group,$user) = (shift,shift,shift,shift);
  $incident = ServiceNow::ITIL::Incident->new($CONFIG);
  $incident->addQuery("number",$number);
  $incident->query();
  if ($incident->next()) {
  	 return $incident->reassign($number,$group,$user);
  }
  return undef;
}

# ======================================================================
#
# Ticket related functions
#
# ======================================================================

=head2 Ticket

=head3 createTicket

createTicket(Reference to named parameters hash of ticket fields and values)

Example:

  my $number = $SN->createTicket({"category" => "hardware"});
   
Create a ServiceNow ticket associated with an incident.
Returns a ticket number upon success. On failure returns undef.

=cut

sub createTicket {
  my ($me, $params) = (shift, shift);
  my $incident = ServiceNow::ITIL::Ticket->new($CONFIG);
  return $incident->create($params);
}

=head3 updateTicket

updateTicket(The ticket number , Reference to named parameters hash of ticket fields and values to update)

Example:

  my $ret = $SN->updateTicket($number, {$field => $value});

Returns undef on failure, all other values indicate success.

=cut

sub updateTicket {
  my ($me, $number, $params) = (shift, shift, shift);
  
  my $target = ServiceNow::ITIL::Ticket->new($CONFIG);;
  return $me->_update($target, $number, $params);
}

=head3 queryTicket

queryTicket( Reference to named parameters hash of Incident fields and exact values )

Example:

  my @tickets = $SN->queryTicket({'number' => $number});

Query for tickets matching specified criteria.
Reference to array of hashes of all matching tickets, undef on failure or if no records found. 

=cut

sub queryTicket {
  my ($me, $params) = (shift, shift);
  
  my $target = ServiceNow::ITIL::Ticket->new($CONFIG);;
  return $me->_query($target, $params);
}

=head3 closeTicket

closeTicket(Ticket number, {$field => $value})

Example:

  my $ret = $SN->closeTicket($number);
  my $ret = $SN->closeTicket($number, {"comments" => "ticket closed"});
   
Close a ServiceNow ticket and optionally specify work effort.
Returns the ticket number on success, undef on failure.

=cut

sub closeTicket {
	my ($me, $number, $params) = (shift, shift, shift);
	
  my $target = ServiceNow::ITIL::Ticket->new($CONFIG);;
  return $me->_close($target, $number, $params);
}

=head3 reopenTicket

reopenTicket(The ticket number)

Example:

  my $ret = $SN->reopenTicket('TKT99999');
   
Reopen a closed ServiceNow ticket.
Returns the ticket number on success, undef on failure.

=cut

sub reopenTicket {
	my ($me, $number) = (shift, shift);
	
	my $ticket = ServiceNow::ITIL::Ticket->new($CONFIG);	
    return $ticket->reopen($number);
}

=head3 reassignTicket

reassignTicket(ticket number, the incident assignment group, optional person to assign the ticket to)

Example:

  my $ret = $SN->reassignTicket('TKT99999', 'SOME_GROUP');
  my $ret = $SN->reassignTicket('TKT99999', 'SOME_GROUP', 'username');
   
Reassign a ServiceNow ticket to a new assignment_group.
Returns the ticket number on success, undef on failure.

=cut

sub reassignTicket {
  my ($me,$number,$group,$user) = (shift,shift,shift,shift);
  $ticket = ServiceNow::ITIL::Ticket->new($CONFIG);
  $ticket->addQuery("number",$number);
  $ticket->query();
  if ($ticket->next()) {
  	 return $ticket->reassign($number,$group,$user);
  }
  return undef;
}

#=============================================================================
#
# Requested Item Related Functions
#
#=============================================================================

=head2 RequestedItem / Request

=head3 createRequestedItem

createRequestedItem(catalog item number, requested for, variables)

Example: 

  my $req = $SN->createRequestedItem('CITM10000', "username", {'description' => 'Some description', 'group' => 'SOME_GROUP'});
   
Create a Service Catalog RequestedItem (and indirectly the associated Request and Tasks). 
Returns a RequestedItem number upon success. On failure returns undef.

=cut

sub createRequestedItem {
  my ($me, $name,$user,$params) = (shift, shift,shift,shift);
  my $req = ServiceNow::ITIL::Request->new($CONFIG);
  my $num = $req->create({'requested_for' => $user});
  my $reqItem = ServiceNow::ITIL::RequestedItem->new($CONFIG);
  $params->{'cat_item'}=$name;
  $params->{'request'} = $num;
  my $number = $reqItem->create($params);
  
  return $number;
}

=head3 queryRequestedItem

queryRequestedItem(Reference to named parameters hash of RequestedItem fields and exact values)

Example:

  my $requestedItems = $SN->queryRequestedItem({'number' => 'SOME_RI_NUMBER'});
   
Query for RequestedItems matching specified criteria.
Reference to array of hashes of all matching RequestedItem, undef on failure or if no records found.

=cut

sub queryRequestedItem {
  my ($me, $params) = (shift, shift);
  
  my $target = ServiceNow::ITIL::RequestedItem->new($CONFIG);
  return $me->_query($target, $params);
}

=head3 queryRequest

queryRequest(Reference to named parameters hash of Request fields and exact values)

Example:

  my $requests = $SN->queryRequest({'number' => 'SOME_REQUEST_NUMBER'});
   
Query for Requests matching specified criteria.
Reference to array of hashes of all matching Request, undef on failure or if no records found.

=cut

sub queryRequest {
	my ($me, $params) =(shift,shift);
	
	my $target = ServiceNow::ITIL::Request->new($CONFIG);
	return $me->_query($target, $params);
}

#=============================================================================
#
# Task Related Functions
#
#=============================================================================

=head2 Task

=head3 createTask

createTask(optional paramaters)

Example:

  $number = $SN->createTask({"short_description" => "this is the short description"});
   
Create a task record.
Returns an task number upon success. On failure returns undef. 

=cut

sub createTask {
  my ($me, $params) = (shift, shift);
  
  my $task = ServiceNow::ITIL::SC_Task->new($CONFIG);
  return $task->create($params);
}

=head3 closeTask

closeTask(task number, optional work effort in seconds)

Example:

  my $ret = $SN->closeTask($number);
  my $ret = $SN->closeTask($number, $seconds);
    
Close a ServiceNow Task and optionally specify work effort. 
Returns true on success, undef on failure.

=cut

sub closeTask {
	my ($me, $number, $secs) = (shift, shift, shift);
	
  my $task = ServiceNow::ITIL::SC_Task->new($CONFIG);;
  return $me->_close($task, $number, $secs);
}


=head3 reopenTask

reopenTask(task number)

Example:

  my $ret = $SN->reopenTask('TASK99999');
   
Reopen a closed ServiceNow Task.
Returns true on success, undef on failure.

=cut

sub reopenTask {
	my ($me, $number) = (shift, shift);
	
	my $task = ServiceNow::ITIL::SC_Task->new($CONFIG);	
    return $task->reopen($number);
}

=head3 reassignTask

reassignTask(task number, assignment group, optional person it is being assigned to)

Example:

  my $ret = $SN->reassignTask('TASK99999', 'SOME_GROUP');
  my $ret = $SN->reassignTask('TASK99999', 'SOME_GROUP', 'username');

Reassign a ServiceNow Task to a new assignment_group. (and optionally specify an assigned_to)
Returns true on success, undef on failure. 

=cut

sub reassignTask {
  my ($me,$number,$group,$user) = (shift,shift,shift,shift);
  $task = ServiceNow::ITIL::SC_Task->new($CONFIG);
  $task->addQuery("number",$number);
  $task->query();
  if ($task->next()) {
  	 return $task->reassign($number,$group,$user);
  }
  return undef;
}

=head3 updateTask

updateTask(task number, reference to named parameters hash of Task fields and values)

Example:

  my $ret = $SN->updateTask($number, {$field => $value});
   
Update a ServiceNow Task.
Returns true on success, undef on failure.

=cut

sub updateTask {
  my ($me, $number, $params) = (shift, shift, shift);
  
  my $target = ServiceNow::ITIL::Task->new($CONFIG);;
  return $me->_update($target, $number, $params);
}

=head3 queryTask

queryTask(reference to named parameters hash of Task fields and exact values )

Example:

   my @tasks = $SN->queryTask({'number' => $number});
   foreach my $task (@tasks) {
      print "Incident number: $task->{'number'}\n";
      print "Assignent Group: $task->{'assignment_group'}\n";
      print "Opened by:       $task->{'opened_by'}\n";
      print "SD:       $task->{'short_description'}\n";
      print "TW:       $task->{'time_worked'}\n";
      print "\n"
   }

Query for Tasks matching specified criteria.
Array of hashes of all matching Tasks, undef on failure or if no records found.

=cut

sub queryTask {
  my ($me, $params) = (shift, shift);
  
  my $target = ServiceNow::ITIL::SC_Task->new($CONFIG);;
  return $me->_query($target, $params);
}

# ======================================================================
#
# ImpNotification related functions
#
# ======================================================================

sub createNotification {
  my ($me, $params) = (shift, shift);
  my $notif = ServiceNow::ImportSet::Notification->new($CONFIG);
  my @result = $notif->create($params);
  return @result;
}

#=============================================================================
#
# Journal Related Functions
#
#=============================================================================

=head2 Journal

=head3 queryJournal

queryJournal(Incident/Ticket/Task number, optional journal field name )

Query for journals entries for the specified incident, ticket or task.
Return array of hashes of all matching Journals, undef on failure or if no records found. 
There will be one hash per per journal entry, 'value' will contain the journal entry string, 
'element' will be the name of the field (e.g. 'comments', 'work_notes', etc.) 

=cut

sub queryJournal {
  my ($me, $number, $fieldName) = (shift, shift, shift);
  my $target = _getTaskType($number);
  $target->addQuery("number",$number);
  $target->query();
  if ($target->next()) {
  	 return $target->queryJournal($CONFIG,$fieldName);	
  }
  return undef;
}

=head3 appendJournal

appendJournal(Incident/Ticket/Task number, field name, journal text)

Example:

  my $ret =  $SN->appendJournal('INC99999', 'comments' "some comment text");
   
Append a journal entry to the specified journal field of an incident, ticket, or task. 
Returns true on success, undef on failure.

=cut

# For now we are assuming that append Journals fieldName is always correct

sub appendJournal {
  my ($me,$number,$fieldName,$content) = (shift,shift,shift,shift);
  my $target = _getTaskType($number);
  $target->addQuery("number",$number);
  $target->query();
  if ($target->next()) {
    $target->setValue($fieldName,$content);
    $target->update();
    return 1;
  }
  return undef;
}

# private subroutine used by appendJournal

sub _getTaskType {
  my ($number) = (shift,shift);	 
  my $target;	
  unless (index($number,"INC") == -1) {
  	$target = ServiceNow::ITIL::Incident->new($CONFIG);
  }
  unless (index($number,"TASK") == -1) {
  	$target = ServiceNow::ITIL::SC_Task->new($CONFIG);
  }
  unless (index($number,"TKT") == -1) {
  	$target = ServiceNow::ITIL::Ticket->new($CONFIG);
  }
  return $target;
}

#======================================================================
#
# Approval related Functions
#
#======================================================================

=head2 Approval

=head3 queryApproval

queryApproval(reference to named parameters hash of approval fields and exact values)

Example:

  my @approvals = $SN->queryApproval({'approver' => 'username'});
     
Query for approvals
Return array of hashes of all matching approvals, undef on failure or if no records found.

=cut

sub queryApproval {
  my ($me, $params) = (shift, shift);
  my $target = ServiceNow::GlideRecord->new($CONFIG,'sysapproval_approver');
  
  return $me->_query($target,$params);
}

=head3 approve

approve(sys_id of the approval,approval state,optional comment text)

Example:

  my $ret = $SN->approve($sys_id, 'Approved');
  my $ret = $SN->approve($sys_id, 'Rejected', "Please do something else");
   
Approve/reject a ServiceNow approval request and optionally provide a comment.
Returns the sys_id on success, undef on failure. 

=cut

sub approve {
  my ($me, $sys_id, $state, $comment) = (shift,shift,shift,shift);
  my $target = ServiceNow::ITIL::Approval->new($CONFIG);
  
  if (!defined($state)) {
  	$state = 'approved';
  }
  
  if (lc($state) eq 'approved') {
  	return $target->approve( $sys_id, $state, $comment);
  }
  if (lc($state) eq 'rejected') {
  	return $target->reject( $sys_id, $state, $comment);
  }
  
  die 'must specify correct state';
}

=head2 Dictionary

=head3 queryFields

queryFields(table, optional boolean)

Example:

   my @fields = $SN->queryFields('incident');

List all the fields of an Incident, Request, RequestedItem or Task. 
Returns a reference to a hash of fields in the specified table type. 
The hash key is the field name, and the hash value is a hash reference to attributes about the field: 'mandatory', 'hint', 'label', 'reference' and 'choice'. 
Returns undef on failure. If getchoices is true then 'choices' is a reference to a hash containing individual choices, keyed by choice value and containing choice 'label' and 'hint'.

=cut  

sub queryFields {
	my ($me, $table,$choices) = (shift,shift,shift);
	my $target = ServiceNow::ITIL::Dictionary->new($CONFIG);
	
	return $target->queryFields($table,$choices); 
}
    
1;