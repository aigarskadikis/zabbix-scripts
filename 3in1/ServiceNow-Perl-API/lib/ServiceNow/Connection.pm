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
#	1.01 sendEncoded implemented
#
# ======================================================================

package ServiceNow::Connection;

# default is using SOAP::Lite
use SOAP::Lite;

$VERSION = '1.01';
my $CONFIG;

=pod

=head1 Connection module

Service-now Perl API - Connection perl module

=head1 Desciption

An object representation of a Connection object used to access your Service-now instance. 
The Connection class can be overrided by the API user for implementations other than the default SOAP::Lite dependency.
To override this class, provide the subroutines for new, open, and send.

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=cut

# implement SOAP::Lite's basic auth strategy
sub SOAP::Transport::HTTP::Client::get_basic_credentials {
   return $CONFIG->getUserName() => $CONFIG->getUserPassword();
}

sub new {
  my ($class, $conf, $target) = (shift, shift, shift);
  # copy to global
  my $me = {};
  $CONFIG = $conf;
  
  $me->{'SOAP'} = SOAP::Lite
    -> proxy($CONFIG->getSoapEndPoint($target));
  bless($me, $class);
  return $me;
}

sub open {
  #print "connection open() is not implemented\n";
}

sub send {
  my ($me, $methodName, %hash) = (shift, shift, %{(shift)});
  
  my $METHOD = SOAP::Data->name($methodName)
    ->attr({xmlns => 'http://www.service-now.com/' . $methodName});
  
  my(@PARAMS);
  my($key);
  foreach $key (keys(%hash)) { 
  	push(@PARAMS, SOAP::Data->name($key => $hash{$key}));
  }
	
  my $RESULT = $me->{'SOAP'}->call($METHOD => @PARAMS);
  # return the element within the Body element, removing SOAP::Lite dependencies
  return $RESULT->valueof('Body');
}

# implemented by Daniel Hernandez Cassel
# used to send encodedQuery

sub sendEncoded {
  my ($me, $methodName, $query) = (shift, shift, shift);
  
  my $soap = $me->{'SOAP'};
  my $method = SOAP::Data->name($methodName)->attr({xmlns => 'http://www.service-now.com/'});
  my @params = ( SOAP::Data->name(__encoded_query => $query) );  
  my %keyHash = %{ $soap->call($method => @params)->body->{'getRecordsResponse'} };
  return %keyHash;
}

sub close {
  #print "connection close() is not implemented\n";	
}

1;