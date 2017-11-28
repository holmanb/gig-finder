#!/usr/bin/perl
use strict;
use warnings;
use local::lib;
use LWP::UserAgent ();
use feature 'say';

# Function for getting html for any arbitrary website 
sub getHtmlPage{

	# Takes a URL and (optionally) an agent
	my @args = @_;

	# Initialize vars 	
	my $num_args = scalar(@args);   # number of args
	my $ua = "";		  	# user agent
	my $url = $args[0];		# url
	say "Searching for: $url";	# user notification

	# Function can only handle two args
	if($num_args>2){ 
		die "Incorrectly used function";
	}

	# UserAgent isn't given, so make one
	elsif($num_args==1){

		# hash of ssl options for https
		my %ssl_ops = (
			verify_hostname => 1 ,
			protocols_allowed => ['https']
			);

		# make the user agent
		$ua = LWP::UserAgent->new(ssl_opts => \%ssl_ops);
		$ua->timeout(10);
		$ua->env_proxy;
	}

	# UserAgent is given as argument
	else{
		$ua = $args[1];
	}

	# HTTP GET REQUEST
	my $response = $ua->get($url);

	# Unsuccessful request
	if (!$response->is_success){
		say $response->as_string;
		die "Unsuccessful request $response->status_line";
		

	}

	# Successful request
	return $response->decoded_content;
}

# Main execution
my $url =  "https://eauclaire.craigslist.org/search/acc";
my $response = getHtmlPage($url, $u); 
say "response: $response";

