#!/usr/bin/perl

# Perl script to take a data file and execute several commands
# based on command line options:
#   Generates pairs of players from the file to battle
#   Ranks players by wins/losses or names
#   Shows old player match ups
#   Shows data file formatting

use File::Basename;
use Getopt::Long;

# Usage variables
$cmd = basename($0);
$options = "  options:\n".
           "    -p, --pair    Generates pairs\n".
           "    -r, --rank    Shows ranking of players\n".
           "    -o, --old     Shows old player pairs\n".
           "    -f, --format  Shows data file format\n";
$usage = "usage: $cmd [-p|-r|-o|-f] <data file>\n".$options;

# Index variables
$indexName=1;
$indexTeam=2;
$indexWins=3;
$indexLoss=4;
$indexDiff=5;
$indexPlay=6;

# Option variables
$pair = 0;
$rank = 0;
$old = 0;
$format = 0;
$help = 0;

$result = GetOptions(
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
$dataFile = $ARGV[0];
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
  @ranking = sort byWinDiff keys %data;
  while(@ranking){
    $player = shift @ranking;
    $playerName = ${$data{$player}}[$indexName];
    next if($playerName eq "XXX");
    $playerWins = ${$data{$player}}[$indexWins];
    $playerLoss = ${$data{$player}}[$indexLoss];
    $playerDiff = ${$data{$player}}[$indexDiff];
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
  @playerIDs = sort{$a<=>$b}keys%data;
  pop @playerIDs;
  while(@playerIDs){
    $player = shift @playerIDs;
    $playerName = ${$data{$player}}[$indexName];
    print "$playerName:\n";
    @pastPlayers = split/,/,${$data{$player}}[$indexPlay];
    shift @pastPlayers;
    $i = 1;
    while(@pastPlayers){
      $pastPlayer = shift @pastPlayers;
      $pastPlayerName = ${$data{$pastPlayer}}[$indexName];
      print "    Battle $i: $pastPlayerName\n";
      $i++;
    }
  }
}

# Subroutine to print player names and teams
sub printPretty(){
  print "\n";
  @pairIDs = sort{$a<=>$b}keys%pairs;
  while(@pairIDs){
    $player = shift @pairIDs;
    $player1Team = ${$data{$player}}[$indexTeam];
    $player1Name = ${$data{$player}}[$indexName];
    $player2Team = ${$data{$pairs{$player}}}[$indexTeam];
    $player2Name = ${$data{$pairs{$player}}}[$indexName];
    print "$player1Team ($player1Name) vs. $player2Team ($player2Name)\n\n";
  }
}

# Subroutine to generate pairs of players
sub genPairs(){
  @playerIDs = sort{$a<=>$b}keys%data;
  $playerNum = @playerIDs;
  while(@playerIDs){
    $player = shift @playerIDs;
    @pData = @{$data{$player}};
    @played = split/,/,$pData[$indexPlay];
    #LASER MARK
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
