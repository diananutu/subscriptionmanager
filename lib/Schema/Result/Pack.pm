use utf8;
package Schema::Result::Pack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Pack

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pack>

=cut

__PACKAGE__->table("pack");

=head1 ACCESSORS

=head2 pid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 fid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "fid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</pid>

=item * L</fid>

=back

=cut

__PACKAGE__->set_primary_key("pid", "fid");

=head1 RELATIONS

=head2 fid

Type: belongs_to

Related object: L<Schema::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "fid",
  "Schema::Result::Feature",
  { fid => "fid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-05-22 12:25:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hbal+5LA27uU13uUtAUJWg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
