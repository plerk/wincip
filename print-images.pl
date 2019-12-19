use strict;
use warnings;
use 5.010;
use Capture::Tiny qw( capture );
use Term::Table;
use JSON::PP ();

my($out,$err) = capture {
  system 'docker', 'image', 'ls', '--format', '{{json .}}';
};

my @images = map { JSON::PP->new->decode($_) } split /\n/, $out;

my %images;
my %size;

foreach my $image (@images)
{
  next unless $image->{Repository} eq 'plicease/wincip';
  next unless $image->{Tag} ne '<none>';
  $size{$image->{ID}} = $image->{Size};
  if($image->{Tag} =~ /^(5\.[0-9]+)/)
  {
    push @{ $images{$1}->{$image->{ID}} }, $image->{Tag};
  }
  else
  {
    push @{ $images{$image->{Tag}}->{$image->{ID}} }, $image->{Tag};
  }
}

my @table;

foreach my $major (sort keys %images)
{
  foreach my $id (keys %{ $images{$major} })
  {
    my $size = $size{$id};
    my @tags = @{ $images{$major}->{$id} };
    my($full) = sort { length $b <=> length $a } @tags;
    my %tags = map { $_ => 1 } @tags;
    delete $tags{$full};
    @tags = sort keys %tags;
    push @table, [
      $major,
      $id,
      $size,
      $full,
      join(', ', @tags),
    ];
  }
}

my $table = Term::Table->new( rows => \@table );
say for $table->render;