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
#	1.02 delete implemented
#	1.03 queryKeys and getKeyValue implemented
#	1.04 get implemented
#	1.05 encodedQuery implemented
#	1.06 getKeyValue deprecated
#	1.07 clearValue implemented
#
# ======================================================================

package ServiceNow::GlideRecord;

use ServiceNow::WS;
use ServiceNow::WSResult;

$VERSION = '1.07';

my @VALUES;
my @QUERIES;
my $TABLE_NAME;
my $CONFIG;

=pod

=head1 GlideRecord module

Service-now Perl API - GlideRecord perl module

=head1 Desciption

An object representation of a GlideRecord object used to access your Service-now instance. 

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=head1 Constructor

=head2 new

new(Configuration object, Table name, optional caller object)
    
    $config = ServiceNow::Configuration->new();
	$glideRecord = ServiceNow::GlideRecord->new($config,'incident',$me);
	
Constructor.  Access to the ServiceNow Glide Record object. The caller object is optional unless creating a Class that 
inherits GlideRecord (See any class in ServiceNow/ITIL for example).

=cut

sub new {
  my ($class,$config,$table_name,$caller) = (shift, shift, shift, shift);
  my $me = {};
  # initialize globals
  undef(@QUERIES) ;
  undef(@VALUES);
  
  $TABLE_NAME = $table_name;
  $CONFIG = $config;
  
  $caller->{'WS'} = $me->{'WS'} = ServiceNow::WS->new($config, $table_name);
  bless ($me,$class);
  return $me;
}

=head1 Subrotines

=head2 insert

insert(optional hash argument)

Example:

    $glideRecord->insert();
    
Inserts glide record into Table. Returns sys id.

=cut

sub insert {
  my ($me, $hashArg) = (shift, shift);
  my %hash;
  
  if (defined($hashArg)) {
  	%hash = %{($hashArg)};
  } elsif (defined($me->{'VALUES'})) {
  	%hash = @{$me->{'VALUES'}};
  }
  
  my $w = $me->{'WS'}->_insert(\%hash);
  $me->{'RESULT'} = ServiceNow::WSResult->new("insert", $w);
  return $me->{'RESULT'}->getValue("sys_id");
}

=head2 setValue

setValue(name, value)

Example:

	$glideRecord->setValue('caller_id','56');
	
Sets element within Glide Record with name to specified value.  
Will not effect the GlideRecord within the Table until inserted or updated.

=cut

sub setValue {
	my ($me, $name, $value) = (shift, shift, shift);
	
	push(@{$me->{'VALUES'}}, ($name => $value));
}

=head2 addQuery

addQuery(name, value)

Example:

    $glideRecord->addQuery('number','INC1000014');
    $glideRecord->query();
    
Refines query to include only the Glide Records with field name=value.

=cut

sub addQuery {
	my ($me, $name, $value) = (shift, shift, shift);
	push(@{$me->{'QUERIES'}}, ($name => $value));
}

=head2 query

query(optional hash arguments)

Example:

	$glideRecord->query();
	
Returns all Glide Records in the Table with specified query.
Step through the Records with the next() call.

=cut

sub query {
  my ($me, $hashArg) = (shift, shift);
  my %hash;
  
  if (defined($hashArg)) {
  	%hash = %{($hashArg)};
  } elsif (defined($me->{'QUERIES'})) {
  	%hash = @{$me->{'QUERIES'}};
  }

  $me->{'QCOUNT'} = 0;
  $me->{'RESULTS'} = $me->{'WS'}->_getRecords(\%hash);
  my %keyHash = %{$me->{'RESULTS'}->{'getRecordsResponse'}};
  
  if(ref($keyHash{'getRecordsResult'}) eq "ARRAY") {
    $me->{'RESULTS_SIZE'} = @{$keyHash{'getRecordsResult'}}; 
  } else {
  	if (defined($keyHash{'getRecordsResult'})) {
  		$me->{'RESULTS_SIZE'} = 1;
  	} else {
  		$me->{'RESULTS_SIZE'} = 0;
  	}
  }
}

=head2 next

next()

Example:

	if($glideRecord->next())
	while($glideRecord->next())

Steps through the results of Glide Record query.
Returns TRUE if more elements exist.

=cut

sub next {
	my $me = shift;
  if ($me->{'QCOUNT'} > ($me->{'RESULTS_SIZE'} - 1)) {
    return 0;
  }

  $me->{'QCOUNT'}++;
  return 1;
}

=head2 update

update(optional hash arguments)
    
Example:

    $glideRecord->setValue('name','value');
   	$glideRecord->update();

Updates Glide Record in table with the Glide Record object.  Changes to Glide Record object will not take effect until updated or inserted.
Returns sys_id of record on success, undef of failure.

=cut

sub update {
  my ($me, $hashArg) = (shift, shift);
  my %hash;
  
  if (defined($hashArg)) {
  	%hash = %{($hashArg)};
  } elsif (defined($me->{'VALUES'})){
  	%hash = @{$me->{'VALUES'}};
  }
  
  my $sys_id = $me->getValue("sys_id");
  if (!defined($sys_id)) {
  	die "call query first before calling update";
  }
  
  my $w = $me->{'WS'}->_update($sys_id,\%hash);
  $me->{'RESULT'} = ServiceNow::WSResult->new("update", $w);
  return $me->{'RESULT'}->getValue("sys_id");
}

# implemented by Daniel Hernandez Cassel

sub delete {
 my $me = shift;
 my $sys_id = $me->getValue("sys_id");
  if (!defined($sys_id)) {
  	die "call query first before calling delete";
  }
  
  my $w = $me->{'WS'}->_delete($sys_id);
  return 1;
}

sub getRecord {
  my $me = shift;
  my %keyHash = %{$me->{'RESULTS'}->{'getRecordsResponse'}};
  if(ref($keyHash{'getRecordsResult'}) eq "ARRAY") {
    return %{$keyHash{'getRecordsResult'}[$me->{'QCOUNT'} - 1]};
  } else {
  	return %{$keyHash{'getRecordsResult'}};
  }
}

=head2 getValue

getValue(name)
   
Example:

    $glideRecord->getValue($name);
    
Get value of element name in GlideRecord.
Returns string value of element.

=cut

sub getValue {
  my ($me, $field) = (shift, shift);
  
  if (defined($me->{'RESULT'})) {
  	return $me->{'RESULT'}->getValue($field);
  }
  
  my %keyHash = %{$me->{'RESULTS'}->{'getRecordsResponse'}};
  my %record;
  if(ref($keyHash{'getRecordsResult'}) eq "ARRAY") {
    %record = %{$keyHash{'getRecordsResult'}[$me->{'QCOUNT'} - 1]};
  } else {
    %record = %{$keyHash{'getRecordsResult'}};
  }
  
  return $record{$field};
}

=head2 getDisplayValue

getDisplayValue(name)

Example:

    $glideRecord->getDisplayValue($name);
    
Gets display value of element name in GlideRecord. A display value would be the string name, instead of the sys_id in the case of
a reference field, or the string value instead of the number value in the case of choice fields.

=cut

sub getDisplayValue {
  my ($me, $field) = (shift, shift);
  
  if (defined($me->{'RESULT'})) {
  	return $me->{'RESULT'}->getDisplayValue($field);
  }
  
  my %keyHash = %{$me->{'RESULTS'}->{'getRecordsResponse'}};
  my %record;
  if(ref($keyHash{'getRecordsResult'}) eq "ARRAY") {
    %record = %{$keyHash{'getRecordsResult'}[$me->{'QCOUNT'} - 1]};
  } else {
    %record = %{$keyHash{'getRecordsResult'}};
  }
  my $dv = $record{"dv_".$field};
  
  if (defined($dv)) {
  	return $dv;
  }
  return $record{$field};
}

sub getTableName {
	return $TABLE_NAME;
}

sub getConfig {
	return $CONFIG;
}

=head2 queryKeys
implemented by Daniel Hernandez Cassel

queryKeys(optional hash arguments)

Example:

	$glideRecord->queryKeys();
	
Returns the sys_id of all the Glide Records in the Table with specified query.
=cut

sub queryKeys {
  my ($me, $hashArg) = (shift, shift);
  my %hash;
  
  if (defined($hashArg)) {
  	%hash = %{($hashArg)};
  } elsif (defined($me->{'QUERIES'})) {
  	%hash = @{$me->{'QUERIES'}};
  }
  $me->{'RESULTS'} = $me->{'WS'}->_getKeys(\%hash);
  if ($me->{'RESULTS'}->{'getKeysResponse'}->{'count'} eq 0){
	return "no results for the query";
  }else{
    return $me->{'RESULTS'}->{'getKeysResponse'}->{'sys_id'};
  }
}

=head2 get
implemented by Daniel Hernandez Cassel

get($sys_id)

Example:

	$glideRecord->get($sys_id);
	
Gets all the elements and values of the glide record with the sys_id equal to $sys_id of the Table.
=cut

sub get {
  my ($me, $sys_id) = (shift, shift);
  my ($result, $k);
  $me->{'RESULTS'} = $me->{'WS'}->_get($sys_id);
  my %h = %{$me->{'RESULTS'}->{'getResponse'}};
  foreach $k (sort keys %h){
		$result.="$k ::> $h{$k}\n";
  }
  if (defined $result and length $result){
    return $result;
  }else{
	return "no results for the query";
  }
}

=head2 encodedQuery
implemented by Daniel Hernandez Cassel

encodedQuery($query)

Example:

	$glideRecord = ServiceNow::GlideRecord->new($CONFIG,$table);
	%result = $glideRecord->encodedQuery($CONFIG,$query); #query contains the encoded query.
	
Gets all the elements and values of the glide records that result of the encoded query for the Table.
=cut

sub encodedQuery {
	my ($me, %value) = @_;
	my @v = values %value;
	my %w = $me->{'WS'}->_encodedQuery(@v);
	return %w;
}

=head2 clearValue
implemented by Daniel Hernandez Cassel

clearValue(name)

Example:

	$glideRecord->clearValue('name');
	
Clears the element within Glide Record with specified name.  
Will not effect the GlideRecord within the Table until inserted or updated.

=cut

sub clearValue {
	my ($me, $name) = (shift, shift);
	$value = 'NULL';
	push(@{$me->{'VALUES'}}, ($name => $value));
}

1;