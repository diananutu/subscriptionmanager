use utf8;
package Schema::Result::ExtraUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::ExtraUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<extra_users>

=cut

__PACKAGE__->table("extra_users");

=head1 ACCESSORS

=head2 euid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 sid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 uid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 status

  data_type: 'enum'
  default_value: 'inactive'
  extra: {list => ["active","inactive"]}
  is_nullable: 1

=head2 invite_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 registered_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 parent_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "euid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "sid",
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
  "status",
  {
    data_type => "enum",
    default_value => "inactive",
    extra => { list => ["active", "inactive"] },
    is_nullable => 1,
  },
  "invite_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "registered_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "parent_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</euid>

=back

=cut

__PACKAGE__->set_primary_key("euid");

=head1 UNIQUE CONSTRAINTS

=head2 C<sid>

=over 4

=item * L</sid>

=item * L</uid>

=back

=cut

__PACKAGE__->add_unique_constraint("sid", ["sid", "uid"]);

=head1 RELATIONS

=head2 parent

Type: belongs_to

Related object: L<Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "parent",
  "Schema::Result::User",
  { uid => "parent_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 sid

Type: belongs_to

Related object: L<Schema::Result::Subscription>

=cut

__PACKAGE__->belongs_to(
  "sid",
  "Schema::Result::Subscription",
  { sid => "sid" },
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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-05-24 11:36:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yE67obnKwYEgU/l2iSXYnQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
