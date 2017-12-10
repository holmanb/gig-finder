#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use YAML::Tiny;
use local::lib;
use LWP::Simple;
my $site = "https://santafe.craigslist.org/search/acc";

# Reduce all URLs to standard format
sub standardize_urls {
	my $source = $_[0];
	my $declaration = "";
	return ($declaration) if ($source =~ /^(mailto:|telnet:|callto:)/);
	if($source=~ /^\//) {
		$source = $site . $source;
	}
	$source =~ s/[\#?].*//;
	return $source;
}

# Craigslist filter
sub filterCraigslist{
	my @urls = @_;
	my @goodness;
	my $re = "\.html";
	for my $url(@urls){
		if($url =~ /$re/){
			push(@goodness, $url);
		}
	}
	return @goodness;
}

# Get outward facing links that may appear interesting
sub getLinks{
	my $html;
	my @inputs=@_;
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
		$full = standardize_urls($url);
		next unless($full);
		
                # Save sites that 
		if($full !~ /^$site/) {
			push @externals, $full;
			$counter{$full}++;
		}
	}

	# Print and return urls
	my @interesting_urls;
	#print "Websites found on @inputs\n";
	foreach my $url(keys %counter){
	#	print "$url\n";
		push(@interesting_urls, $url);
	}
	return @interesting_urls;
}


# Uses ssmtp to send an email
sub sendEmail{

	my ($destination, $subject, $body) = @_;

        # Create and display the shell command used to send the email
	my $command="echo \'$body\' | mail -s \'$subject\' $destination";
	#say "\nExecuting shell command: $command";
	my $output = qx($command);
}

# does a keyword search based on a hash of keywords passed in: returns true if it passes the test 
sub keyword_search{
	my ($found_url, $find, $exclude) = @_;
        my $found = 0;
        my $skip = 0; 

        # getting the final webpage
	my $html = get($found_url);
	
        # Search for attractive items from config
        foreach my $find_item (@$find){

                if($html =~ /$find_item/){
                
                        $found=1;
                        next;
                }
        }

        # Search for excluded items from config
        foreach my $exclude_item (@$exclude){

                if($html =~ /$exclude_item/) {
                        $skip = 1;
                        return 0;
                }
        }
        return $found;
}

# Open the config
my $yaml = YAML::Tiny->read('.config.yml');	

# Get a reference to the first document
my $config = $yaml->[0];

my $search_url =  "https://santafe.craigslist.org/search/acc";

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
			my @potential_opportunities = filterCraigslist(getLinks($config_urls));
                        foreach my $opportunity (@potential_opportunities){
                                
                                # Match found! 
                                if(keyword_search($opportunity, ($profile_value->{keywords}->{find}), $profile_value->{keywords}->{exclude})){
                                       push @found_jobs, $opportunity; 
                                       say "Found a job!! $opportunity"
                                }
                        }
		}		
 	}	
        
        # Found some jobs
        if(scalar(@found_jobs)){
               
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

