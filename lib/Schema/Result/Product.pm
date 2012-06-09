use utf8;
package Schema::Result::Product;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Product

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<products>

=cut

__PACKAGE__->table("products");

=head1 ACCESSORS

=head2 pid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 no_periods

  data_type: 'integer'
  is_nullable: 1

=head2 subscription_cost

  data_type: 'float'
  is_nullable: 1

=head2 period_type

  data_type: 'enum'
  extra: {list => ["day","week","month","quarter","year"]}
  is_nullable: 1

=head2 auto_renew

  data_type: 'enum'
  extra: {list => [0,1]}
  is_nullable: 1

=head2 trial_period

  data_type: 'integer'
  is_nullable: 1

=head2 additional_users

  data_type: 'integer'
  is_nullable: 1

=head2 details

  data_type: 'varchar'
  is_nullable: 1
  size: 300

=head2 actions

  data_type: 'varchar'
  is_nullable: 1
  size: 300

=head2 is_new

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 requires_card

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 currency

  data_type: 'enum'
  default_value: 'USD'
  extra: {list => ["USD","EUR","GBP"]}
  is_nullable: 1

=head2 trial_period_type

  data_type: 'enum'
  extra: {list => ["day","week","month","quarter","year"]}
  is_nullable: 1

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 is_featured

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "no_periods",
  { data_type => "integer", is_nullable => 1 },
  "subscription_cost",
  { data_type => "float", is_nullable => 1 },
  "period_type",
  {
    data_type => "enum",
    extra => { list => ["day", "week", "month", "quarter", "year"] },
    is_nullable => 1,
  },
  "auto_renew",
  { data_type => "enum", extra => { list => [0, 1] }, is_nullable => 1 },
  "trial_period",
  { data_type => "integer", is_nullable => 1 },
  "additional_users",
  { data_type => "integer", is_nullable => 1 },
  "details",
  { data_type => "varchar", is_nullable => 1, size => 300 },
  "actions",
  { data_type => "varchar", is_nullable => 1, size => 300 },
  "is_new",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
  "requires_card",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "currency",
  {
    data_type => "enum",
    default_value => "USD",
    extra => { list => ["USD", "EUR", "GBP"] },
    is_nullable => 1,
  },
  "trial_period_type",
  {
    data_type => "enum",
    extra => { list => ["day", "week", "month", "quarter", "year"] },
    is_nullable => 1,
  },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "is_featured",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pid>

=back

=cut

__PACKAGE__->set_primary_key("pid");

=head1 RELATIONS

=head2 packs

Type: has_many

Related object: L<Schema::Result::Pack>

=cut

__PACKAGE__->has_many(
  "packs",
  "Schema::Result::Pack",
  { "foreign.pid" => "self.pid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 product_downgrades_downgraded_pids

Type: has_many

Related object: L<Schema::Result::ProductDowngrade>

=cut

__PACKAGE__->has_many(
  "product_downgrades_downgraded_pids",
  "Schema::Result::ProductDowngrade",
  { "foreign.downgraded_pid" => "self.pid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 product_downgrades_parent_pids

Type: has_many

Related object: L<Schema::Result::ProductDowngrade>

=cut

__PACKAGE__->has_many(
  "product_downgrades_parent_pids",
  "Schema::Result::ProductDowngrade",
  { "foreign.parent_pid" => "self.pid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 product_upgrades_parent_pids

Type: has_many

Related object: L<Schema::Result::ProductUpgrade>

=cut

__PACKAGE__->has_many(
  "product_upgrades_parent_pids",
  "Schema::Result::ProductUpgrade",
  { "foreign.parent_pid" => "self.pid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 product_upgrades_upgraded_pids

Type: has_many

Related object: L<Schema::Result::ProductUpgrade>

=cut

__PACKAGE__->has_many(
  "product_upgrades_upgraded_pids",
  "Schema::Result::ProductUpgrade",
  { "foreign.upgraded_pid" => "self.pid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 subscriptions

Type: has_many

Related object: L<Schema::Result::Subscription>

=cut

__PACKAGE__->has_many(
  "subscriptions",
  "Schema::Result::Subscription",
  { "foreign.pid" => "self.pid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fids

Type: many_to_many

Composing rels: L</packs> -> fid

=cut

__PACKAGE__->many_to_many("fids", "packs", "fid");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-05-28 15:58:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MmxD96Nd8drLycmpGJq0sA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
