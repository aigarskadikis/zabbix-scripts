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
#	1.02 _delete implemented
#	1.03 _getKeys implemented
#	1.04 _get implemented
#	1.05 _encodedQuery implemented
#
# ======================================================================

package ServiceNow::WS;
#use Data::Dumper;

$VERSION = '1.05';
my $RESULT;
my $TYPE;

=pod

=head1 WS module

Service-now Perl API - WS perl module

=head1 Desciption

An internal class used for masking the web service function calls.  Calls subroutines in Connection class for access

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=cut

sub new {
  my ($class, $CONFIG, $TARGET) = (shift, shift, shift);
  
  undef($RESULT);
  undef($TYPE);
  my $me  = {};

  $me->{'TARGET'} = $TARGET;
  $me->{$TARGET} = $CONFIG->getConnection($TARGET);
   
  $me->{$TARGET}->open();
  bless($me,$class);
  return $me;
}

sub _insert (\%) {
  my ($me, %hash) = (shift, %{(shift)});
  
  $TYPE = "insert";
  $RESULT = $me->{ $me->{'TARGET'}}->send($TYPE, \%hash);
  return $RESULT;
}

sub _getRecords {
  my ($me, %hash) = (shift, %{(shift)});
  
  $TYPE = "getRecords";
  $RESULT = $me->{ $me->{'TARGET'}}->send($TYPE, \%hash);
  
  # debugging dump
  #print Dumper($RESULT);
  
  return $RESULT;
}

sub _update {
  my ($me, $sysId,  %hash) = (shift, shift,%{(shift)});
  
  $hash{'sys_id'} = $sysId;
  $TYPE = "update";
  $RESULT = $me->{ $me->{'TARGET'}}->send($TYPE, \%hash);
  return $RESULT;
}

# implemented by Daniel Hernandez Cassel

sub _get {
  my ($me, $sysId) = (shift, shift);
  
  $hash{'sys_id'} = $sysId;
  $TYPE = "get";
  $RESULT = $me->{ $me->{'TARGET'}}->send($TYPE, \%hash);
  
  return $RESULT;
}

# implemented by Daniel Hernandez Cassel

sub _getKeys {
  my ($me, %hash) = (shift, %{(shift)});
  
  $TYPE = "getKeys";
  $RESULT = $me->{ $me->{'TARGET'}}->send($TYPE, \%hash);
  
  return $RESULT;
}

# implemented by Daniel Hernandez Cassel

sub _delete {
  my ($me, $sysId) = (shift, shift);
  
  $hash{'sys_id'} = $sysId;
  $TYPE = "deleteRecord";
  $RESULT = $me->{ $me->{'TARGET'}}->send($TYPE, \%hash);
  return $RESULT;
}

# implemented by Daniel Hernandez Cassel

sub _encodedQuery {
  my ($me, $query) = (shift, shift);
  
  $TYPE = "getRecords";
  %keyHash = $me->{ $me->{'TARGET'}}->sendEncoded($TYPE, $query);
  return %keyHash;
}

1;