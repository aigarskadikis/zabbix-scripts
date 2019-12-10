
#!/usr/bin/perl -w

use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Simple tests => 4;

my $CONFIG = ServiceNow::Configuration->new();

my $SN = ServiceNow->new($CONFIG);
my $fields = $SN->queryFields('incident','RAWR');

  foreach my $name (keys %{$fields}) {
      print "$name : \
                      mandatory=$fields->{$name}->{'mandatory'} \
                      hint=\'$fields->{$name}->{'hint'}\' \
                      label=\'$fields->{$name}->{'label'}\' \
                      reference=\'$fields->{$name}->{'reference'}\' \
                      plural=\'$fields->{$name}->{'plural'}\' \
                      choice=\'$fields->{$name}->{'choice'}\'\n";
                         if (defined($fields->{$name}->{'choices'})) {
          print "                      Choices:\n";
          foreach my $c (keys %{$fields->{$name}->{'choices'}}) {
              print "                         value=\'$c\', label=\'$fields->{$name}->{'choices'}->{$c}->{'label'}\', hint=\'$fields->{$name}->{'choices'}->{$c}->{'hint'}\'\n";
          }
      }
                      
  } 
 ok($fields->{'incident_state'}->{'mandatory'} eq '0','base query correct');
 ok($fields->{'incident_state'}->{'hint'} eq 'Workflow state of the incident', 'Documentation query correct' );
 ok($fields->{'incident_state'}->{'choices'}->{'6'}->{'label'} eq 'Resolved','choices querry correct');
 
$fields = undef;
$fields = $SN->queryFields('incidentalitis','bleh');

ok(!defined($fields), 'Successfully failed to query bogus Table');

1;