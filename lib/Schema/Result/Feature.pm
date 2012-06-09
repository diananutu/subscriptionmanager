use utf8;
package Schema::Result::Feature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Feature

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<features>

=cut

__PACKAGE__->table("features");

=head1 ACCESSORS

=head2 fid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 price

  data_type: 'float'
  default_value: 0
  is_nullable: 0

=head2 feature_name

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=cut

__PACKAGE__->add_columns(
  "fid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "price",
  { data_type => "float", default_value => 0, is_nullable => 0 },
  "feature_name",
  { data_type => "varchar", is_nullable => 1, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</fid>

=back

=cut

__PACKAGE__->set_primary_key("fid");

=head1 RELATIONS

=head2 packs

Type: has_many

Related object: L<Schema::Result::Pack>

=cut

__PACKAGE__->has_many(
  "packs",
  "Schema::Result::Pack",
  { "foreign.fid" => "self.fid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pids

Type: many_to_many

Composing rels: L</packs> -> pid

=cut

__PACKAGE__->many_to_many("pids", "packs", "pid");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-05-22 12:25:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ksbv6qtHK+zBKA0ZGfvCZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
