#!/usr/bin/perl
#This is a general script that can be used to archive any of the drives
#Needs to be called with the same name as the files in the folder
#eg. ./archivegeneric.pl general {perm) 
#perm switch is if you want to propagate permissions down the tree from root folder

#Check that the right number of arguments have been provided
if ( @ARGV < "1" || @ARG > "3" ) {
	die "Number of arguments must be one\n";
	}

$drive=$ARGV[0];

my @resultsarray;
my @rmarray;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900; ## $year contains no. of years since 1900, to add 1900 to make Y2K compliant
my @month_abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
$timenow="$month_abbr[$mon]-$mday\_$hour-$min-$sec";
open FILE, "$drive" . "archivedata.txt" or die $!;
open OUTFILE, "+>>", "results/" . "$drive" . "results$timenow.txt" or die $!;

while (<FILE>) {
	if ($_ !~ m/^#/) {
        if ($_ !~ m/^$/) {
		chomp($_);
		$_ =~ s/\s/\\\ /g;
		$_ =~ s/\(/\\\(/g;
		$_ =~ s/\)/\\\)/g;
		$_ =~ s/\&/\\\&/g;
		@array = split(',',$_);
			if(! -d $array[1]) {
				`mkdir -pv $array[1];`
			}
                        @path = split('/',@array[1]);
                        $chmodcommand = "chmod -R --reference=@path[0]\/@path[1]\/@path[2]\/@path[3]\/@path[4] @path[0]\/@path[1]\/@path[2]\/@path[3]\/@path[4]";
			$command = "rsync -rulDvX @array[0]/ $array[1]";
			$dfsize = `du -sh $array[0]`;
			print "$command\n";
			$returncode = system($command);
			if ($returncode != 0) {
			push(@resultsarray, "***$array[0] was not backed up succesfully***");
				my $delattempts = "";
				
			} else {
				push(@resultsarray, "$array[0] was backed up succesfully to $array[1] - $dfsize");
				push(@rmarray, "rm -rvf $array[0]/*\; while \[ \$\? -ne 0 \]\; do rm -rvf $array[0]/*\; done");
			}
			$dfsize ="";
	}
	}
}

foreach (@resultsarray) {
	print OUTFILE "$_\n";
	print "$_\n";
	}

if ($ARGV[1] =~ m/^perm$/) {
print "Setting Permissions on $chmodcommand\n";
`$chmodcommand`;
}

#This is the section to print the removal commands

print "\nDo you want me to print the rm commands? (y or n)\n";
my $rmcommands = "y";
eval {
  local $SIG{ALRM} = sub { die "alarm\n" };
  alarm 5;
  print "Remark: ";
  chomp($rmcommands = <STDIN>);
};
alarm 0;
#$rmcommands = <STDIN>;
if ($rmcommands =~ 'y') {
foreach (@rmarray) {
	$_ =~ s/\!/\\\!/g;
	print "$_\n";
	}
}
