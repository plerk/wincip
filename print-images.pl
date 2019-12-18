use strict;
use warnings;
use 5.010;
use Capture::Tiny qw( capture );
use JSON::PP ();

my($out,$err) = capture {
  system 'docker', 'image', 'ls', '--format', '{{json .}}';
};

my @images = map { JSON::PP->new->decode($_) } split /\n/, $out;

my %images;

foreach my $image (@images)
{
  next unless $image->{Repository} eq 'plicease/wincip';
  next unless $image->{Tag} ne '<none>';
  if($image->{Tag} =~ /^(5\.[0-9]+)/)
  {
    push @{ $images{$1}->{$image->{ID}} }, $image->{Tag};
  }
  else
  {
    push @{ $images{$image->{Tag}}->{$image->{ID}} }, $image->{Tag};
  }
}

use YAML ();
print YAML::Dump(\%images);