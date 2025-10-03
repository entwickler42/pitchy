#!/usr/bin/perl -w

use Megahal;
use Purple;
use LWP::Simple;
use XML::RSS;

$last_sent="";
$last_read="";
$log=1;
$rss_feed= "http://www.nytimes.com/services/xml/rss/nyt/Business.xml";

%PLUGIN_SETTINGS = (
	ENABLED => 1
);

%PLUGIN_INFO = (
    perl_api_version => 2,
    name => "MegaHAL Plugin",
    version => "0.1",
    summary => "MegaHAL Conversation AI (Bot)",
    description => "this plugin is a simple interface to the pritty much anoing MegaHAL AI :)",
    author => "Refowe <refowe\@justmail.de>",
    url => "https://www.eifel-lotro.de",
    load => "plugin_load",
    unload => "plugin_unload"
);

sub plugin_init {
    return %PLUGIN_INFO;
}

sub plugin_load {
	my $plugin = shift;
	Megahal::megahal_initialize();
	Purple::Signal::connect(Purple::Conversations::get_handle(), "received-im-msg", $plugin, \&on_received_im_msg, "");
#	Purple::Signal::connect(Purple::Conversations::get_handle(), "sent-im-msg", $plugin, \&on_sent_im_msg, "");
}

sub plugin_unload {
	Megahal::megahal_cleanup();
}

sub on_sent_im_msg {
	my ($account, $sender, $message, $conv, $flags) = @_;
	if($message != $last_sent){
		learn($message);
	}
}

sub on_received_im_msg {
	my ($account, $sender, $message, $conv, $flags) = @_;
	my $im = $conv->get_im_data();
	my $reply;
	my $msg = $message;
	$msg =~ s{ < \W* \w+ [^>]* > }{}xmsg;
	trace($sender . ": " . $msg);
	if($last_read eq $msg){
		$reply = reply_rss();
		learn($reply);
		$im->send($reply);
	}else{
		$reply = reply($msg);
		$im->send($reply);
	}
	trace("MegaHal: " . $reply);
	$last_sent = $reply;
	$last_read = $msg;
}

sub reply{
	my $text = shift;
	Megahal::megahal_do_reply($text,$log);
}

sub reply_rss{
	my $rss	 = XML::RSS->new();
	my $data = get($rss_feed);
	$rss->parse($data);
	my $len = @{$rss->{items}};
	my $idx = int(rand($len-1));
	return $rss->{items}->[$idx]->{title};
}

sub learn{
	Megahal::megahal_learn_no_reply($message,$log);
}

sub trace {
	my $text = shift;
	Purple::Debug::info("MegaHAL", $text . "\n");
}

