use utf8;
package Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 uid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 photo

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 address

  data_type: 'varchar'
  is_nullable: 1
  size: 150

=head2 phone

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 country

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 county

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 birthday

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 gender

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 signup_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 access

  data_type: 'varchar'
  default_value: 'user'
  is_nullable: 1
  size: 10

=head2 active

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "uid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "photo",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "address",
  { data_type => "varchar", is_nullable => 1, size => 150 },
  "phone",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "country",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "county",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "birthday",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "gender",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "signup_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "access",
  {
    data_type => "varchar",
    default_value => "user",
    is_nullable => 1,
    size => 10,
  },
  "active",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</uid>

=back

=cut

__PACKAGE__->set_primary_key("uid");

=head1 RELATIONS

=head2 extra_users_parents

Type: has_many

Related object: L<Schema::Result::ExtraUser>

=cut

__PACKAGE__->has_many(
  "extra_users_parents",
  "Schema::Result::ExtraUser",
  { "foreign.parent_id" => "self.uid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 extra_users_uids

Type: has_many

Related object: L<Schema::Result::ExtraUser>

=cut

__PACKAGE__->has_many(
  "extra_users_uids",
  "Schema::Result::ExtraUser",
  { "foreign.uid" => "self.uid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 password_hashes

Type: has_many

Related object: L<Schema::Result::PasswordHash>

=cut

__PACKAGE__->has_many(
  "password_hashes",
  "Schema::Result::PasswordHash",
  { "foreign.uid" => "self.uid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 subscriptions

Type: has_many

Related object: L<Schema::Result::Subscription>

=cut

__PACKAGE__->has_many(
  "subscriptions",
  "Schema::Result::Subscription",
  { "foreign.uid" => "self.uid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-08 13:52:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YpQo1dwvfgWPJJ4pLZgkcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
