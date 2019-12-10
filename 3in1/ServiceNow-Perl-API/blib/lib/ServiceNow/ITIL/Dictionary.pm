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

package ServiceNow::ITIL::Dictionary;
use ServiceNow::GlideRecord;

$VERSION = '1.00';
@ISA = (ServiceNow::GlideRecord);

=pod

=head1 Dictionary module

Service-now Perl API - Dictionary perl module

=head1 Desciption

An object representation of a Dictionary record in the Service-now platform.  Provides subroutines for querying, updating, and creating sys_dictionary. 

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=head1 Constructor

=head2 new

new(Configuration);

Example:

  $dic = ServiceNow::ITIL::Dictionary->new($CONFIG);

Takes a configuration object and manufactures a Dictionary object connected to the Service-now instance

=cut

sub new {
  my $class = shift;
  my $me = {};
   
  $me->{'CONFIG'} = shift;

  ServiceNow::GlideRecord->new($me->{'CONFIG'}, "sys_dictionary", $me);
  bless($me,$class);
  return $me;
}

=head1 Subroutines

=head2 queryFields

queryFields(table name, optional boolean choice)

Example:

   $sys_dictionary->queryFields('incident');
   
Returns an array of hashes containing each field for specified table.  If choice is specified then get choice values for each of the
choice fields and put them into the hash element 'choices'.

=cut

sub queryFields {
	my ($me,$table,$choice) = (shift,shift,shift);
	$me->addQuery('name',$table);
	$me->query();
	$hash = undef;
	
	while ($me->next()) {
		my $name = $me->getValue('element');
		$hash->{$name}{'mandatory'} = $me->getValue('mandatory');
		$hash->{$name}{'reference'} = $me->getValue('reference');
		$hash->{$name}{'choice'}= $me->getValue('choice');
	    $me->_queryDocumentation($hash,$table,$name);
	    if(defined($choice)) {
	    	$me->_queryChoices($hash,$table,$name);
	    }
	}
	return $hash;
}

#
# Query the documentation table and add to hash
#
# private subroutine

sub _queryDocumentation {
	my ($me,$hash, $table, $name) = (shift,shift,shift,shift);
	my $doc = ServiceNow::GlideRecord->new($me->{'CONFIG'},"sys_documentation");
	$doc->addQuery('element',$name);
	$doc->addQuery('table',$table);
	$doc->query();
	if($doc->next()) {
	   print $doc->getValue('hint')."\n";
       $hash->{$name}{'hint'} = $doc->getValue('hint');
       $hash->{$name}{'label'} = $doc->getValue('label');
       $hash->{$name}{'plural'} = $doc->getValue('plural');		    	
	}
}

#
#  Query the choice table and add them to hash
#
# private subroutine

sub _queryChoices {
	my ($me,$hash, $table, $name) = (shift,shift,shift,shift);
	my $choice = ServiceNow::GlideRecord->new($me->{'CONFIG'},"sys_choice");
	$choice->addQuery('table', $table);
	$choice->addQuery('element',$name);
	$choice->query();
	my $choices = {};
	while($choice->next()) {
		$choices->{$choice->getValue('value')}{'hint'} = $choice->getValue('hint');
		$choices->{$choice->getValue('value')}{'label'} = $choice->getValue('label');
	}
	$hash->{$name}{'choices'} = $choices;
}

1;