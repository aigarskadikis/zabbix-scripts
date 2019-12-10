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

package ServiceNow::ImportSet::Notification;
use ServiceNow::GlideRecord;

$VERSION = '1.00';
@ISA = (ServiceNow::GlideRecord);

sub new {
  my $class = shift; 
  my $config = shift;
  my $me = {};
  bless($me,$class);

  ServiceNow::GlideRecord->new($config, "imp_notification", $me);
  return $me;
}

# returns an array of hash values for the field values
sub create {
  my ($me, $params) = (shift, shift);
  
  my @hash;
  $me->insert($params);
  my $displayValue = $me->getValue("display_value");
  if (defined($displayValue)) {
  	@hash = ($me->{'RESULT'}->getResultBody()->{'insertResponse'});
  	return @hash;
  } else {
  	@hash = @{$me->{'RESULT'}->getResultBody()->{'multiInsertResponse'}->{'insertResponse'}};
  	return @hash;
  }
  
  return undef;
}

1;