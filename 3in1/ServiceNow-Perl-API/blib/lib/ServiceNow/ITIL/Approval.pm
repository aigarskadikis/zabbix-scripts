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

package ServiceNow::ITIL::Approval;
use ServiceNow::GlideRecord;

$VERSION = '1.00';
@ISA = (ServiceNow::GlideRecord);

=pod

=head1 Approval module

Service-now Perl API - Approval perl module

=head1 Desciption

An object representation of an Approval record in the Service-now platform.  Provides subroutines for querying, updating, and creating approvals. 

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=head1 Constructor

=head2 new

new(Configuration);

Example:

  $approvals = ServiceNow::ITIL::Approval->new($CONFIG);

Takes a configuration object and manufactures an Approval object connected to the Service-now instance

=cut

sub new {
  my $class = shift; 
  my $config = shift;
  my $me = {};
  bless($me,$class);

  ServiceNow::GlideRecord->new($config, "sysapproval_approver", $me);
  return $me;
}

=head1 Subroutines

=head2 reject

reject(sys_id of approval record, optional comment string)

Example:

   $approval->reject($sysID,$comment);

Reject the Approval record with specified sys id, and add comment to approval if given.

=cut

sub reject {
	my ($me, $sys_id,$comment) = (shift,shift,shift);
	
	return $me->_changeState($sys_id,'rejected',$comment);
}

=head2 approve

approve(sys_id of approval record, optional comment string)

Example:

   $approval->approve($sysID,$comment);

Approve the Approval record with specified sys id, and add comment to approval if given.

=cut

sub approve {
	my ($me, $sys_id,$comment) = (shift,shift,shift);
	
	return $me->_changeState($sys_id,'approved',$comment);
}

# private subroutine
sub _changeState {
	my ($me,$sys_id,$state,$comment) = (shift,shift,shift,shift);
    $me->addQuery('sys_id',$sys_id);
    $me->query();
    if($me->next()) {
  	  $me->setValue('state',lc($state));
  	  unless(!($comment)) {
  	    $me->setValue('comments', $comment);
  	  }
  	  $me->update();
  	  return $me->getValue('sys_id');
    } 	
    return undef;
}

1;