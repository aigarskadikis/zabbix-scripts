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

package ServiceNow::ITIL::Task;
use ServiceNow::GlideRecord;
use ServiceNow::Attachment;

$VERSION = '1.00';
@ISA = (ServiceNow::GlideRecord);

=pod

=head1 Task module

Service-now Perl API - Task perl module

=head1 Desciption

An object representation of a Task in the Service-now platform.  Provides subroutines for querying, updating, and creating tasks. 
Task is the parent class of Incident, Problem, Change, SC_Task and Ticket. These child classes inherit subroutines from this class. 

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=head1 Constructor

=head2 new

new(Configuration);

Example:

  $task = ServiceNow::ITIL::Task->new($CONFIG);

Takes a configuration object and manufactures an Task object connected to the Service-now instance

=cut

sub new {
  my $class = shift; 
  my $config = shift;
  my $me = {};
  bless($me,$class);
  ServiceNow::GlideRecord->new($config, "task", $me);
  return $me;
}

=head1 Subroutines

=head2 create

create(optional paramaters)

Example:

   $task->create();
   
Creates and inserts Task/Incident/Ticket/SC_Task record into the respective table. 
Returns the number of created record on succes, undef on failure.

=cut

sub create {
  my ($me, $params) = (shift, shift);
  
  $me->insert($params);
  return $me->getValue("number");
}

=head2 close

close(number of record, optional parameters)

Example:

   $task->close('INC1000312');
   
Sets the state of Task/Incident/Ticket/SC_Task to closed and updates the respective table.
Returns the number of created record on success, undef on failure.

=cut

sub close {
  my ($me, $number, $hashArg) = (shift, shift, shift);
  return $me->_updateState($number, "3", $hashArg); # closed complete
}

=head2 reopen

reopen(number of record, optional parameters)

Example:
 
   $task->reopen('TKT1003010');

Sets the state of Task/Incident/Ticket/SC_Task to open and updates the respective table.

=cut

sub reopen {
  my ($me, $number, $hashArg) = (shift, shift, shift);
  return $me->_updateState($number, "1", $hashArg); # open
}

=head2 reassign

reassign(number, group, user);

Example:

  $incident->reassign($number, 'Database', 'user')

Re-assign an incident to the group and user specified.

=cut

sub reassign {
	my ($me,$number,$group,$user) = (shift,shift,shift,shift);
	$me->addQuery("number",$number);
	$me->query();
	if ($me->next()) {
		$me->setValue("assignment_group",$group);
		if (defined($user)) {
			$me->setValue("assigned_to",$user);
	    }	
 		$me->update();
		return 1;
	}
	return undef;
} 

# private subs
sub _updateState {
  my ($me, $number, $state, $hashArg) = (shift, shift, shift, shift);
  
  my %hash;
  unless( !$hashArg ) {
    %hash = %{($hashArg)};
    my $key;
    foreach $key (keys(%hash)) { 
  	  $me->setValue($key, $hash{$key});
    }
  }
  
  $me->addQuery("number", $number);
  $me->query();
  if ($me->next()) {
    $me->setValue("state", $state);
    $me->update();
    return 1;
  }
  
  return undef;
}

=head2 queryJournal

queryJournal(configuration file, optional field name)

Example:

   $task->queryJournal($config, 'work_notes');
   
Returns an array of hash references to each journal associated with the current Task/Incident/Ticket/SC_Task.
Optional field name refines the search to a specified field. 

=cut

sub queryJournal {
	my ($me,$config,$fieldName) = (shift,shift,shift);
	my @journals;
	my $sys_id = $me->getValue('sys_id');
	my $journal = ServiceNow::GlideRecord->new($config, "sys_journal_field");
	$journal->addQuery("element_id",$sys_id);
	unless (!($fieldName)) {
		$journal->addQuery("element",$fieldName);
	}
	$journal->query();
	my $count = 0;
	while ($journal->next()) {
		my $hash= {};
		$hash->{ 'value' } = $journal->getValue("value"); 
		$hash->{'element'} = $journal->getValue("element");
		
		push(@journals,$hash);
		$count++;
	}
	if($count == 0) {
		return undef;
	}
	return @journals;	
}

=head2 attach

attach(file path)

Example:

   $task->attach("/Users/davidloo/Desktop/test_files/number_test.xls");
   
Attach a file to a record of Task

=cut

sub attach {
	my ($me, $path) = (shift, shift);
	my $table_name = $me->getTableName();
	my $sys_id = $me->getValue("sys_id");
	
	my $attachment = ServiceNow::Attachment->new($me->getConfig());
	return $attachment->create($path, $table_name, $sys_id);
}

1;