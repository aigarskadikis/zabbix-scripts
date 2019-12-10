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

package ServiceNow::WSResult;

$VERSION = '1.00';
my $TYPE;

=pod

=head1 WSResult module

Service-now Perl API - WSResult perl module

=head1 Desciption

An internal wrapper object used for parsing return values and detecting SOAP faults

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=head1 Constructor

=head2 new

new(Type)
    
Example:

    $WSResult = ServiceNow::WSResult->new($Type);

Constructor.  Access to the ServiceNow Web Service Result object.  Creates and stores a connection to specified table.

=cut

sub new {
  my $class = shift;
  my $me = {};
  $TYPE = shift;
  bless($me,$class);
  ($me->{'WSRESULT'}) = @_;
  
  return $me;
}

=head2 getValue

getValue(key) 

Example:

  $WSResult->getValue('name');
    
Get value from result hash using the supplied key.
Returns string value. 

=cut

sub getValue {
	my $me = shift;
	my $key = shift;
	if (defined($me->{'WSRESULT'}->{$TYPE . 'Response'})) {
	  my %keyHash = %{$me->{'WSRESULT'}->{$TYPE . 'Response'}};
	  if ($keyHash{$key}) {
		return $keyHash{$key};
	  }
	}
	
	return undef;
}

=head2 getDisplayValue

getDisplayValue(key)

Example:

    $WSResult->getValue($field);
    
Gets display value from result hash using the supplied key.
Returns a string of the display value.

=cut

sub getDisplayValue {
	my ($me,$key) = (shift,shift);
	my $displayValue = $me->getValue("dv_". $key);
	
	if (defined($displayValue)) {
		return $displayValue;
	}
	return $me->getValue($key);
}

=head2 getResultBody

getResultBody();

Return the entire body of the result

=cut

sub getResultBody {
	my $me = shift;
	return $me->{'WSRESULT'};
}

=head2 getMultiInsertValue

getMultiInsertValue()

Return the results of a multi transform that resulted in multiple insert responses

=cut

sub getMultiInsertValue {
	my ($me, $key) = (shift, shift);
	
	if ($TYPE eq "insert") {
	  my @keyHash = @{$me->{'WSRESULT'}->{'multiInsertResponse'}->{'insertResponse'}};
	  return @keyHash;
    }
    
    return undef;
}

=head2 print

print()

Example:

    $WSResult->print();
    
Prints entire contents of result.

=cut

sub print {
  my $me = shift;

  if ($me->{'WSRESULT'} && $me->{'WSRESULT'}->{$TYPE . 'Response'}) {
    my %keyHash = %{ $me->{'WSRESULT'}->{$TYPE . 'Response'} };
    foreach my $k (keys %keyHash) {
        print "name=$k   value=$keyHash{$k}\n";
    }
  }
}

=head2 printFault

printFault(hash)

Example:

    $WSResult->printFault();
    
If fault print fault fields.

=cut

sub printFault {
  my $me = shift;

  if ($me->{'WSRESULT'}->fault) {
    print "faultcode=" . $me->{'WSRESULT'}->fault->{'faultcode'} . "\n";
    print "faultstring=" . $me->{'WSRESULT'}->fault->{'faultstring'} . "\n";
    print "detail=" . $me->{'WSRESULT'}->fault->{'detail'} . "\n";
  }
}

=head2 isFault

isFault()

Example:

    $WSResult->isFault();
    
Returns boolean TRUE if result was not found, FALSE is result was found.

=cut

sub isFault {
  my $me = shift;
  
  if ($me->{'WSRESULT'}->fault) {
  	return 1;
  }
  	
  return 0;
}

1;