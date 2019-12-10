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

package ServiceNow::Attachment;
use ServiceNow::GlideRecord;
use File::Basename;
use MIME::Types;
use MIME::Type;
use MIME::Base64;

$VERSION = '1.00';
@ISA = (ServiceNow::GlideRecord);

=pod

=head1 Attachment module

Service-now Perl API - Attachment perl module

=head1 Desciption

An object representation of an Attachment in the Service-now platform.  Provides subroutines for creating 
an attachment and attaching to an existing record 

=head2 System Requirements

The Service-now Perl API requires Perl 5.8 with the following modules installed

  * SOAP::Lite (prerequisites http://soaplite.com/prereqs.html) 0.71 or later
  * Crypt::SSLeay
  * IO::Socket::SSL
  * File::Basename
  * MIME::Types
  * MIME::Type
  * MIME::Base64

=head1 Constructor

=head2 new

new(Configuration);

Example:

  $task = ServiceNow::Attachment->new($CONFIG);

Takes a configuration object and manufactures an Task object connected to the Service-now instance

=cut

sub new {
  my $class = shift; 
  my $config = shift;
  my $me = {};
  bless($me,$class);
  ServiceNow::GlideRecord->new($config, "ecc_queue", $me);
  return $me;
}

=head1 Subroutines

=head2 create

create(path, table_name, sys_id)

Example:

   $attachment->create("/Users/davidloo/Desktop/test_files/number_test.xls", "incident", "9d385017c611228701d22104cc95c371");
   
Creates an attachment from a file on the local disk, to an existing record defined by table_name and sys_id 
Returns the sys_id of the ecc_queue record, undef if failed

=cut

sub create {
  my ($me, $path, $table_name, $sys_id) = (shift, shift, shift, shift, shift);
  
#  my $file_type = "application/octet-stream";
  my ($file_name, $file_path, $suffix ) = fileparse( $path, "\.[^.]*");
  my $mimetypes = MIME::Types->new;
  my $file_type = $mimetypes->mimeTypeOf($suffix);
  my $base64;
  my $buf;

  open(FILE, $path) or die "$!";
  binmode FILE;
  while (read(FILE, $buf, 60*57)) {
    $base64 .= encode_base64($buf);
  }
  
  # if not defined, set the default
  if (!defined($file_type)) {
    $file_type = $mimetypes->type('application/octet-stream');
  }
  
  $me->setValue("agent", "Perl API");
  $me->setValue("topic", "AttachmentCreator");
  $me->setValue("name", $file_name . $suffix . ":" . $file_type);
  $me->setValue("source", $table_name . ":" . $sys_id);
  $me->setValue("payload", $base64);
  return $me->insert();
}

1;