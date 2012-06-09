use utf8;
package Schema::Result::Subscription;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Subscription

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<subscriptions>

=cut

__PACKAGE__->table("subscriptions");

=head1 ACCESSORS

=head2 sid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 pid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 uid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 start_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 end_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 renew

  data_type: 'enum'
  extra: {list => ["A","M","C"]}
  is_nullable: 1

=head2 active

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "pid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "uid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "start_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "end_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "renew",
  {
    data_type => "enum",
    extra => { list => ["A", "M", "C"] },
    is_nullable => 1,
  },
  "active",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sid>

=back

=cut

__PACKAGE__->set_primary_key("sid");

=head1 RELATIONS

=head2 extra_users

Type: has_many

Related object: L<Schema::Result::ExtraUser>

=cut

__PACKAGE__->has_many(
  "extra_users",
  "Schema::Result::ExtraUser",
  { "foreign.sid" => "self.sid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pid

Type: belongs_to

Related object: L<Schema::Result::Product>

=cut

__PACKAGE__->belongs_to(
  "pid",
  "Schema::Result::Product",
  { pid => "pid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-05-22 12:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2WX6scCE1ZrS3hBDR/+ykg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
