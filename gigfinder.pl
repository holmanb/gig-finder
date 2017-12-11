#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Cwd;
use local::lib;
use YAML::Tiny;
use LWP::Simple;
use Getopt::Long qw(GetOptions);


# Let the fun begin! 
&main;


# standardize_urls
# Reduces all URLs to a standard format
#
# Takes:
# - $url - a string that should hold a url
# Returns:
# - $source - a formatted url
##
sub standardize_urls {
	my $source = $_[0];
        my $site = $_[1];
	my $declaration = "";
	return ($declaration) if ($source =~ /^(mailto:|telnet:|callto:)/);
	if($source=~ /^\//) {
		$source = $site . $source;
	}
	$source =~ s/[\#?].*//;
	return $source;
}


# filter_craigslist
# removes all URLS that are not *.html
#
# Takes:
# - @urls - an array with scalars of urls
# Returns:
# - @goodness - sweet, sweet, chocolatey goodness
##
sub filter_craigslist{
	my @urls = @_;
	my @goodness;
	my $re = "\.html";

        # Check for *.html
	for my $url(@urls){
		if($url =~ /$re/){
			push(@goodness, $url);
		}
	}
	return @goodness;
}


# get_links
# extract links from the urls in the array passed to the site, also filters self-referencing pages
#
# Takes:
# - @inputs - a list of urls
# Returns:
# - @interesting_urls - an array of standardized, 
##
sub get_links{
	my $html;
	my @inputs=$_[0];
        my $site = $_[1];
	my @urls;

	# Grab a web page and check the links 
	foreach my $page(@inputs){
		$html = get($page);
		@urls = $html =~ /\shref="?([^\s>"]+)/gi;
	}

	my %counter;
	my @externals = ();
	my $full;

	# Remove sites that start with the same url as the input
	foreach my $url(@urls){
		$full = standardize_urls($url,$site);
		next unless($full);
		
                # Save sites that 
		if($full !~ /^$site/) {
			push @externals, $full;
			$counter{$full}++;
		}
	}

	# Print and return urls
	my @interesting_urls;
	foreach my $url(keys %counter){
		push(@interesting_urls, $url);
	}
	return @interesting_urls;
}


# get_links
# Uses ssmtp to send an email
#
# Takes:
# - $destination - email address
# - $subject - email subject
# - $body - email body
# Returns:
# - no output
##
sub sendEmail{

	my ($destination, $subject, $body) = @_;

        # Create and display the shell command used to send the email
	my $command="echo \'$body\' | mail -s \'$subject\' $destination";
	my $output = qx($command);
}


# keyword_search
# does a keyword search based on a hash of keywords passed in: returns true if it passes the test 
# 
# Takes:
# - $found_url - web page to be scraped
# - $find - desirable keywords, one of these keywords must be found, or () is returned
# - $exclude - undesirable keywords, if one of these keywords is found, () is returned
# Returns:
# - @keywords - a list of the desirable keywords that were found in this webpage
##
sub keyword_search{
	my ($found_url, $find, $exclude) = @_;
        my @keywords=();

        # getting the final webpage
	my $html = get($found_url);
        
         
        # Search for attractive items from config
        if ($html){
                foreach my $find_item (@$find){

                        if($html =~ /$find_item/){
                                
                                # Save keywords for later
                                push(@keywords, $find_item);
                        }
                }

                # Search for excluded items from config
                foreach my $exclude_item (@$exclude){

                        if($html =~ /$exclude_item/i) {
                                return ();
                        }
                }
        }else{
                say "\$html is unitialized for some reason, might want to double check the url given: [$found_url]";
        }
        return @keywords;
}

# main 
# the primary execution block of the code
#
# Takes: 
# - prayers and hope
# Returns:
# - exit codes
# - dividends
##
sub main{

	 # Getting and handling cli options
	my $clear_cache;
	my $dry_run;
	my $past;
	my $help;
	my $no_email;
	my $file;
	my $directory='config';

	# Defining options
	GetOptions(
	       "clear_cache"|"c" => \$clear_cache,
	       "past"|"p" => \$past,
	       "dry_run"|"d" => \$dry_run,
	       "no_email"|"n"=> \$no_email,
	       "file"|"f"=> \$file,
	       "location"|"l"=>\$directory,
	       "help"|"h" => \$help,
	) or die "Usage: $0 --past --clear_cache";
	
	# Help flag	
	if($help){
		say "NAME";
		say "\t$0 - a utility for sending job opportunities straight to your inbox\n";
		say "SYNOPSIS";
		say "\t$0 [clear_cache|c] [past|p] [file[=FILE]|f [FILE]] [location[=DIRECTORY]|[l [DIRECTOR]] [dry_run|d] [help|h]\n";
		say "DESCRIPTION";
		say "\t$0 is a script for scraping the web for jobs that match a given configuration";
		say "\tfile.  The tool is intended to be able to scrape multiple websites, though its";
		say "\tcurrent implementation has only implimented searching the \'neighborhood\' of w-";
		say "\tbpages (graph theory).  This means that it will search the given urls for avail-";
		say "\table links, and it will search the websites linked to for keywords. This works ";		       
		say "\tquite well for sites such as craigslist and indeed. The script";
		say "\thas the additional ability to read from multiple \'profiles\' in the configura";
		say "\ttion file, and search each configuration for matching jobs.  This allows the ";
		say "\tuser to craft an exacting search of the jobs presented.  The configuration ";
		say "\tfile uses YAML format, which allows for ease of human and machine readability";
		say "\tThe example file given can be modified to suit your needs.  The script defaults";
		say "\tto running a single time and then exiting, though for periodic runs, a daemon ";
		say "\tsuch as cron would work quite nicely.\n";
		say "HISTORY";
		say "\t".'2017 - Written by Brett Holman (bpholman5@gmail.com).'."\n";
		say "OPTIONS";
		say "\t-c, --clear_cache";
		say "\t\tclears the history of previus jobs sent. This is the equivalent of deleating .cache\n";
		say "\t-p, --past";
		say "\t\tprints out the cached jobs that have been previously sent\n";
		say "\t-d, --dry_run";
		say "\t\tintended for use with the installer, but can be used with cache options\n";
		say "\t-n, --no_email";
		say "\t\tdo I really need to explain how this works?\n";
		say "\t-f FILE, --file=FILE";
		say "\t\tuse to specify a custom config file \n";
		say "\t-l DIRECTORY, --location=DIRECTORY";
		say "\t\tuse to specify a custom config directory location\n";
		say "\t-h, --help";
		say "\t\ta manual for those who prefer a higher-level understanding of what the code";
		say "\t\t is supposed to be doing\n";
		exit 0;
	}	

	# Dry run used for dependency checking on the install script
	if($dry_run){
		
		# Prints out links previously send to cache
		if($past){
			open(my $fh, "<", ".cache") or die "Cannot read from cache"; 
			my $row;
			say "Previously send items in cache:";
			while($row = <$fh>){
				say $row; 
			}
		}

		# Deletes the cache
		if($clear_cache){
			say "Cache cleared";
			unlink ".cache";
		}
		say "Dry run succeeded, dependencies are properly installed.";
		exit 0;
	}       
	
	# Get directory
	my $dir = cwd();
	
        # Open the config directory file location
	chdir $directory or die "configuration file location: $directory didn't exist";

	# Grab all available yaml files
	my @configs = glob("*.yml *.YAML");

	# If a file argument is given, override the default location and only search for that car 
	if($file){
		@configs=();
		push(@configs, $file);
		say "Checking the config files: $file";
	}else{
		say "Found: ".join(" ", @configs)." config files";
	}
	
	# Searches all of the config files
	foreach my $config_file (@configs){
		say "Checking for jobs using config: $config_file";
		my $yaml = YAML::Tiny->read($config_file);	

		# Get a reference to the first document
		my $config = $yaml->[0];

		# Loop through config  
		while (my($person_key, $person_value) = each %$config){
			say "Searching for jobs for $person_value->{name}";	
			
			my @found_jobs;

			# Search each profile
			my $profiles = $person_value->{profiles};
			while (my($key, $profile_value) = each %$profiles){
				
				# Get each location url in the config file
				my $locations = $profile_value->{location_urls};
				for(my $j=0;$j<scalar(@$locations);$j++){
					my $config_urls = $profile_value->{location_urls}[$j];
					say "Searching $config_urls";

					# Search given website for interesting urls
					my @potential_opportunities = filter_craigslist(get_links($config_urls, $config_urls));
					foreach my $opportunity (@potential_opportunities){
						
						# Match found! 
						my @keywords = keyword_search($opportunity, ($profile_value->{keywords}->{find}), $profile_value->{keywords}->{exclude});
						if(@keywords){
						       push @found_jobs, $opportunity; 
						       say "Found a job!! keywords[". join(", ", @keywords) ."]\t $opportunity";
						}
					}
				}		
			}	
			
			# Found some jobs
			if(scalar(@found_jobs)){

				# Return to working directory directory to write to cache
				chdir $dir or say "Coundn't return to working directory: the .cache file may end up getting written to the directory holding the config files";

				# Compare to old jobs 
				if(open(my $fh, "<", ".cache")){ 
					my $row;
					while($row = <$fh>){
					       for( my $i=0;$i<scalar(@found_jobs)-1;$i++){
							if(index($row, $found_jobs[$i]) != -1){
								splice(@found_jobs, $i, 1);
								say "looks like this one was already sent, not sending duplicate:$found_jobs[$i]";
							}
					       }
					}
					close($fh);

					# Save new opportunities to the file
					open(my $fh, ">>", ".cache") or say "Unable to write to cache";
					foreach (@found_jobs){
						say $fh $_;
					}
					close($fh);

				}else{
					
					# Generate cache
					say "No cache found";
					open($fh, ">>", ".cache") or say "Unable to write to cache";
					foreach (@found_jobs){
						say $fh $_;
						if($past){
							say $fh;
						}
					}
					close($fh);
					say "Wrote to cache";
				}
				
				# return to the config directory file location
				chdir $directory or die "config directory file location: $directory didn't exist";

				if(@found_jobs && !$no_email){

					# Send emails and stuff
					my @signatures = (
						"Strangely Human Perl Script", 
						"Anonymous Benefactor", 
						"Null Friend", 
						"Most Favoured Servant",
						"Morally Superior Djinni",
						"Wholesome Caretaker"
						);
					my @emails=$person_value->{email};
					my $msg="Hey $person_value->{name}!\n\nCheck out these sweet jobs I found for you!\n\n";
					$msg.=join("\n", @found_jobs)."\n\nSincerely,\n\nYour ".$signatures[int(rand(scalar(@signatures)))];
					
					# For sending to multiple emails
					for(my $i=0;$i<scalar(@emails);$i++){
						
						# Sending emails
						say "Sending emails to $person_value->{email}[$i]";
						sendEmail($person_value->{email}[$i], "Found a job!",$msg);
					}
				}elsif(@found_jobs){
					say "Not sending an email at this time";
				}else{
					say "No new jobs found.";
				}
			}else{
				say "\nNo jobs this time :(";
			}
		}
        }
}

