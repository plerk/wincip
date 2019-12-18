use strict;
use warnings;
use 5.010;
use JSON::PP ();
use File::Glob qw( bsd_glob );
use Path::Tiny qw( path );

foreach my $dockerfile ( sort map { path($_) } bsd_glob 'versions/*/Dockerfile' )
{
  say $dockerfile;
  my $meta = JSON::PP->new->decode($dockerfile->parent->child('meta.json')->slurp_raw);
  
  {
    my @cmd = ('docker', 'build', -f => "$dockerfile");
    push @cmd, -t => "plicease/wincip:$_" for @{ $meta->{tags} };
    push @cmd, '.';
  
    say "+@cmd";
    system @cmd;
    die if $?;
  }
  
  foreach my $tag (@{ $meta->{tags} })
  {
    foreach my $try (1..10)
    {
      my @cmd = ('docker', 'push', "plicease/wincip:$tag");
      
      say "[try $try]";
      say "+@cmd";
      system @cmd;
      if($?)
      {
        die if $try == 10;
      }
      else
      {
        last;
      }
    }
  }
}
