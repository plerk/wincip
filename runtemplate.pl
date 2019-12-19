use strict;
use warnings;
use 5.010;
use Template;
use Path::Tiny qw( path );
use JSON::PP ();

our %vars = (
  mingw_get_version => '0.6.2-mingw32-beta-20131004-1',
  cmake_version     => '3.16.1',
  go_version        => '1.13.2',
  dzil_perl_version => '5.30.1.1',
);

path('versions')->remove_tree if -d 'versions';

my $tt = Template->new;
my $tmpl = path('rc/Dockerfile.tt')->slurp_utf8;

sub generate
{
  my($dockerfile, $vars, %meta) = @_;
  
  say $dockerfile;
  $dockerfile->parent->mkpath;
  $tt->process('rc/Dockerfile.tt', \%vars, "$dockerfile") or die $tt->error;
  
  %meta = ( %$vars, %meta );
  
  my $json_file = $dockerfile->parent->child('meta.json');
  $json_file->spew_raw(JSON::PP->new->indent(1)->encode(\%meta));
}

foreach my $tag (qw( default ))
{
  my $dockerfile = path('versions')->child($tag)->child('Dockerfile');
  $dockerfile->parent->mkpath;
  
  local %vars = (
    %vars,
    rust_arch => 'x86_64-pc-windows-gnu',
    go_arch   => 'amd64',
  );
  
  generate( $dockerfile, \%vars, tags => [ $tag ] );
}

{

  my $current_strawberry_version = '5.30.1.1';
  my @old_strawberry_versions = qw(  5.28.2.1 5.26.3.1 5.24.4.1 5.22.3.1 5.20.3.3 5.18.4.1 5.16.3.1 5.14.4.1 );

  foreach my $strawberry_version ($current_strawberry_version, @old_strawberry_versions)
  {
    foreach my $strawberry_arch (qw( 32bit 64bit ))
    {
      local %vars = (
        %vars,
        strawberry_version => $strawberry_version,
        strawberry_arch    => $strawberry_arch,
      );

      our @tags = ();

      {
        my @versions = split /\./, $strawberry_version;

        $vars{make} = $versions[1] >= 26 ? 'gmake' : 'dmake';

        my $ver = shift @versions;
        foreach my $number (@versions)
        {
          $ver .= ".$number";
          push @tags, "$ver-sb-$strawberry_arch";
          push @tags, "$ver-$strawberry_arch";
          push @tags, "$ver-sb" if $strawberry_arch eq '64bit';
          push @tags, "$ver" if $strawberry_arch eq '64bit';
        }
      }
    
      @tags = sort { length $b <=> length $a || $a cmp $b } @tags;

      if($strawberry_version eq $current_strawberry_version)
      {
        {
          local %vars = (
            %vars,
            rust_arch => $strawberry_arch eq '32bit' ? 'i686-pc-windows-gnu' : 'x86_64-pc-windows-gnu',
          );
          delete $vars{go_version};
          local @tags = map { "$_-rust"} @tags;
          my $dockerfile = path('versions')->child($tags[0])->child('Dockerfile');
          generate( $dockerfile, \%vars, tags => \@tags );
        }
        
        {
          local %vars = (
            %vars,
            go_arch => $strawberry_arch eq '32bit' ? '386' : 'amd64',
          );
          delete $vars{rust_version};
          local @tags = map { "$_-go"} @tags;
          my $dockerfile = path('versions')->child($tags[0])->child('Dockerfile');
          generate( $dockerfile, \%vars, tags => \@tags );
        }
      }

      delete $vars{rust_version};
      delete $vars{go_version};

      my $dockerfile = path('versions')->child($tags[0])->child('Dockerfile');
      generate( $dockerfile, \%vars, tags => \@tags );
    }
  }
}