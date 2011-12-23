use Text::Language::Guess;

my $guesser = Text::Language::Guess->new();
my $lang = $guesser->language_guess_string($ARGV[0]);

print "$lang";