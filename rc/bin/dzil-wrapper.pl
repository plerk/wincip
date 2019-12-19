BEGIN {
  @INC = qw(
    c:/dzil/perl/site/lib
    c:/dzil/perl/vendor/lib
    c:/dzil/perl/lib
  );
};

use strict;
use warnings;
use 5.030;
use Env qw( @PATH );
use File::Which qw( which );
use Path::Tiny qw( path );

@PATH = grep !/^c:\\(cache\\)?perl\\/i, @PATH;

unshift @PATH, 'c:\\dzil\\perl\\site\\bin',
               'c:\\dzil\\perl\\bin',
               'c:\\dzil\\c\\bin';

if(defined $ENV{PERL_MB_OPT} || defined $ENV{PERL_MM_OPT})
{
  unshift @PATH, 'c:\\cache\\dzil\\bin';
  $ENV{PERL5LIB}            = 'c:/cache/dzil/lib/perl5';
  $ENV{PERL_LOCAL_LIB_ROOT} = 'c:/cache/dzil';
  $ENV{PERL_MB_OPT}         = '--install_base c:/cache/dzil';
  $ENV{PERL_MM_OPT}         = 'INSTALL_BASE=c:/cache/dzil';
}

my $program = shift @ARGV;
die "no program given" unless defined $program;
my $exe = lc which $program;
die "no $program found" unless defined $exe;

say "+$exe @ARGV";
system $exe, @ARGV;
if($? == -1)
{ die "system failed $!" }
elsif($?)
{ die "command failed" }

system 'rmdir /s/q c:\\tmp\\cpanm';
