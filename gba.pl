#!/usr/bin/perl

# Perl script to take a data file and execute several commands
# based on command line options:
#   Generates pairs of players from the file to battle
#   Ranks players by wins/losses or names
#   Shows old player match ups
#   Shows data file formatting

use strict;
use File::Basename;
use Getopt::Long;

# Usage variables
my $cmd = basename($0);
my $options = "  options:\n".
              "    -p, --pair    Generates pairs\n".
              "    -r, --rank    Shows ranking of players\n".
              "    -o, --old     Shows old player pairs\n".
              "    -f, --format  Shows data file format\n";
my $usage = "usage: $cmd [-p|-r|-o|-f] <data file>\n".$options;

# Index variables
my $indexName=1;
my $indexTeam=2;
my $indexWins=3;
my $indexLoss=4;
my $indexDiff=5;
my $indexPlay=6;

# Data storage variables
my %data;
my %pairs;

# Option variables
my $pair = 0;
my $rank = 0;
my $old = 0;
my $format = 0;
my $help = 0;

my $result = GetOptions(
  "help|usage" => \$help,   # print help and exit
  "pair"       => \$pair,   # generate new pairs
  "rank"       => \$rank,   # rank players by score 
  "old"        => \$old,    # show prior pairs
  "format"     => \$format  # show data file format
  );

# Check for proper formatting or asking for help
die "$usage\n" if($help);
die "$usage\n" if(@ARGV != 1 
                  or !$result 
                  or ($pair + $rank + $old + $format) > 1
                 );

$rank = 1 if($pair + $rank + $old + $format == 0);

if($format){
  &printFormat();
  exit(0);
}

# Check if file exists and is readable
my $dataFile = $ARGV[0];
die "$dataFile: no such file\n" if(! -e $dataFile);
open(FILE, '<',$dataFile) or die "$dataFile: cannot open for reading\n";

# Get hash that maps playerID to an array of data
while(<FILE>){
  chomp;
  next if m/^\s*\#/;
  next if m/^\s*$/;
  $data{$.-1}=[split/:/];   
}
close FILE;

#print "Key: $_ => Player: $@${$data{$_}}[1]\n" foreach(sort{$a <=> $b}keys%data);

# Generate pairs and print pretty version
if($pair){
  &genPairs();
  &printPretty();
}
# Print players in order of highest wins and differential
elsif($rank){
  &printRank();
}
# Print old player match ups
elsif($old){
  &printOld;
}

# Subroutine to print players in rank order
sub printRank(){
  my @ranking = sort byWinDiff keys %data;
  while(@ranking){
    my $player = shift @ranking;
    my $playerName = ${$data{$player}}[$indexName];
    next if($playerName eq "XXX");
    my $playerWins = ${$data{$player}}[$indexWins];
    my $playerLoss = ${$data{$player}}[$indexLoss];
    my $playerDiff = ${$data{$player}}[$indexDiff];
    print "$playerName\t",
          "Wins: $playerWins ",
          "Losses: $playerLoss ",
          "Diff: $playerDiff\n";
  }
}

# Subroutine to print data file format
sub printFormat(){
  print "Data file format:\n";
  print "<PLAYERID>:<PLAYERNAME>:<TEAMNAME>:<WINS>:<LOSSES>:<DIFFERENTIAL>:<PLAYED>\n";
  print "#<COMMENT>\n\n";
  print "Variable Types:\n";
  print "<PLAYERID>: Integer\n<PLAYERNAME>: String\n";
  print "<TEAMNAME>: String\n<WINS>: Integer\n<LOSSES>: Integer\n";
  print "<DIFFERENTIAL>: Integer\n";
  print "<PLAYED>: Comma-separated list of Integers (i.e. 1,2,13,3)\n";
  print "<COMMENT>: String\n";
}

# Subroutine to print the old player match ups
sub printOld(){
  my @playerIDs = sort{$a<=>$b}keys%data;
  pop @playerIDs;
  while(@playerIDs){
    my $player = shift @playerIDs;
    my $playerName = ${$data{$player}}[$indexName];
    print "$playerName:\n";
    my @pastPlayers = split/,/,${$data{$player}}[$indexPlay];
    shift @pastPlayers;
    my $i = 1;
    while(@pastPlayers){
      my $pastPlayer = shift @pastPlayers;
      my $pastPlayerName = ${$data{$pastPlayer}}[$indexName];
      print "    Battle $i: $pastPlayerName\n";
      $i++;
    }
  }
}

# Subroutine to print player names and teams
sub printPretty(){
  print "\n";
  my @pairIDs = sort{$a<=>$b}keys%pairs;
  while(@pairIDs){
    my $player = shift @pairIDs;
    my $player1Team = ${$data{$player}}[$indexTeam];
    my $player1Name = ${$data{$player}}[$indexName];
    my $player2Team = ${$data{$pairs{$player}}}[$indexTeam];
    my $player2Name = ${$data{$pairs{$player}}}[$indexName];
    print "$player1Team ($player1Name) vs. $player2Team ($player2Name)\n\n";
  }
}

# Subroutine to generate pairs of players
sub genPairs(){
  my @playerIDs = sort{$a<=>$b}keys%data;
  my $playerNum = @playerIDs;
  while(@playerIDs){
    my $player = shift @playerIDs;
    my @pData = @{$data{$player}};
    my @played = split/,/,$pData[$indexPlay];
    #LASER MARK
    my $randID;
    my $index;
    do{
      $randID = int(rand($playerNum));
      $index = 0;
      $index++ until $playerIDs[$index] == $randID or 
                     $index == $playerNum; 
    } while(grep /^$randID$/,@played or $index == $playerNum or $randID == 0);
    splice @playerIDs,$index,1;
    #print "Played: @played\nRand: $randID\n\n";
    $pairs{$player}=$randID;
  }
}

# Sort players by wins/differential/name
sub byWinDiff{
  ${$data{$b}}[$indexWins] <=> ${$data{$a}}[$indexWins]
    or
  ${$data{$b}}[$indexDiff] <=> ${$data{$a}}[$indexDiff]
    or
  ${$data{$a}}[$indexName] cmp ${$data{$b}}[$indexName]
}
