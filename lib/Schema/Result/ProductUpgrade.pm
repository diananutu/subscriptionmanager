use utf8;
package Schema::Result::ProductUpgrade;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::ProductUpgrade

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<product_upgrades>

=cut

__PACKAGE__->table("product_upgrades");

=head1 ACCESSORS

=head2 piud

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 parent_pid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 upgraded_pid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "piud",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "parent_pid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "upgraded_pid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</piud>

=back

=cut

__PACKAGE__->set_primary_key("piud");

=head1 RELATIONS

=head2 parent_pid

Type: belongs_to

Related object: L<Schema::Result::Product>

=cut

__PACKAGE__->belongs_to(
  "parent_pid",
  "Schema::Result::Product",
  { pid => "parent_pid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 upgraded_pid

Type: belongs_to

Related object: L<Schema::Result::Product>

=cut

__PACKAGE__->belongs_to(
  "upgraded_pid",
  "Schema::Result::Product",
  { pid => "upgraded_pid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-05-22 12:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nhUXwP0Kvn6+Zfb5Ve7EPQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
