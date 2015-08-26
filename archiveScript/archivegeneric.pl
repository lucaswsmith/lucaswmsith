#!/usr/bin/perl
# This is a general script that can be used to archive any of the drives
# Needs to be called with the same name as the files in the folder
# eg. ./archivegeneric.pl general {perm) 
# which would be read in a file called generalarchivedata.txt
# The format of the file is source directory, destination directory - does not create the directory
# perm switch is if you want to propagate permissions down the tree from root folder
#### TO DO ####
# Backslash escape more characters - bit hit and miss, at the moment doing - space, open and close parentheses and ampersand
# Clean up some of the code into subroutines
# What happens if a file path has a comma - line 49 - modify to be ,/mnt but might have to re-prepend that path

# Check that the right number of arguments have been provided
if ( @ARGV < "1" || @ARG > "3" ) {
	die "Number of arguments must be one\n";
	}

# Read the drive - used for logging and reading in file in this instance - used for mounting in transfer deletion script
$drive=$ARGV[0];

# Initialise some variables
my @resultsarray;
my @rmarray;

# Configure date for log files
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900; ## $year contains no. of years since 1900, to add 1900 to make Y2K compliant
my @month_abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
$timenow="$month_abbr[$mon]-$mday\_$hour-$min-$sec";

# Open the file to read in the directories for archiving
open FILE, "$drive" . "archivedata.txt" or die $!;

# Open the file for logging
open OUTFILE, "+>>", "results/" . "$drive" . "results$timenow.txt" or die $!;

# Process each line of the file
while (<FILE>) {
# If it doesn't begin with a hash or is blank...
	if ($_ !~ m/^#/) {
        if ($_ !~ m/^$/) {
# Clean the new line off the end and backslash escape some characters        
        chomp($_);
		$_ =~ s/\s/\\\ /g;
		$_ =~ s/\(/\\\(/g;
		$_ =~ s/\)/\\\)/g;
		$_ =~ s/\&/\\\&/g;
# Split on comma         
		@array = split(',',$_);
# If the source directory does not exist, create it
			if(! -d $array[1]) {
				`mkdir -pv $array[1];`
			}
# This is unique to M&C and how the archive server is structured, this takes the 4th level deep folder and recurses those permissions if you have the switch
            @path = split('/',@array[1]);
            $chmodcommand = "chmod -R --reference=@path[0]\/@path[1]\/@path[2]\/@path[3]\/@path[4] @path[0]\/@path[1]\/@path[2]\/@path[3]\/@path[4]";
# Generate the rsync command
            $command = "rsync -rulDvX @array[0]/ $array[1]";
# Size the folder 			
            $dfsize = `du -sh $array[0]`;
			print "$command and $chmodcommand\n";
# Execute the command and get only the return code - this prints all the info to screen but is not captured by the logs
            $returncode = system($command);
# If return code is not zero command failed
            if ($returncode != 0) {
			push(@resultsarray, "***$array[0] was not backed up succesfully***");
				my $delattempts = "";
			} else {
				push(@resultsarray, "$array[0] was backed up succesfully to $array[1] - $dfsize");
# The format of this command reruns the rm command until it is successful - if doing this automatically would change 
# this to a number as it might otherwise run indefinitely
                push(@rmarray, "rm -rvf $array[0]/*\; while \[ \$\? -ne 0 \]\; do rm -rvf $array[0]/*\; done");
			}
# Reset dfsize, should be using proper scoping here but didn't know about that when I wrote this
            $dfsize ="";
	}
	}
}

# Print the results of each line to the results file
foreach (@resultsarray) {
	print OUTFILE "$_\n";
	print "$_\n";
	}

# If the perm argument is set, set the permissions on the fourth level deep
if ($ARGV[1] =~ m/^perm$/) {
    print "Setting Permissions on $chmodcommand\n";
    `$chmodcommand`;
}

# This is the section to print the removal commands
# Print the commands if you press yes - I was missing it too often so it prints them anyway. Can suppress with n or anything else (that isn't y).
print "\nDo you want me to print the rm commands? (y or n)\n";
my $rmcommands = "y";
eval {
  local $SIG{ALRM} = sub { die "alarm\n" };
  alarm 5;
  print "Remark: \n";
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
