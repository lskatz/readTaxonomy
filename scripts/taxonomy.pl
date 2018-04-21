#!/usr/bin/env perl

use strict;
use warnings;
use BerkeleyDB;
use Getopt::Long qw/GetOptions/;
use Data::Dumper;

sub logmsg{print STDERR "$0: @_\n";}

exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help dbpath=s)) or die $!;
  $$settings{dbpath}||="taxonomy.db3";

  die usage() if(!@ARGV || $$settings{help});

  my $db;
  if(-e $$settings{dbpath}){
    $db=readTaxonomyDb($$settings{dbpath},$settings);
  } else {
    $db = loadTaxonomy($ARGV[0],$$settings{dbpath},$settings);
  }

  my ($key,$value)=each(%$db);
  die Dumper [$key,$value];

}

sub loadTaxonomy{
  my($db,$dbpath,$settings)=@_;
  my $nodes="$db/nodes.dmp";
  my $names="$db/names.dmp";
  my(%nodes,%names);
  tie %nodes, "BerkeleyDB::Hash",
      -Filename => $dbpath,
      -Flags    => DB_CREATE
      or die "Cannot open file $dbpath: $! $BerkeleyDB::Error\n" ;

  open(my $namesFh, $names) or die "ERROR: could not read $names.dmp: $!";
  while(my $line=<$namesFh>){
    $line=~s/^\s*|\s*$//g; # trim
    $line=~s/^\||\|$//g;   # pipe trim
    $line=~s/^\s*|\s*$//g; # trim
    $line=~s/^\||\|$//g;   # pipe trim
    my @F=split(/\t\|\t/,$line);
    $names{$F[0]}=\@F;
  }
  close $namesFh;

  open(my $nodesFh, $nodes) or die "ERROR: could not read $nodes.dmp: $!";
  while(my $line=<$nodesFh>){
    $line=~s/^\s*|\s*$//g; # trim
    $line=~s/^\||\|$//g;   # pipe trim
    $line=~s/^\s*|\s*$//g; # trim
    $line=~s/^\||\|$//g;   # pipe trim
    my @F=split(/\t\|\t/,$line);
    $nodes{$F[0]}=[@F,@{ $names{$F[0]} }];
  }
  close $nodesFh;
  return \%nodes;
}

sub readTaxonomyDb{
  my($db,$settings)=@_;

  my %nodes;

  tie %nodes, "BerkeleyDB::Hash",
      -Filename => $db,
      -Flags    => DB_RDONLY
      or die "Cannot open file $db: $! $BerkeleyDB::Error\n" ;

  return \%nodes;
}

sub usage{
  "This script is a proof of concept for creating a BerkeleyDb out of a taxonomy database
  You can obtain the db from ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
  Usage: $0 taxonomydir/
  --dbpath   taxonomy.db3  The path to the database
  "
}
