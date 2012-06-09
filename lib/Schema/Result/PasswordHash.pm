use utf8;
package Schema::Result::PasswordHash;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::PasswordHash

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<password_hashes>

=cut

__PACKAGE__->table("password_hashes");

=head1 ACCESSORS

=head2 hid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 uid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 sent_url

  data_type: 'varchar'
  is_nullable: 0
  size: 150

=head2 expiry_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "hid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "uid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "sent_url",
  { data_type => "varchar", is_nullable => 0, size => 150 },
  "expiry_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</hid>

=back

=cut

__PACKAGE__->set_primary_key("hid");

=head1 RELATIONS

=head2 uid

Type: belongs_to

Related object: L<Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "uid",
  "Schema::Result::User",
  { uid => "uid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-06-07 15:06:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CWYjUjXIjV7a4cagjiXcUw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
