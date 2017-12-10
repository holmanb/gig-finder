#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use local::lib;
use YAML::Tiny;
use LWP::Simple;
use Getopt::Long qw(GetOptions);

# Getting and hanlding cli options
my $clear_cache;
my $dry_run;
my $past;
my $help;
GetOptions(
       "clear_cache"|"c" => \$clear_cache,
       "past"|"p" => \$past,
       "dry_run"|"d" => \$dry_run,
       "help"|"h" => \$help,
) or die "Usage: $0 --one_time --clear_cache";

# Dry run used for dependency checking on the install script
if($dry_run){
        say "Dry run, dependencies properly installed.";
}

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
        foreach my $find_item (@$find){

                if($html =~ /$find_item/){
                        
                        # Save keywords for later
                        push(@keywords, $find_item);
                }
        }

        # Search for excluded items from config
        foreach my $exclude_item (@$exclude){

                if($html =~ /$exclude_item/) {
                        return ();
                }
        }
        return @keywords;
}


sub main{
        
        # Open the config
        my $yaml = YAML::Tiny->read('.config.yml');	

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
                        my @locations = $profile_value->{location_urls};
                        for(my $j=0;$j<scalar(@locations);$j++){
                                my $config_urls = $profile_value->{location_urls}[$j];
                                say "Searching $config_urls";

                                # Search given website for interesting urls
                                my @potential_opportunities = filter_craigslist(get_links($config_urls, $config_urls));
                                foreach my $opportunity (@potential_opportunities){
                                        
                                        # Match found! 
                                        my @keywords = keyword_search($opportunity, ($profile_value->{keywords}->{find}), $profile_value->{keywords}->{exclude});
                                        if(@keywords){
                                               push @found_jobs, $opportunity; 
                                               say "Found a job!! keywords[". join(", ", @keywords) ."] $opportunity"
                                        }
                                }
                        }		
                }	
                
                # Found some jobs
                if(scalar(@found_jobs)){

                        # Compare to old jobs 
                        open(DATA, "<.cache") or say "No cache found";
                        while(<DATA>){
                               for my $i (0..scalar(@found_jobs)-1){
                                        if($_ eq $found_jobs[$i]){
                                                splice(@found_jobs, $i, 1);
                                                say "match found, removing $found_jobs[$i]";
                                        }
                               }
                        }
                        # Send emails and stuff
                        my @emails=$person_value->{email};
                        my @tags = ("Your Strangely Human Perl Script", "Your Anonymous Benefactor", "Your Null Friend", "Your Most Favoured Servant");
                        my $msg="Hey $person_value->{name}!\n\nCheck out these sweet jobs I found for you!\n\n";
                        $msg.=join("\n", @found_jobs)."\n\nSincerely,\n\n".$tags[int(rand(scalar(@tags)-1))];

                        for(my $i=0;$i<scalar(@emails);$i++){
                                
                                # Sending emails
                                say "Sending emails to $person_value->{email}[$i]";
                                sendEmail($person_value->{email}[$i], "Found a job!",$msg);
                        }
                }else{
                        say "\nNo jobs this time :(";
                }
        }
}

