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
#	1.01 getSoapUrl
#
# ======================================================================

package ServiceNow::Configuration;

use ServiceNow::Connection;

$VERSION = '1.01';
$SOAP_ENDPOINT_URL = "http://localhost:8080/glide/";
$SOAP_ENDPOINT_SUFFIX = "?SOAP";
$SOAP_USER = "itil";
$SOAP_USER_PASSWORD = "itil";
%SOAP_PARAMETERS = ('displayvalue' => 'all');

=pod

=head1 Configuration module

Service-now Perl API - Ticket perl module

=head1 Desciption

An object representation of a Configuration object used to access your Service-now instance. 

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL

=head1 Constructor

=head2 new

new();

Example:

  $conf = ServiceNow::Configuration->new();

Create a new Configuration object and start customizing it to be used for other objects

=cut

sub new {
	my $class = shift;
	my $me = {};
	bless($me,$class);
	return $me;
}

=head1 Subroutines

=head2 getSoapEndpoint

getSoapEndpoint(target_table);

Gets the complete SOAP endpoint used to access your Service-now instance, given the table name.

=cut

sub getSoapEndPoint {
	my ($me, $target) = (shift, shift);
	
	my $endpoint = $SOAP_ENDPOINT_URL . $target . ".do" . $SOAP_ENDPOINT_SUFFIX;
	
	# add additional parameters
    while ( (my $key, my $value) = each %SOAP_PARAMETERS ) {
      $endpoint = $endpoint . "&" . $key . "=" . $value;
    }
	
	return $endpoint;
}

=head2 setSoapEndpoint

setSoapEndpoint(endpoint_url);

Sets the complete SOAP endpoint used to access your Service-now instance

=cut

sub setSoapEndPoint {
	my ($me, $endPoint) = (shift, shift);
	$SOAP_ENDPOINT_URL = $endPoint;
}

=head2 getSoapUrl

getSoapUrl();

Get only the SOAP url used to access to your Service-now instance

=cut

sub getSoapUrl {
	return $SOAP_ENDPOINT_URL;
}

=head2 getUserName

getUserName();

Get the user name used to authenticate a connection to the SOAP endpoint

=cut

sub getUserName {
	return $SOAP_USER;
}

=head2 setUserName

setUserName(user_name);

Set the user name used to authenticate a connection to the SOAP endpoint

=cut

sub setUserName {
	my $me = shift;
	$SOAP_USER = shift;
}

=head2 getUserPassword

getUserPassword();

Get the user password used to authenticate a connection to the SOAP endpoint

=cut

sub getUserPassword {
	return $SOAP_USER_PASSWORD;
}

=head2 setUserPassword

setUserPassword(user_password);

Set the user password used to authenticate a connection to the SOAP endpoint

=cut

sub setUserPassword {
	my $me = shift;
	$SOAP_USER_PASSWORD = shift;
}

=head2 getConnection

getConnection(target_table);

Get the Connection object used to access the Service-now SOAP endpoint

=cut

sub getConnection {
	my ($me, $target) = (shift, shift);

    # make a connection and return it
	return ServiceNow::Connection->new($me, $target);
}

1;