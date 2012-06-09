package Subscription::Helpers;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';



sub register {

    my ($self, $app) = @_;

    # MD5 HEX encoding
    $app->helper(checksum => sub {
        my ($self, $str) = @_;
        return 0 unless $str;

        use Mojo::Util qw/sha1_sum/;
        return sha1_sum $str;
    });


    # File Upload
    $app->helper(upload_file => sub {
      my ($self, $file, $uid ) = @_;
      
      use FileHandle;
      use POSIX;
      use YAML::Tiny;
      
      if ( my $upload = $file ) {
        my $filename = $upload->filename;
        my $new_filename;
        my $location;
        my @split_file;
        if($filename =~ /\.(css|jpg|jpeg|png|gif)/i){
          if ( defined($uid) && $uid && $filename =~ /\.(jpg|jpeg|png|gif)/i ){
            @split_file = split( /\./, $filename );
            $new_filename = $uid . "." . $split_file[-1];
            $location = $self->app->{config}->{uploads_dir};
          } else {
            $new_filename = $filename;
            @split_file = split( /\./, $filename );
            $location = "/assets/css/";
          }
          my $asset;
          if ( ref( $upload->asset ) ne 'Mojo::Asset::File' ) {
            $asset = Mojo::Asset::File->new( path => POSIX::tmpnam );
            $asset->add_chunk( $upload->asset->slurp );
          } 
          else {
            $asset = $upload->asset;
          }
          
          $asset->cleanup(1);
          
          my $fh = FileHandle->new();
          $fh->open( sprintf( '<%s', $asset->path ) )
            || die "could not open attachment file\n";
          my $fh2 = FileHandle->new();
          
          $fh2->open(
              sprintf( '>%s',
                 $self->app->static->paths->[0] . $location .$new_filename )
          ) || die "could not open att file\n";
          while (<$fh>) {
              print $fh2 $_;
          }
          
          $fh->close;
          $fh2->close;
          
          if ($new_filename =~ /\.(css)/i) {
            my $yaml = YAML::Tiny->new;
            $yaml = YAML::Tiny->read('conf/styles.yaml');

            my $max_value = $yaml->[0]->{max_value} + 1;

            my $hash = {
                text  => $split_file[0],
                value => '/assets/css/' . $new_filename,
                img   => '/assets/img/cssdefault.png',
            };
            $yaml->[0]->{styles_data}->{$max_value} = $hash;
            $yaml->[0]->{max_value} = $max_value;
            $yaml->write('conf/styles.yaml');
          }
          else {
            return $location .$new_filename;
          }
          push @{ $self->session->{notice_messages} }, 'Upload completed';
        }
        else {
          push @{ $self->session->{error_messages} },
            'Please upload a valid file';
        }
      }
    });

}

1;

__END__