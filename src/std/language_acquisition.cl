// src/std/language_acquisition.cl
// CARTAN Standard Library: Staged Language Acquisition & Attention-Trigger Cloze Engine
// Based on docs/Research/Idea.txt (Phase 62)

include "string.cl";

// Initialize language acquisition taxonomies (no-op in direct branching architecture)
fn lang_init_taxonomies() -> float {
    return 1.0;
}

// Retrieve high-frequency noun-noun pair by 1-based index (1-100)
fn lang_get_noun_pair(idx: float) -> string {
    if (idx == 1.0) { return "Health care"; }
    if (idx == 2.0) { return "Ice cream"; }
    if (idx == 3.0) { return "Web page"; }
    if (idx == 4.0) { return "Cell phone"; }
    if (idx == 5.0) { return "Credit card"; }
    if (idx == 6.0) { return "High school"; }
    if (idx == 7.0) { return "Social media"; }
    if (idx == 8.0) { return "Real estate"; }
    if (idx == 9.0) { return "Data base"; }
    if (idx == 10.0) { return "Water bottle"; }
    if (idx == 11.0) { return "Phone number"; }
    if (idx == 12.0) { return "Car insurance"; }
    if (idx == 13.0) { return "Home page"; }
    if (idx == 14.0) { return "Coffee shop"; }
    if (idx == 15.0) { return "Air conditioner"; }
    if (idx == 16.0) { return "Movie theater"; }
    if (idx == 17.0) { return "Room temperature"; }
    if (idx == 18.0) { return "Life insurance"; }
    if (idx == 19.0) { return "Post office"; }
    if (idx == 20.0) { return "Income tax"; }
    if (idx == 21.0) { return "Gas station"; }
    if (idx == 22.0) { return "Blood pressure"; }
    if (idx == 23.0) { return "Climate change"; }
    if (idx == 24.0) { return "Customer service"; }
    if (idx == 25.0) { return "Human rights"; }
    if (idx == 26.0) { return "Capital gains"; }
    if (idx == 27.0) { return "Heart attack"; }
    if (idx == 28.0) { return "Computer science"; }
    if (idx == 29.0) { return "Case study"; }
    if (idx == 30.0) { return "Board game"; }
    if (idx == 31.0) { return "Public relations"; }
    if (idx == 32.0) { return "Chain reaction"; }
    if (idx == 33.0) { return "Mass media"; }
    if (idx == 34.0) { return "Stock market"; }
    if (idx == 35.0) { return "Space shuttle"; }
    if (idx == 36.0) { return "Fossil fuels"; }
    if (idx == 37.0) { return "Core values"; }
    if (idx == 38.0) { return "Birth certificate"; }
    if (idx == 39.0) { return "Action movie"; }
    if (idx == 40.0) { return "Search engine"; }
    if (idx == 41.0) { return "Mental health"; }
    if (idx == 42.0) { return "Labor market"; }
    if (idx == 43.0) { return "Consciousness raising"; }
    if (idx == 44.0) { return "Security guard"; }
    if (idx == 45.0) { return "Grounded theory"; }
    if (idx == 46.0) { return "Comfort zone"; }
    if (idx == 47.0) { return "Call center"; }
    if (idx == 48.0) { return "Oil industry"; }
    if (idx == 49.0) { return "Gold medal"; }
    if (idx == 50.0) { return "World war"; }
    if (idx == 51.0) { return "Child care"; }
    if (idx == 52.0) { return "Video game"; }
    if (idx == 53.0) { return "Family business"; }
    if (idx == 54.0) { return "Laser pointer"; }
    if (idx == 55.0) { return "Police officer"; }
    if (idx == 56.0) { return "Air pollution"; }
    if (idx == 57.0) { return "State government"; }
    if (idx == 58.0) { return "Research method"; }
    if (idx == 59.0) { return "Resource management"; }
    if (idx == 60.0) { return "School district"; }
    if (idx == 61.0) { return "Brain damage"; }
    if (idx == 62.0) { return "Media coverage"; }
    if (idx == 63.0) { return "Death penalty"; }
    if (idx == 64.0) { return "Price tag"; }
    if (idx == 65.0) { return "Career path"; }
    if (idx == 66.0) { return "Safety net"; }
    if (idx == 67.0) { return "Solar energy"; }
    if (idx == 68.0) { return "Test tube"; }
    if (idx == 69.0) { return "Music video"; }
    if (idx == 70.0) { return "Target market"; }
    if (idx == 71.0) { return "Grave yard"; }
    if (idx == 72.0) { return "Water vapor"; }
    if (idx == 73.0) { return "Wind turbine"; }
    if (idx == 74.0) { return "Food source"; }
    if (idx == 75.0) { return "Flight attendant"; }
    if (idx == 76.0) { return "Sales tax"; }
    if (idx == 77.0) { return "Information technology"; }
    if (idx == 78.0) { return "Staff meeting"; }
    if (idx == 79.0) { return "Office building"; }
    if (idx == 80.0) { return "Waste management"; }
    if (idx == 81.0) { return "Identity theft"; }
    if (idx == 82.0) { return "Brand name"; }
    if (idx == 83.0) { return "Control group"; }
    if (idx == 84.0) { return "Field work"; }
    if (idx == 85.0) { return "Peer review"; }
    if (idx == 86.0) { return "Time limit"; }
    if (idx == 87.0) { return "Data collection"; }
    if (idx == 88.0) { return "Focus group"; }
    if (idx == 89.0) { return "Night club"; }
    if (idx == 90.0) { return "Coping mechanism"; }
    if (idx == 91.0) { return "Suicide attempt"; }
    if (idx == 92.0) { return "Mouth wash"; }
    if (idx == 93.0) { return "Property tax"; }
    if (idx == 94.0) { return "Reference point"; }
    if (idx == 95.0) { return "Power plant"; }
    if (idx == 96.0) { return "Ground water"; }
    if (idx == 97.0) { return "Eye contact"; }
    if (idx == 98.0) { return "Business plan"; }
    if (idx == 99.0) { return "Dating pool"; }
    if (idx == 100.0) { return "Drug addiction"; }
    return "";
}

// Retrieve binomial non-reversible pair by 1-based index (1-100)
fn lang_get_binomial_pair(idx: float) -> string {
    if (idx == 1.0) { return "Law and order"; }
    if (idx == 2.0) { return "Bread and butter"; }
    if (idx == 3.0) { return "Life and death"; }
    if (idx == 4.0) { return "Men and women"; }
    if (idx == 5.0) { return "Mom and dad"; }
    if (idx == 6.0) { return "Ladies and gentlemen"; }
    if (idx == 7.0) { return "Body and soul"; }
    if (idx == 8.0) { return "Trial and error"; }
    if (idx == 9.0) { return "Profit and loss"; }
    if (idx == 10.0) { return "Supply and demand"; }
    if (idx == 11.0) { return "Cause and effect"; }
    if (idx == 12.0) { return "Lock and key"; }
    if (idx == 13.0) { return "Fish and chips"; }
    if (idx == 14.0) { return "Salt and pepper"; }
    if (idx == 15.0) { return "Knife and fork"; }
    if (idx == 16.0) { return "Leaps and bounds"; }
    if (idx == 17.0) { return "Thunder and lightning"; }
    if (idx == 18.0) { return "Time and tide"; }
    if (idx == 19.0) { return "Flesh and blood"; }
    if (idx == 20.0) { return "Skin and bones"; }
    if (idx == 21.0) { return "Heart and soul"; }
    if (idx == 22.0) { return "Nook and cranny"; }
    if (idx == 23.0) { return "Bits and pieces"; }
    if (idx == 24.0) { return "Odds and ends"; }
    if (idx == 25.0) { return "Wear and tear"; }
    if (idx == 26.0) { return "Peace and quiet"; }
    if (idx == 27.0) { return "Pride and joy"; }
    if (idx == 28.0) { return "Facts and figures"; }
    if (idx == 29.0) { return "Suit and tie"; }
    if (idx == 30.0) { return "Hugs and kisses"; }
    if (idx == 31.0) { return "Bacon and eggs"; }
    if (idx == 32.0) { return "Mac and cheese"; }
    if (idx == 33.0) { return "Hammer and sickle"; }
    if (idx == 34.0) { return "Bow and arrow"; }
    if (idx == 35.0) { return "Stocks and bonds"; }
    if (idx == 36.0) { return "Pen and paper"; }
    if (idx == 37.0) { return "Checks and balances"; }
    if (idx == 38.0) { return "Rank and file"; }
    if (idx == 39.0) { return "Alpha and omega"; }
    if (idx == 40.0) { return "Milk and honey"; }
    if (idx == 41.0) { return "Cloak and dagger"; }
    if (idx == 42.0) { return "Black and white"; }
    if (idx == 43.0) { return "Safe and sound"; }
    if (idx == 44.0) { return "Short and sweet"; }
    if (idx == 45.0) { return "Loud and clear"; }
    if (idx == 46.0) { return "Alive and well"; }
    if (idx == 47.0) { return "Alive and kicking"; }
    if (idx == 48.0) { return "Sick and tired"; }
    if (idx == 49.0) { return "High and dry"; }
    if (idx == 50.0) { return "Bright and early"; }
    if (idx == 51.0) { return "Far and wide"; }
    if (idx == 52.0) { return "Plain and simple"; }
    if (idx == 53.0) { return "Neat and tidy"; }
    if (idx == 54.0) { return "Pure and simple"; }
    if (idx == 55.0) { return "Good and bad"; }
    if (idx == 56.0) { return "Hot and cold"; }
    if (idx == 57.0) { return "Hard and fast"; }
    if (idx == 58.0) { return "Old and gray"; }
    if (idx == 59.0) { return "Black and blue"; }
    if (idx == 60.0) { return "Deaf and dumb"; }
    if (idx == 61.0) { return "Free and easy"; }
    if (idx == 62.0) { return "Near and dear"; }
    if (idx == 63.0) { return "Ready and willing"; }
    if (idx == 64.0) { return "Slow and steady"; }
    if (idx == 65.0) { return "Rough and tough"; }
    if (idx == 66.0) { return "Armed and dangerous"; }
    if (idx == 67.0) { return "Big and tall"; }
    if (idx == 68.0) { return "Give and take"; }
    if (idx == 69.0) { return "Live and learn"; }
    if (idx == 70.0) { return "Pick and choose"; }
    if (idx == 71.0) { return "Wait and see"; }
    if (idx == 72.0) { return "Wine and dine"; }
    if (idx == 73.0) { return "Rise and shine"; }
    if (idx == 74.0) { return "Crash and burn"; }
    if (idx == 75.0) { return "Live and let live"; }
    if (idx == 76.0) { return "Cease and desist"; }
    if (idx == 77.0) { return "Divide and conquer"; }
    if (idx == 78.0) { return "Hit and run"; }
    if (idx == 79.0) { return "Stop and go"; }
    if (idx == 80.0) { return "Hide and seek"; }
    if (idx == 81.0) { return "Touch and go"; }
    if (idx == 82.0) { return "Do or die"; }
    if (idx == 83.0) { return "Sink or swim"; }
    if (idx == 84.0) { return "Come and go"; }
    if (idx == 85.0) { return "Huff and puff"; }
    if (idx == 86.0) { return "Meet and greet"; }
    if (idx == 87.0) { return "Forgive and forget"; }
    if (idx == 88.0) { return "Back and forth"; }
    if (idx == 89.0) { return "Up and down"; }
    if (idx == 90.0) { return "In and out"; }
    if (idx == 91.0) { return "On and off"; }
    if (idx == 92.0) { return "Now and then"; }
    if (idx == 93.0) { return "By and large"; }
    if (idx == 94.0) { return "To and fro"; }
    if (idx == 95.0) { return "Hither and thither"; }
    if (idx == 96.0) { return "More or less"; }
    if (idx == 97.0) { return "Sooner or later"; }
    if (idx == 98.0) { return "Dos and donts"; }
    if (idx == 99.0) { return "Pros and cons"; }
    if (idx == 100.0) { return "Heads or tails"; }
    return "";
}

// Categorize binomial pair by 1-based index
fn lang_get_binomial_category(idx: float) -> string {
    if (idx >= 1.0 && idx <= 41.0) {
        return "Noun+Noun";
    }
    if (idx >= 42.0 && idx <= 67.0) {
        return "Adjective+Adjective";
    }
    if (idx >= 68.0 && idx <= 87.0) {
        return "Verb+Verb";
    }
    if (idx >= 88.0 && idx <= 100.0) {
        return "Adverbial/Contrastive";
    }
    return "Unknown";
}

// Retrieve discourse marker or social ritual by 1-based index (1-100)
fn lang_get_discourse_marker(idx: float) -> string {
    if (idx == 1.0) { return "Thank you"; }
    if (idx == 2.0) { return "You are welcome"; }
    if (idx == 3.0) { return "Excuse me"; }
    if (idx == 4.0) { return "Good morning"; }
    if (idx == 5.0) { return "How are you"; }
    if (idx == 6.0) { return "Nice to meet you"; }
    if (idx == 7.0) { return "See you later"; }
    if (idx == 8.0) { return "Have a good day"; }
    if (idx == 9.0) { return "Take care"; }
    if (idx == 10.0) { return "Bless you"; }
    if (idx == 11.0) { return "No problem"; }
    if (idx == 12.0) { return "Do not worry about it"; }
    if (idx == 13.0) { return "It is my pleasure"; }
    if (idx == 14.0) { return "Congratulations"; }
    if (idx == 15.0) { return "Happy birthday"; }
    if (idx == 16.0) { return "By the way"; }
    if (idx == 17.0) { return "As a matter of fact"; }
    if (idx == 18.0) { return "In other words"; }
    if (idx == 19.0) { return "To be honest"; }
    if (idx == 20.0) { return "At the end of the day"; }
    if (idx == 21.0) { return "For example"; }
    if (idx == 22.0) { return "First of all"; }
    if (idx == 23.0) { return "On the other hand"; }
    if (idx == 24.0) { return "In my opinion"; }
    if (idx == 25.0) { return "As far as I know"; }
    if (idx == 26.0) { return "To tell you the truth"; }
    if (idx == 27.0) { return "Believe it or not"; }
    if (idx == 28.0) { return "Long story short"; }
    if (idx == 29.0) { return "All in all"; }
    if (idx == 30.0) { return "In the meantime"; }
    if (idx == 31.0) { return "For the record"; }
    if (idx == 32.0) { return "Mind you"; }
    if (idx == 33.0) { return "You know what I mean"; }
    if (idx == 34.0) { return "At any rate"; }
    if (idx == 35.0) { return "So to speak"; }
    if (idx == 36.0) { return "Of course"; }
    if (idx == 37.0) { return "I agree"; }
    if (idx == 38.0) { return "No way"; }
    if (idx == 39.0) { return "Fair enough"; }
    if (idx == 40.0) { return "I suppose so"; }
    if (idx == 41.0) { return "Absolutely"; }
    if (idx == 42.0) { return "You are right"; }
    if (idx == 43.0) { return "I think so"; }
    if (idx == 44.0) { return "I do not think so"; }
    if (idx == 45.0) { return "I am not sure"; }
    if (idx == 46.0) { return "Without a doubt"; }
    if (idx == 47.0) { return "I bet"; }
    if (idx == 48.0) { return "You never know"; }
    if (idx == 49.0) { return "That makes sense"; }
    if (idx == 50.0) { return "Definitely"; }
    if (idx == 51.0) { return "Are you sure"; }
    if (idx == 52.0) { return "I doubt it"; }
    if (idx == 53.0) { return "Exactly"; }
    if (idx == 54.0) { return "Sounds good"; }
    if (idx == 55.0) { return "No doubt about it"; }
    if (idx == 56.0) { return "I want to"; }
    if (idx == 57.0) { return "I would like to"; }
    if (idx == 58.0) { return "Can you help me"; }
    if (idx == 59.0) { return "Hold on a second"; }
    if (idx == 60.0) { return "Give me a hand"; }
    if (idx == 61.0) { return "Could you please"; }
    if (idx == 62.0) { return "I am going to"; }
    if (idx == 63.0) { return "Let me know"; }
    if (idx == 64.0) { return "Keep in touch"; }
    if (idx == 65.0) { return "Check this out"; }
    if (idx == 66.0) { return "Wait a minute"; }
    if (idx == 67.0) { return "Let us do it"; }
    if (idx == 68.0) { return "Do you mind"; }
    if (idx == 69.0) { return "Make yourself at home"; }
    if (idx == 70.0) { return "Never mind"; }
    if (idx == 71.0) { return "Forget about it"; }
    if (idx == 72.0) { return "Let it go"; }
    if (idx == 73.0) { return "Leave me alone"; }
    if (idx == 74.0) { return "Just a moment"; }
    if (idx == 75.0) { return "Oh my god"; }
    if (idx == 76.0) { return "What is up"; }
    if (idx == 77.0) { return "You are kidding me"; }
    if (idx == 78.0) { return "That is awesome"; }
    if (idx == 79.0) { return "What a shame"; }
    if (idx == 80.0) { return "I am so sorry"; }
    if (idx == 81.0) { return "Good luck"; }
    if (idx == 82.0) { return "Cheer up"; }
    if (idx == 83.0) { return "Calm down"; }
    if (idx == 84.0) { return "Poor thing"; }
    if (idx == 85.0) { return "That sucks"; }
    if (idx == 86.0) { return "You can do it"; }
    if (idx == 87.0) { return "I cannot believe it"; }
    if (idx == 88.0) { return "What a relief"; }
    if (idx == 89.0) { return "You have got to be joking"; }
    if (idx == 90.0) { return "How awful"; }
    if (idx == 91.0) { return "Good job"; }
    if (idx == 92.0) { return "That is incredible"; }
    if (idx == 93.0) { return "Do not give up"; }
    if (idx == 94.0) { return "I am proud of you"; }
    if (idx == 95.0) { return "No hard feelings"; }
    if (idx == 96.0) { return "It happens"; }
    if (idx == 97.0) { return "Whatever"; }
    if (idx == 98.0) { return "Whatever you say"; }
    if (idx == 99.0) { return "I do not care"; }
    if (idx == 100.0) { return "I love you"; }
    return "";
}

// Categorize functional discourse marker by 1-based index
fn lang_get_discourse_category(idx: float) -> string {
    if (idx >= 1.0 && idx <= 15.0) {
        return "Social Rituals & Politeness";
    }
    if (idx >= 16.0 && idx <= 35.0) {
        return "Discourse Markers & Managing Conversation";
    }
    if (idx >= 36.0 && idx <= 55.0) {
        return "Expressing Agreement, Certainty, & Doubt";
    }
    if (idx >= 56.0 && idx <= 74.0) {
        return "Expressing Desires, Intentions, & Requests";
    }
    if (idx >= 75.0 && idx <= 100.0) {
        return "Emotional Responses & Empathy";
    }
    return "Unknown";
}

// Retrieve narrative progression transition bridge by 1-based index (1-100)
fn lang_get_transition_bridge(idx: float) -> string {
    if (idx == 1.0) { return "As previously mentioned"; }
    if (idx == 2.0) { return "In contrast to"; }
    if (idx == 3.0) { return "On the contrary"; }
    if (idx == 4.0) { return "Moving on to"; }
    if (idx == 5.0) { return "With that being said"; }
    if (idx == 6.0) { return "In the meantime"; }
    if (idx == 7.0) { return "Simultaneously"; }
    if (idx == 8.0) { return "As a result"; }
    if (idx == 9.0) { return "Consequently"; }
    if (idx == 10.0) { return "Subsequently"; }
    if (idx == 11.0) { return "For the time being"; }
    if (idx == 12.0) { return "Up to this point"; }
    if (idx == 13.0) { return "Historically speaking"; }
    if (idx == 14.0) { return "In general terms"; }
    if (idx == 15.0) { return "Broadly speaking"; }
    if (idx == 16.0) { return "More specifically"; }
    if (idx == 17.0) { return "In particular"; }
    if (idx == 18.0) { return "On a related note"; }
    if (idx == 19.0) { return "By extension"; }
    if (idx == 20.0) { return "To illustrate"; }
    if (idx == 21.0) { return "For instance"; }
    if (idx == 22.0) { return "Case in point"; }
    if (idx == 23.0) { return "In essence"; }
    if (idx == 24.0) { return "Fundamentally speaking"; }
    if (idx == 25.0) { return "It is important to note"; }
    if (idx == 26.0) { return "Given the circumstances"; }
    if (idx == 27.0) { return "Under the condition that"; }
    if (idx == 28.0) { return "Assuming that is true"; }
    if (idx == 29.0) { return "Hypothetically speaking"; }
    if (idx == 30.0) { return "In all likelihood"; }
    if (idx == 31.0) { return "There is no doubt that"; }
    if (idx == 32.0) { return "It goes without saying"; }
    if (idx == 33.0) { return "It is worth mentioning"; }
    if (idx == 34.0) { return "From a different perspective"; }
    if (idx == 35.0) { return "Taking into account"; }
    if (idx == 36.0) { return "All things considered"; }
    if (idx == 37.0) { return "In light of recent events"; }
    if (idx == 38.0) { return "Based on the data"; }
    if (idx == 39.0) { return "According to the source"; }
    if (idx == 40.0) { return "In accordance with"; }
    if (idx == 41.0) { return "By definition"; }
    if (idx == 42.0) { return "Strictly speaking"; }
    if (idx == 43.0) { return "To a certain extent"; }
    if (idx == 44.0) { return "For all intents and purposes"; }
    if (idx == 45.0) { return "In reality"; }
    if (idx == 46.0) { return "On the surface"; }
    if (idx == 47.0) { return "Deep down"; }
    if (idx == 48.0) { return "At first glance"; }
    if (idx == 49.0) { return "Upon further inspection"; }
    if (idx == 50.0) { return "As far as I am concerned"; }
    if (idx == 51.0) { return "If I remember correctly"; }
    if (idx == 52.0) { return "Correct me if I am wrong"; }
    if (idx == 53.0) { return "To tell you the truth"; }
    if (idx == 54.0) { return "Do not get me wrong"; }
    if (idx == 55.0) { return "If you think about it"; }
    if (idx == 56.0) { return "I see what you mean"; }
    if (idx == 57.0) { return "Point taken"; }
    if (idx == 58.0) { return "That being the case"; }
    if (idx == 59.0) { return "As you can see"; }
    if (idx == 60.0) { return "Believe it or not"; }
    if (idx == 61.0) { return "Like I said"; }
    if (idx == 62.0) { return "As I was saying"; }
    if (idx == 63.0) { return "To wrap things up"; }
    if (idx == 64.0) { return "Long story short"; }
    if (idx == 65.0) { return "In a nutshell"; }
    if (idx == 66.0) { return "Suffice it to say"; }
    if (idx == 67.0) { return "Needless to say"; }
    if (idx == 68.0) { return "That is to say"; }
    if (idx == 69.0) { return "In other words"; }
    if (idx == 70.0) { return "To put it simply"; }
    if (idx == 71.0) { return "Simply put"; }
    if (idx == 72.0) { return "At the end of the day"; }
    if (idx == 73.0) { return "When all is said and done"; }
    if (idx == 74.0) { return "Bottom line is"; }
    if (idx == 75.0) { return "As long as"; }
    if (idx == 76.0) { return "Provided that"; }
    if (idx == 77.0) { return "Unless otherwise specified"; }
    if (idx == 78.0) { return "Whether or not"; }
    if (idx == 79.0) { return "In case of"; }
    if (idx == 80.0) { return "Just in case"; }
    if (idx == 81.0) { return "No matter what"; }
    if (idx == 82.0) { return "Either way"; }
    if (idx == 83.0) { return "In any event"; }
    if (idx == 84.0) { return "At any rate"; }
    if (idx == 85.0) { return "By all means"; }
    if (idx == 86.0) { return "By no means"; }
    if (idx == 87.0) { return "Under no circumstances"; }
    if (idx == 88.0) { return "As a rule"; }
    if (idx == 89.0) { return "More or less"; }
    if (idx == 90.0) { return "On average"; }
    if (idx == 91.0) { return "For the most part"; }
    if (idx == 92.0) { return "By and large"; }
    if (idx == 93.0) { return "In some ways"; }
    if (idx == 94.0) { return "To some degree"; }
    if (idx == 95.0) { return "In a sense"; }
    if (idx == 96.0) { return "So to speak"; }
    if (idx == 97.0) { return "As it turns out"; }
    if (idx == 98.0) { return "Lo and behold"; }
    if (idx == 99.0) { return "Sure enough"; }
    if (idx == 100.0) { return "In light of this"; }
    return "";
}

// Check whether phrase is registered across any of the 4 acquisition taxonomies
fn lang_is_registered_phrase(phrase: string) -> float {
    var i = 1.0;
    while (i <= 100.0) {
        if (cartan_string_eq(phrase, lang_get_transition_bridge(i)) == 1.0) {
            return 1.0;
        }
        if (cartan_string_eq(phrase, lang_get_discourse_marker(i)) == 1.0) {
            return 1.0;
        }
        if (cartan_string_eq(phrase, lang_get_binomial_pair(i)) == 1.0) {
            return 1.0;
        }
        if (cartan_string_eq(phrase, lang_get_noun_pair(i)) == 1.0) {
            return 1.0;
        }
        i = i + 1.0;
    }
    return 0.0;
}

// Compute prioritized attention anchor weight for cloze training
fn lang_calculate_anchor_weight(phrase: string) -> float {
    var i = 1.0;
    while (i <= 100.0) {
        if (cartan_string_eq(phrase, lang_get_transition_bridge(i)) == 1.0) {
            return 2.50; // Maximum anchor weight for structural transition bridges
        }
        i = i + 1.0;
    }
    i = 1.0;
    while (i <= 100.0) {
        if (cartan_string_eq(phrase, lang_get_discourse_marker(i)) == 1.0) {
            return 2.00; // High weight for discourse markers & social rituals
        }
        i = i + 1.0;
    }
    i = 1.0;
    while (i <= 100.0) {
        if (cartan_string_eq(phrase, lang_get_binomial_pair(i)) == 1.0) {
            return 1.80; // Elevated weight for non-reversible binomial pairs
        }
        i = i + 1.0;
    }
    i = 1.0;
    while (i <= 100.0) {
        if (cartan_string_eq(phrase, lang_get_noun_pair(i)) == 1.0) {
            return 1.50; // Priority weight for statistical noun-noun pairs
        }
        i = i + 1.0;
    }
    return 1.00; // Baseline weight for general text tokens
}
