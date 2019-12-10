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

package ServiceNow::ITIL::Incident;
use ServiceNow::GlideRecord;
use ServiceNow::ITIL::Task;
use ServiceNow::ITIL::Problem;
use ServiceNow::ITIL::Change;

$VERSION = '1.00';
@ISA = (ServiceNow::ITIL::Task);
my $CONFIG;

=pod

=head1 Incident module

Service-now Perl API - Incident perl module

=head1 Desciption

An object representation of an Incident in the Service-now platform.  Provides subroutines for querying, updating, and creating incidents. 

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=head1 Constructor

=head2 new

new(Configuration);

Example:

  $incident = ServiceNow::ITIL::Incident->new($CONFIG);

Takes a configuration object and manufactures an Incident object connected to the Service-now instance

=cut

sub new {
  my $class = shift; 
  $CONFIG = shift;
  my $me = {};
  
  bless($me,$class);
  ServiceNow::GlideRecord->new($CONFIG, "incident", $me);
  return $me;
}

=head1 Subroutines

=head2 close

close(number, hashmap);

Example:

  $incident->close($number)

Close an incident and update values described in the hash map passed in.

=cut

sub close {
  my ($me, $number, $hashArg) = (shift, shift, shift);
  return $me->_updateState($number, "7", $hashArg); # close
}

=head2 reopen

reopen(number, hashmap);

Example:

  $incident->reopen($number);

Re-open a closed incident and update values described in the hash map passed in.

=cut

sub reopen {
  my ($me, $number, $hashArg) = (shift, shift, shift);
  return $me->_updateState($number, "2", $hashArg); # active
}

# private routine
sub _updateState {
  my ($me, $number, $state, $hashArg) = (shift, shift, shift, shift);

  if(defined($hashArg)) {
    my %hash = %{($hashArg)};
    my $key;
    foreach $key (keys(%hash)) { 
  	  $me->setValue($key, $hash{$key});
    }
  }
  
  $me->addQuery("number", $number);
  $me->query();
  if ($me->next()) {
    $me->setValue("incident_state", $state);
    $me->update();
    return 1;
  }
  
  return undef;
}

=head2 createProblem

createProblem();

Create a problem ticket from an incident and associate it. Returns the sys_id of the newly created problem ticket

=cut

sub createProblem {
	my ($me) = (shift);
	if(!$me->getValue('problem_id')) {
		my $problem = ServiceNow::ITIL::Problem->new($CONFIG);
		$problem->setValue('short_description',$me->getValue('short_description'));
		$problem->setValue('cmdb_ci',$me->getValue('cmdb_ci'));
		my $pid = $problem->insert();
		$me->setValue('problem_id', $pid);	
		$me->update();
		return $pid;
	}
	return undef;
}

=head2 createChange

createChange();

Create a change request from an incident and associate it. Returns the sys_id of the newly created change request

=cut

sub createChange {
	my ($me) = (shift);
	if(!$me->getValue('rfc')) {
		my $change = ServiceNow::ITIL::Change->new($CONFIG);
		$change->setValue('priority',$me->getValue('priority'));
		$change->setValue('impact',$me->getValue('impact'));
		$change->setValue('opened_by',$me->getValue('opened_by'));
		$change->setValue('cmdb_ci',$me->getValue('cmdb_ci'));
		my $cid = $change->insert();
		$me->setValue('rfc', $cid);
		$me->update();
		return $cid;
	}
	return undef;
}

1;