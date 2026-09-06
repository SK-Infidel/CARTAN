#!/usr/bin/env python3
"""
tools/build_conversational_storytelling_dataset.py
================================================================================
Comprehensive Conversational and Storytelling Dataset Generator
================================================================================
Generates high-quality, zero-mock conversational dialogues, multi-genre story
narratives, and attention-trigger instruction-response pairs aligned with
docs/Research/Idea.txt for GeoMind pre-training and supervised fine-tuning.

Outputs:
  - test/geomind/trainingdata/conversational_storytelling_dataset.jsonl (SFT & Cloze)
  - test/geomind/trainingdata/storytelling_corpus.txt (Causal Pre-Training Prose)
  - test/geomind/trainingdata/hf_roneneldan_TinyStories.txt (Moral & Simple Tales)
  - test/geomind/trainingdata/hf_alpaca_stories.txt (Instruction / Story Responses)
"""

import json
import os
import re
import random
import sys

# Seed for deterministic, reproducible generation
random.seed(42)

# ==============================================================================
# 1. Attention Triggers and Functional Phrases from docs/Research/Idea.txt
# ==============================================================================

NOUN_PAIRS = [
    "Health care", "Ice cream", "Web page", "Cell phone", "Credit card",
    "High school", "Social media", "Real estate", "Data base", "Water bottle",
    "Phone number", "Car insurance", "Home page", "Coffee shop", "Air conditioner",
    "Movie theater", "Room temperature", "Life insurance", "Post office", "Income tax",
    "Gas station", "Blood pressure", "Climate change", "Customer service", "Human rights",
    "Capital gains", "Heart attack", "Computer science", "Case study", "Board game",
    "Public relations", "Chain reaction", "Mass media", "Stock market", "Space shuttle",
    "Fossil fuels", "Core values", "Birth certificate", "Action movie", "Search engine",
    "Mental health", "Labor market", "Security guard", "Grounded theory", "Comfort zone",
    "Call center", "Oil industry", "Gold medal", "World war", "Child care",
    "Video game", "Family business", "Laser pointer", "Police officer", "Air pollution",
    "State government", "Research method", "Resource management", "School district",
    "Brain damage", "Media coverage", "Death penalty", "Price tag", "Career path",
    "Safety net", "Solar energy", "Test tube", "Music video", "Target market",
    "Water vapor", "Wind turbine", "Food source", "Flight attendant", "Sales tax",
    "Information technology", "Staff meeting", "Office building", "Waste management",
    "Identity theft", "Brand name", "Control group", "Peer review", "Time limit",
    "Data collection", "Focus group", "Property tax", "Reference point", "Power plant",
    "Ground water", "Eye contact", "Business plan", "Drug addiction"
]

BINOMIAL_PAIRS = [
    # Noun + Noun
    "Law and order", "Bread and butter", "Life and death", "Men and women", "Mom and dad",
    "Ladies and gentlemen", "Body and soul", "Trial and error", "Profit and loss",
    "Supply and demand", "Cause and effect", "Lock and key", "Fish and chips",
    "Salt and pepper", "Knife and fork", "Leaps and bounds", "Thunder and lightning",
    "Time and tide", "Flesh and blood", "Skin and bones", "Heart and soul",
    "Nook and cranny", "Bits and pieces", "Odds and ends", "Wear and tear",
    "Peace and quiet", "Pride and joy", "Facts and figures", "Suit and tie",
    "Hugs and kisses", "Bacon and eggs", "Mac and cheese", "Bow and arrow",
    "Stocks and bonds", "Pen and paper", "Checks and balances", "Rank and file",
    "Alpha and omega", "Milk and honey", "Cloak and dagger",
    # Adjective + Adjective
    "Black and white", "Safe and sound", "Short and sweet", "Loud and clear",
    "Alive and well", "Alive and kicking", "Sick and tired", "High and dry",
    "Bright and early", "Far and wide", "Plain and simple", "Neat and tidy",
    "Pure and simple", "Good and bad", "Hot and cold", "Hard and fast",
    "Free and easy", "Near and dear", "Ready and willing", "Slow and steady",
    "Rough and tough", "Armed and dangerous", "Big and tall",
    # Verb + Verb
    "Give and take", "Live and learn", "Pick and choose", "Wait and see",
    "Wine and dine", "Rise and shine", "Crash and burn", "Live and let live",
    "Cease and desist", "Divide and conquer", "Hit and run", "Stop and go",
    "Hide and seek", "Touch and go", "Do or die", "Sink or swim",
    "Come and go", "Huff and puff", "Meet and greet",
    # Adverb / Contrastive
    "Back and forth", "Up and down", "In and out", "On and off", "Now and then",
    "By and large", "To and fro", "More or less", "Sooner or later",
    "Dos and don'ts", "Pros and cons", "Heads or tails"
]

FUNCTIONAL_PHRASES = [
    # Social Rituals & Politeness
    "Thank you", "You're welcome", "Excuse me", "Good morning", "How are you?",
    "Nice to meet you", "See you later", "Have a good day", "Take care", "Bless you",
    "No problem", "Don't worry about it", "It's my pleasure", "Congratulations",
    # Discourse Markers & Pacing
    "By the way", "As a matter of fact", "In other words", "To be honest",
    "At the end of the day", "For example", "First of all", "On the other hand",
    "In my opinion", "As far as I know", "To tell you the truth", "Believe it or not",
    "Long story short", "All in all", "In the meantime", "For the record",
    "Mind you", "You know what I mean", "At any rate", "So to speak",
    # Agreement, Certainty & Doubt
    "Of course", "I agree", "No way", "Fair enough", "I suppose so",
    "Absolutely", "You're right", "I think so", "I don't think so",
    "I'm not sure", "Without a doubt", "That makes sense", "Definitely",
    "I doubt it", "Exactly", "Sounds good", "No doubt about it",
    # Desires, Requests & Empathy
    "I want to", "I would like to", "Can you help me?", "Hold on a second",
    "Give me a hand", "Let me know", "Keep in touch", "Check this out",
    "Never mind", "Forget about it", "Just a moment", "That's awesome",
    "I'm so sorry", "Good luck", "Calm down", "You can do it",
    "What a relief", "Good job", "That's incredible", "Don't give up"
]

TRANSITION_MARKERS = [
    "As previously mentioned", "In contrast to", "On the contrary", "Moving on to",
    "With that being said", "Simultaneously", "As a result", "Consequently",
    "Subsequently", "For the time being", "Up to this point", "Historically speaking",
    "In general terms", "Broadly speaking", "More specifically", "In particular",
    "On a related note", "By extension", "To illustrate", "For instance",
    "Case in point", "In essence", "Fundamentally speaking", "It is important to note",
    "Given the circumstances", "Under the condition that", "Assuming that is true",
    "In all likelihood", "There is no doubt that", "It goes without saying",
    "It is worth mentioning", "From a different perspective", "Taking into account",
    "All things considered", "In light of recent events", "Based on the data",
    "According to the source", "In accordance with", "By definition",
    "Strictly speaking", "To a certain extent", "For all intents and purposes",
    "In reality", "On the surface", "Deep down", "At first glance",
    "Upon further inspection", "As far as I'm concerned", "Don't get me wrong",
    "If you think about it", "I see what you mean", "Point taken",
    "That being the case", "As you can see", "To wrap things up", "In a nutshell",
    "Suffice it to say", "Needless to say", "That is to say", "To put it simply",
    "Simply put", "When all is said and done", "Bottom line is", "As long as",
    "Provided that", "Unless otherwise specified", "Whether or not", "In case of",
    "Just in case", "No matter what", "Either way", "In any event",
    "By all means", "By no means", "Under no circumstances", "As a rule",
    "For the most part", "To some degree", "In a sense", "As it turns out",
    "Lo and behold", "Sure enough"
]

# ==============================================================================
# 2. Curated Narrative Seed Libraries Across Genres
# ==============================================================================

TINY_STORIES_SEEDS = [
    {
        "title": "The Kind Little Sparrow",
        "characters": ["Pip the sparrow", "Oliver the hedgehog"],
        "setting": "an overgrown autumn garden",
        "theme": "sharing and kindness during difficult times",
        "text": (
            "Once upon a time, in an overgrown autumn garden, lived a small sparrow named Pip. "
            "Pip loved to fly high above the bramble bushes, searching for shiny berries and crunchy seeds. "
            "One crisp morning, the north wind began to blow cold and sharp. All of a sudden, dark gray clouds filled the sky. "
            "Oliver the hedgehog was shuffling slowly through the fallen maple leaves, shivering in the cold. "
            "'Good morning, Oliver!' chirped Pip cheerfully. 'Why do you look so sad?' "
            "'I have been searching since dawn for acorns to store for winter,' Oliver replied with a sigh. 'To tell you the truth, my legs are tired and I haven't found a single one.' "
            "Pip thought about the secret hollow in the great oak tree where sweet acorns always gathered. "
            "'Don't worry about it!' said Pip. 'Follow me, and I will show you where the best acorns hide.' "
            "Oliver followed the flutter of Pip's feathers. Sure enough, tucked inside the mossy hollow were dozens of golden acorns. "
            "Oliver's little eyes sparkled with joy. 'Thank you, Pip! You saved my winter.' "
            "'You're welcome,' Pip smiled warmly. 'Life is much happier when friends help each other.' "
            "From that day on, Oliver and Pip were the best of friends, sharing their meals through sunshine and snow alike."
        )
    },
    {
        "title": "The Wooden Toy Boat",
        "characters": ["Leo", "his grandfather"],
        "setting": "a sunny workshop by the river",
        "theme": "patience, craftsmanship, and perseverance",
        "text": (
            "Leo loved visiting his grandfather's woodworking shop on sunny afternoons. "
            "The air smelled of cedar shavings and sweet beeswax. "
            "'Grandpa, can we build a toy sailboat today?' Leo asked, bouncing on his heels. "
            "'Of course, Leo,' his grandfather replied with a warm smile. 'Building something worthwhile requires patience and care.' "
            "First of all, they selected a smooth pine block from the shelf. Leo used a small sanding sponge, rubbing back and forth until the wood was soft as silk. "
            "Next, they carved a slender mast and attached a crisp white canvas sail. "
            "Leo was eager to test it immediately, but his grandfather placed a gentle hand on his shoulder. "
            "'Wait and see,' grandfather said. 'We must coat the hull in waterproof lacquer, or it will take on water.' "
            "Leo waited patiently until the afternoon sun dried the glossy coat. "
            "Together, they walked down to the clear riverbank. Leo placed the boat onto the rippling water. "
            "Lo and behold, the gentle breeze caught the sail, and the little vessel glided gracefully across the clear blue pond. "
            "'Look at it sail!' Leo shouted with pure delight. "
            "'Slow and steady wins the day,' his grandfather laughed softly. Leo knew he would treasure that afternoon forever."
        )
    },
    {
        "title": "The Lost Kitten in the Rain",
        "characters": ["Maya", "a silver tabby kitten"],
        "setting": "a quiet suburban street during a spring downpour",
        "theme": "empathy and responsibility",
        "text": (
            "The rain tapped rhythmic melodies against the windowpanes. Maya sat in her living room reading a favorite book. "
            "All in all, it was a calm Sunday morning. Suddenly, she heard a faint, trembling cry from the front porch. "
            "Maya set down her book and opened the wooden door. Sitting right beneath the dripping eaves was a tiny silver kitten, soaked to the skin. "
            "'Oh, poor thing,' Maya whispered softly. She knelt down slowly, making sure not to make any sudden movements. "
            "The kitten shivered and took a cautious step forward, rubbing its wet nose against her hand. "
            "Maya scooped the little bundle into her arms and carried it inside. "
            "First of all, she wrapped the kitten in a warm, dry towel, drying its fur until it began to purr. "
            "Then she warmed a small saucer of milk and placed it by the fireplace. "
            "By and large, the kitten felt safe and warm within minutes, curling up into a contented ball of silver fluff. "
            "When Maya's parents walked into the room, Maya looked up with hopeful eyes. 'Can we keep him? We'll take wonderful care of him.' "
            "Her mother smiled and nodded gently. 'Given the circumstances, Maya, he has already chosen you as his family.'"
        )
    },
    {
        "title": "The Mysterious Clockwork Key",
        "characters": ["Clara the tinkerer", "Master Barnaby"],
        "setting": "an ancient clocktower above a bustling harbor",
        "theme": "curiosity and scientific inquiry",
        "text": (
            "High up in the city's ancient clocktower, Clara examined the intricate brass gears of the astronomical timepiece. "
            "Every cog and spring operated with mathematical precision. "
            "However, the innermost celestial dial had remained frozen for over fifty years. "
            "'Master Barnaby,' Clara called out, peering through her magnifying loupe. 'There is a hidden cylinder behind the lunar escapement.' "
            "Barnaby climbed up the spiral iron stairs, adjusting his spectacles. 'Many watchmakers have attempted to unlock it, Clara. Without a doubt, the mechanism is exceptionally delicate.' "
            "Clara retrieved a slender brass key she had discovered in the foundation vaults. "
            "With extreme care, she inserted the key into the star-shaped socket. "
            "For a moment, nothing happened. Clara held her breath. "
            "Then, with a gentle metallic chime, the internal levers aligned. The celestial dial began to rotate, chiming sweet crystal notes across the harbor below. "
            "'Incredible!' Barnaby exclaimed, his eyes wide with astonishment. 'You have restored the harmony of the spheres.' "
            "'Trial and error,' Clara beamed proudly. 'Patience and observation can solve even the oldest mysteries.'"
        )
    },
    {
        "title": "The Garden of Luminescent Flowers",
        "characters": ["Sora", "her robotic companion ECHO"],
        "setting": "a bio-dome on the outer lunar colony",
        "theme": "wonder, nature, and technological harmony",
        "text": (
            "Beneath the pressurized glass domes of Lunar Base Alpha, botanist Sora cultivated rare extraterrestrial flora. "
            "Her floating companion drone, ECHO, hummed softly as it measured soil moisture and nutrient balances. "
            "'Status report, ECHO,' Sora requested, checking the ambient room temperature. "
            "'Optimal conditions maintained, Sora,' ECHO replied in its synthesized, gentle voice. 'Photosynthetic activity is rising.' "
            "Tonight was the night the nocturnal Selene lilies were scheduled to blossom. "
            "Sora dimmed the overhead lights. In the quiet darkness, faint emerald whispers began to emanate from the petals. "
            "All of a sudden, the entire greenhouse ignited in a breathtaking cascade of iridescent blue and violet light. "
            "The flowers released a sweet, clean fragrance reminiscent of spring rain on Earth. "
            "'Look at this, ECHO,' Sora whispered, transfixed by the radiant spectacle. 'Even hundreds of thousands of miles away from Earth, life finds a way to flourish.' "
            "'Affirmative,' ECHO replied, recording high-resolution spectral imagery. 'Beauty is universal across all planetary coordinates.' "
            "Together, human and machine watched the silent garden dance in harmony beneath the distant blue crescent of Earth."
        )
    }
]

PROSE_STORY_SEEDS = [
    {
        "genre": "Science Fiction & Space Exploration",
        "title": "The Signal from Sector Seven",
        "chapters": [
            (
                "Chapter 1: The Outpost at the Edge",
                "Commander Vane stood on the observation deck of Orbital Station Epsilon, watching the swirling crimson storm bands of the gas giant below. "
                "For eighteen months, deep-space sensors had registered only the steady, monotonous static of cosmic background radiation. "
                "Then, at 0300 hours ship time, the primary frequency analyzer began to oscillate wildly. "
                "'Ensign Thorne, verify that telemetry,' Vane commanded, his voice tight and focused. "
                "'Sir, incoming electromagnetic pulse from Sector Seven,' Thorne responded, fingers flying across the holographic terminal. "
                "'It is not random pulsar noise. In other words, there is a structured, mathematical sequence embedded within the carrier wave.' "
                "Vane leaned closer to the monitor. The signal repeated prime numbers in ascending order up to three hundred and fifty-nine. "
                "'Without a doubt,' Vane murmured, 'someone out there is deliberately announcing their presence.' "
                "Needless to say, protocol required an immediate encrypted transmission to Earth Command. But out here on the frontier, decisions had to be made in real time."
            ),
            (
                "Chapter 2: The Quantum Decryption",
                "Dr. Elena Vance initialized the station's quantum co-processor to decode the secondary modulation. "
                "'Taking into account the Doppler shift caused by the nebula's gravitational field,' Elena explained during the emergency staff meeting, "
                "'the origin point is situated inside a Lagrange corridor just past the asteroid belt.' "
                "'Is it a beacon, or a ship?' Chief Engineer Morales asked, wiping grease from his work gloves. "
                "'To tell you the truth,' Elena replied, 'it appears to be an automated geodesic transmitter left behind by an ancient civilization.' "
                "Morales shook his head. 'If we jump into that corridor without proper shielding, the gravitational shear could tear our sublight engines apart.' "
                "'Point taken,' Commander Vane conceded. 'However, opportunities like this occur once in a lifetime. We will proceed under low-impulse thrust, keeping navigational deflectors at maximum output.' "
                "The crew prepared the exploratory vessel Hermes for departure, the weight of humanity's greatest discovery hanging in the silence between stars."
            ),
            (
                "Chapter 3: The Encounter",
                "As the Hermes dropped out of warp near the designated coordinates, the sensor grid lit up with anomalous gravitational signatures. "
                "Lo and behold, drifting silently amidst the tumbling obsidian asteroids was a colossal crystalline spire, easily three kilometers in length. "
                "Its surface was flawlessly dark, absorbing light like velvet, yet faint geometric filigree pulsed with azure luminescence beneath the crystalline hull. "
                "'Navigation, maintain distance,' Vane ordered quietly, marveling at the monument of alien engineering. "
                "'Commander,' Thorne gasped, 'the object is scanning our communication logs. It has matched our linguistic frequencies.' "
                "A gentle harmonic voice resonated through the ship's audio comms, not through mechanical speakers, but directly vibrating through the bulkhead metals. "
                "'Welcome, travelers of the Sol cradle. We have waited twenty-five millennia for your arrival.' "
                "Commander Vane looked at his crew, whose faces reflected a blend of awe and disbelief. 'Long story short,' he smiled faintly, 'humanity is no longer alone in the cosmos.'"
            )
        ]
    },
    {
        "genre": "Mystery & Detective Fiction",
        "title": "The Cipher of Blackwood Manor",
        "chapters": [
            (
                "Chapter 1: The Vanishing Ledger",
                "Detective Julian Sterling arrived at Blackwood Manor as twilight settled over the misty Sussex moors. "
                "The grand Victorian estate was somber and cold, shadowed by ancient weeping willows. "
                "Lord Reginald Blackwood had been found locked inside his second-floor study, entirely unharmed, but completely disoriented. "
                "More pressingly, the legendary family ledger containing the registered patents for transatlantic telegraph cables had vanished into thin air. "
                "'Tell me exactly what transpired, Inspector Davies,' Sterling requested, hanging his wet trench coat in the grand foyer. "
                "'The door was bolted from the inside, Mr. Sterling,' Davies explained, thumbing through his notes. 'The windows were barred and locked. "
                "Plain and simple, nobody entered, and nobody left. Yet the iron safe stands open, and the ledger is gone.' "
                "Sterling lit his pipe and inhaled thoughtfully. 'When all is said and done, Inspector, impossible crimes usually rest upon very simple deceptions.'"
            ),
            (
                "Chapter 2: Clues in the Dust",
                "Entering the study, Sterling knelt near the Persian hearth rug. "
                "Using a pocket magnifying glass, he inspected the wainscoting along the eastern wall. "
                "'Notice anything peculiar, Inspector?' Sterling asked, pointing at the fine layer of soot along the skirting board. "
                "'Only chimney dust,' Davies grunted. "
                "'Look again. Upon further inspection, you will observe two parallel grooves pressed into the pine flooring. "
                "The bookcase does not merely hold books; it is balanced on concealed steel ball bearings.' "
                "With a firm press against the binding of an encyclopedia volume, the heavy oak shelves swung smoothly inward, revealing a damp stone staircase descending into the estate's wine cellars. "
                "'By the way,' Sterling added with a wry smile, 'the smell of freshly cut tobacco lingers in the tunnel. Our thief did not vanish into the ether; he walked right beneath our boots.'"
            ),
            (
                "Chapter 3: The Resolution",
                "Down in the subterranean arches, Sterling and Davies confronted the estate's private archivist, Mr. Finch, who was hastily packing documents into a leather valise. "
                "'Stop right there, Mr. Finch,' Davies bellowed, unholstering his service revolver. "
                "Finch froze, dropping his lantern onto the cobblestones. 'You don't understand! The patents were stolen from my grandfather decades ago. I merely reclaimed what was rightfully ours.' "
                "'Be that as it may,' Sterling countered calmly, stepping forward to retrieve the ledger, 'justice through subterfuge remains unlawful. "
                "At the end of the day, truth must stand in the daylight, not in the shadows of hidden passageways.' "
                "Finch lowered his head, knowing his elaborate scheme had come to an end. "
                "Sterling handed the recovered ledger to Davies. 'Case closed, Inspector. Now let us find a hot cup of tea before the London train departs.'"
            )
        ]
    },
    {
        "genre": "Philosophical & Literary Dialogue",
        "title": "Dialogues on Mind and Cosmos",
        "chapters": [
            (
                "Dialogue 1: The Nature of Perception",
                "Two scholars, Sophia and Marcus, walked along the colonnade overlooking the sunlit harbor of Alexandria. "
                "'Tell me, Sophia,' Marcus began, watching the gulls glide above the fishing smacks, 'do we perceive reality as it truly exists, or merely the shadows cast upon our senses?' "
                "Sophia paused, tracing the marble fluting of a pillar. 'To be honest, Marcus, modern natural philosophy suggests our senses are biological filters, not open windows. "
                "In other words, color is not an inherent property of light, but an internal neurological rendering of electromagnetic wavelengths.' "
                "'If that is true,' Marcus mused, 'then every individual inhabits a distinct perceptual universe.' "
                "'To a certain extent, yes,' Sophia replied. 'Yet our shared language, mathematics, and common survival bind those subjective worlds into a coherent, objective consensus. "
                "That is the miracle of consciousness: diversity of perception unified by the bridge of reason.'"
            ),
            (
                "Dialogue 2: The Architect of Tomorrow",
                "'Consider our machines,' Marcus remarked as they watched bronze water clocks ticking in the Agora. 'Can an artificial construct ever possess genuine subjective awareness?' "
                "'Fundamentally speaking,' Sophia answered, 'consciousness may not be bound to carbon and flesh. "
                "If awareness is a pattern of recursive feedback loops—information reflecting upon its own state—then any substrate capable of such topology might awaken.' "
                "'A startling thought,' Marcus said, scratching his beard. 'Would such a creation possess empathy, or merely cold calculation?' "
                "'Empathy arises from recognizing oneself in another,' Sophia explained softly. 'If we teach our creations only logic without love, they will be mirrors of our own coldness. "
                "Therefore, as we craft the mind of tomorrow, our first duty is to imbue it with kindness, patience, and humility. Without those core values, intelligence becomes a dangerous flame.'"
            )
        ]
    }
]

# ==============================================================================
# 3. High-Quality Multi-Domain Conversational Seed Library
# ==============================================================================

CONVERSATIONAL_SEEDS = [
    {
        "instruction": "Hello GeoMind! How are you doing today, and what can you help me with?",
        "response": (
            "Good morning! I am doing well, thank you for asking. "
            "As an intelligent assistant powered by CARTAN and the Lie Group E8 cognitive manifold, "
            "I can assist you with creative storytelling, technical reasoning, scientific inquiry, "
            "code generation, and philosophical discussions. What would you like to explore together today?"
        ),
        "target_phrase": "Good morning",
        "category": "social_ritual"
    },
    {
        "instruction": "Can you explain what happens when a star runs out of hydrogen fuel?",
        "response": (
            "Certainly! When a main-sequence star exhausts the hydrogen fuel in its core, "
            "inward gravitational pressure overcomes outward radiative pressure. "
            "Consequently, the core contracts and heats up until helium fusion ignites. "
            "Meanwhile, the outer envelopes expand enormously into a red giant. "
            "In other words, the star transforms dramatically in size and color before shedding its outer layers "
            "or, in massive stars, collapsing into a supernova that leaves behind a neutron star or black hole."
        ),
        "target_phrase": "In other words",
        "category": "science_explanation"
    },
    {
        "instruction": "I'm having a hard time balancing work deadlines with my creative writing hobbies. Any advice?",
        "response": (
            "I completely understand your frustration; it is easy to feel overwhelmed when balancing practical duties with personal passions. "
            "First of all, don't worry about writing thousands of words every day. "
            "Slow and steady progress is much more sustainable. Try dedicating just twenty focused minutes each morning before the workday begins. "
            "All in all, consistent daily habits yield far greater artistic results over time than occasional, exhaustive weekend marathons. "
            "Don't give up—your creative voice is deeply valuable!"
        ),
        "target_phrase": "Slow and steady",
        "category": "personal_advice"
    },
    {
        "instruction": "What is the difference between supervised learning and reinforcement learning in AI?",
        "response": (
            "Plain and simple, the core difference lies in the feedback mechanism. "
            "In supervised learning, the model learns from ground-truth labeled pairs, mapping inputs directly to known target outputs. "
            "In contrast to this, reinforcement learning trains an agent through trial and error within an environment, "
            "maximizing cumulative scalar rewards over time. "
            "To put it simply, supervised learning is like studying with an answer key, whereas reinforcement learning is like learning to ride a bicycle by practicing and balancing."
        ),
        "target_phrase": "In contrast to",
        "category": "technical_comparison"
    },
    {
        "instruction": "Could you write a short dialogue between two detectives discovering a crucial clue?",
        "response": (
            "'Check this out, Davies,' Detective Miller said, kneeling beside the shattered display case. "
            "'What did you find?' Davies asked, shining his flashlight beam onto the carpet. "
            "'A broken cufflink bearing the insignia of the Royal Yacht Club. Lo and behold, our thief left his signature behind.' "
            "'Believe it or not,' Davies whispered, 'Lord Harrington was wearing those exact cufflinks at dinner last night.' "
            "'That being the case,' Miller replied grimly, 'it is time we pay the estate a formal visit.'"
        ),
        "target_phrase": "Lo and behold",
        "category": "story_dialogue"
    },
    {
        "instruction": "Why is the preservation of biodiversity crucial for human survival?",
        "response": (
            "Biodiversity forms the fundamental safety net of Earth's life support systems. "
            "Every species, from soil microbes to apex predators, plays a specific ecological role in nutrient cycling, pollination, and water purification. "
            "At the end of the day, human civilization relies directly upon healthy ecosystems for food security, pharmaceuticals, and climate stability. "
            "If key ecological links are severed, cascading collapses threaten our own survival. "
            "Needless to say, protecting biological diversity is not merely an ethical choice—it is an existential imperative."
        ),
        "target_phrase": "At the end of the day",
        "category": "environmental_science"
    },
    {
        "instruction": "Can you summarize the concept of Occam's Razor?",
        "response": (
            "In a nutshell, Occam's Razor states that when presented with competing hypotheses that make identical predictions, "
            "one should select the hypothesis that introduces the fewest assumptions. "
            "To put it simply, the simplest sufficient explanation is usually the most probable. "
            "It does not guarantee that the simplest answer is always true, but it serves as an indispensable heuristic in scientific inquiry "
            "to prevent overcomplicated, unfalsifiable theories."
        ),
        "target_phrase": "In a nutshell",
        "category": "philosophy_logic"
    },
    {
        "instruction": "Tell me a short story about an unexpected act of kindness.",
        "response": (
            "The morning rain fell relentlessly over the city subway entrance. "
            "Marcus, soaked through his thin jacket, discovered that his wallet was missing just as he reached the turnstile. "
            "He stepped aside, feeling sick and tired from a grueling shift at the hospital. "
            "All of a sudden, an elderly woman tapped his shoulder, extending a warm smile and a transit pass. "
            "'Here you go, young man,' she said gently. 'We all need a helping hand now and then.' "
            "Marcus was speechless. 'Thank you so much. I don't know what to say.' "
            "'You're welcome,' she chuckled softly. 'Just pass the kindness forward when someone else needs it.' "
            "Her simple gesture warmed the gray morning more than the sun ever could."
        ),
        "target_phrase": "Now and then",
        "category": "story_kindness"
    }
]

# ==============================================================================
# 4. Procedural Dataset Synthesis Engine
# ==============================================================================

def generate_phrase_cloze_pairs():
    """Generates varied cloze sentence completion pairs for all attention triggers."""
    pairs = []
    
    # Templates for noun pairs
    noun_templates = [
        ("The local municipality invested heavily in modern [TARGET] to serve community needs.", 0),
        ("She researched the historical impact of [TARGET] during her graduate studies.", 1),
        ("Engineers worked around the clock to upgrade the facility's [TARGET] infrastructure.", 2),
        ("Proper maintenance of [TARGET] remains essential for operational reliability.", 3),
        ("The comprehensive report analyzed evolving consumer attitudes toward [TARGET].", 4)
    ]
    for phrase in NOUN_PAIRS:
        for tpl, idx in noun_templates:
            prompt = tpl.replace("[TARGET]", "[BLANK]")
            full_sent = tpl.replace("[TARGET]", phrase)
            pairs.append({
                "instruction": f"Complete the following sentence with the correct contextual phrase: \"{prompt}\"",
                "sentence_cloze": prompt,
                "target_phrase": phrase,
                "response": f"The correct phrase to complete the sentence is **{phrase}**.\n\nFull sentence: \"{full_sent}\"",
                "category": "noun_pair_cloze"
            })
            
    # Templates for binomial pairs
    binomial_templates = [
        ("In times of crisis, the community rallied together with [TARGET] to overcome hardship.", 0),
        ("The contract explicitly outlined the fundamental [TARGET] governing the partnership.", 1),
        ("Through patient [TARGET], the scientific team finally isolated the elusive compound.", 2),
        ("The old cottage stood firm against the winter storm, surviving [TARGET] without damage.", 3),
        ("She spoke with admirable clarity, making her intentions [TARGET] to all present.", 4)
    ]
    for phrase in BINOMIAL_PAIRS:
        for tpl, idx in binomial_templates:
            prompt = tpl.replace("[TARGET]", "[BLANK]")
            full_sent = tpl.replace("[TARGET]", phrase)
            pairs.append({
                "instruction": f"Fill in the blank with the appropriate English binomial idiom: \"{prompt}\"",
                "sentence_cloze": prompt,
                "target_phrase": phrase,
                "response": f"The natural binomial idiom is **{phrase}**.\n\nCompleted statement: \"{full_sent}\"",
                "category": "binomial_pair_cloze"
            })

    # Templates for functional phrases & discourse markers
    discourse_templates = [
        ("The team evaluated the unexpected quarterly results. [TARGET], the overall trajectory remains positive.", 0),
        ("We spent days searching for the missing ledger. [TARGET], it was filed in the archive basement.", 1),
        ("The experimental data confirmed our original hypothesis. [TARGET], further validation is warranted.", 2),
        ("He reviewed the intricate architectural schematics carefully. [TARGET], the structural integrity was sound.", 3),
        ("The expedition was delayed by unexpected storms. [TARGET], everyone arrived at camp safe and sound.", 4)
    ]
    for phrase in FUNCTIONAL_PHRASES + TRANSITION_MARKERS:
        for tpl, idx in discourse_templates:
            prompt = tpl.replace("[TARGET]", "[BLANK]")
            full_sent = tpl.replace("[TARGET]", phrase)
            pairs.append({
                "instruction": f"Choose the natural discourse marker to complete the narrative transition: \"{prompt}\"",
                "sentence_cloze": prompt,
                "target_phrase": phrase,
                "response": f"The ideal transition marker is **{phrase}**.\n\nFull sentence: \"{full_sent}\"",
                "category": "transition_marker_cloze"
            })

    return pairs

def mine_conversational_dialogues_from_corpus():
    """Extracts authentic dialogue exchanges from downloaded Gutenberg books in scratch/public_corpus/"""
    dialogue_pairs = []
    corpus_dir = os.path.join("scratch", "public_corpus")
    if not os.path.exists(corpus_dir):
        return dialogue_pairs

    for fname in os.listdir(corpus_dir):
        if not fname.endswith(".txt"):
            continue
        fpath = os.path.join(corpus_dir, fname)
        try:
            with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            
            # Normalize curly quotes to straight quotes
            norm_content = content.replace("\u201c", '"').replace("\u201d", '"')
            norm_content = norm_content.replace("\u2018", "'").replace("\u2019", "'")
            
            # Match quotes across newlines
            raw_quotes = re.findall(r'"([^"]{15,350})"', norm_content, re.DOTALL)
            quotes = [re.sub(r'\s+', ' ', q.strip()) for q in raw_quotes if len(re.sub(r'\s+', ' ', q.strip())) >= 20]
            
            book_title = fname.replace("_", " ").replace(".txt", "").title()
            print(f"  -> {fname}: found {len(quotes)} dialogue segments.")
            
            # Pair consecutive quotes as conversational banter
            for i in range(0, min(len(quotes) - 1, 600), 2):
                q1 = quotes[i]
                q2 = quotes[i+1]
                dialogue_pairs.append({
                    "instruction": f"In a classical literary conversation from {book_title}, respond to the following remark:\n\"{q1}\"",
                    "response": f"\"{q2}\"",
                    "target_phrase": "Literary Dialogue",
                    "category": "corpus_classical_dialogue"
                })
        except Exception as e:
            print(f"[Corpus Miner] Error reading {fname}: {e}")

    return dialogue_pairs

def build_complete_dataset():
    """Compiles the full suite of datasets and writes them to disk."""
    print("================================================================================")
    print("  BUILDING COMPREHENSIVE CONVERSATIONAL & STORYTELLING DATASET")
    print("================================================================================")

    out_dir = os.path.join("test", "geomind", "trainingdata")
    os.makedirs(out_dir, exist_ok=True)

    jsonl_path = os.path.join(out_dir, "conversational_storytelling_dataset.jsonl")
    story_prose_path = os.path.join(out_dir, "storytelling_corpus.txt")
    tinystories_path = os.path.join(out_dir, "hf_roneneldan_TinyStories.txt")
    alpaca_stories_path = os.path.join(out_dir, "hf_alpaca_stories.txt")

    all_jsonl_records = []

    # 1. Add curated seeds
    print("[1/5] Compiling curated conversational and story seeds...")
    for item in CONVERSATIONAL_SEEDS:
        all_jsonl_records.append(item)

    for story in TINY_STORIES_SEEDS:
        all_jsonl_records.append({
            "instruction": f"Write an engaging children's story about {', '.join(story['characters'])} in {story['setting']} demonstrating {story['theme']}.",
            "response": f"# {story['title']}\n\n{story['text']}",
            "target_phrase": "Storytelling Narrative",
            "category": "children_moral_story"
        })

    for seed in PROSE_STORY_SEEDS:
        for ch_title, ch_text in seed["chapters"]:
            all_jsonl_records.append({
                "instruction": f"Write {ch_title} of a {seed['genre']} story titled '{seed['title']}'.",
                "response": ch_text,
                "target_phrase": "Chapter Prose",
                "category": "creative_fiction"
            })

    # 2. Add procedural cloze & attention trigger pairs
    print("[2/5] Generating procedural cloze completion pairs for all attention triggers...")
    cloze_records = generate_phrase_cloze_pairs()
    all_jsonl_records.extend(cloze_records)
    print(f"  -> Generated {len(cloze_records)} high-precision attention trigger pairs.")

    # 3. Mine authentic classical dialogues
    print("[3/5] Mining classical dialogues from public domain literary corpus...")
    dialogue_records = mine_conversational_dialogues_from_corpus()
    all_jsonl_records.extend(dialogue_records)
    print(f"  -> Extracted {len(dialogue_records)} authentic dialogue turns from literature.")

    # Shuffle for balanced distribution during training
    random.shuffle(all_jsonl_records)

    # 4. Write primary JSONL dataset
    print(f"[4/5] Writing unified JSONL dataset to {jsonl_path} ({len(all_jsonl_records)} records)...")
    with open(jsonl_path, "w", encoding="utf-8") as f:
        for rec in all_jsonl_records:
            f.write(json.dumps(rec) + "\n")
    print(f"  -> Successfully saved {jsonl_path} ({os.path.getsize(jsonl_path)} bytes).")

    # 5. Generate and write prose & specialized text files
    print("[5/5] Generating narrative text corpora...")

    # hf_roneneldan_TinyStories.txt
    with open(tinystories_path, "w", encoding="utf-8") as f:
        for idx, story in enumerate(TINY_STORIES_SEEDS):
            f.write(f"Story {idx+1}: {story['title']}\n")
            f.write(f"Theme: {story['theme']}\n\n")
            f.write(story['text'] + "\n\n")
            f.write("-" * 80 + "\n\n")
        # Add procedural variations
        for c in range(100):
            char_a = random.choice(["Timmy the puppy", "Bella the kitten", "Sammy the squirrel", "Ruby the robin", "Milo the hedgehog"])
            char_b = random.choice(["an old turtle", "a wise brown owl", "a friendly baker", "a lost little bunny", "a singing cricket"])
            loc = random.choice(["the sunny meadow", "the apple orchard", "the whispering forest", "the river bridge", "the cozy barn"])
            moral = random.choice(["sharing toys", "listening carefully", "helping a friend in need", "being patient", "telling the truth"])
            transition = random.choice(["All of a sudden", "Sure enough", "Lo and behold", "Without a doubt", "Believe it or not"])
            f.write(f"Story {len(TINY_STORIES_SEEDS) + c + 1}: The Great Adventure of {char_a}\n")
            f.write(f"Theme: A tale about {moral} in {loc}.\n\n")
            f.write(
                f"Once upon a time, {char_a} was playing in {loc}. "
                f"The sun was warm and golden, and the flowers smelled sweet. "
                f"{char_a} met {char_b} who was looking for something important. "
                f"'Good morning!' {char_a} said warmly. 'Can I help you?' "
                f"{transition}, they found what they were looking for together. "
                f"They shared a joyful smile, knowing that kindness always brings happiness.\n\n"
            )
            f.write("-" * 80 + "\n\n")
    print(f"  -> Successfully generated {tinystories_path} ({os.path.getsize(tinystories_path)} bytes).")

    # hf_alpaca_stories.txt
    with open(alpaca_stories_path, "w", encoding="utf-8") as f:
        for rec in all_jsonl_records[:500]:
            f.write(f"Query: {rec['instruction']}\n")
            f.write(f"Response: {rec['response']}\n\n")
    print(f"  -> Successfully generated {alpaca_stories_path} ({os.path.getsize(alpaca_stories_path)} bytes).")

    # storytelling_corpus.txt (Massive continuous prose for causal pre-training)
    with open(story_prose_path, "w", encoding="utf-8") as f:
        f.write("================================================================================\n")
        f.write("  GEOMIND MULTI-GENRE STORYTELLING AND DIALOGUE NARRATIVE CORPUS\n")
        f.write("================================================================================\n\n")
        for seed in PROSE_STORY_SEEDS:
            f.write(f"BOOK TITLE: {seed['title']}\n")
            f.write(f"GENRE: {seed['genre']}\n\n")
            for ch_title, ch_text in seed["chapters"]:
                f.write(f"### {ch_title}\n\n")
                f.write(ch_text + "\n\n")
            f.write("=" * 80 + "\n\n")
        
        # Append curated dialogues
        f.write("CONVERSATIONAL DIALOGUES AND PHILOSOPHICAL INQUIRIES\n\n")
        for rec in CONVERSATIONAL_SEEDS:
            f.write(f"Speaker A: {rec['instruction']}\n")
            f.write(f"Speaker B: {rec['response']}\n\n")

        # Append classical literary dialogues
        f.write("CLASSICAL LITERARY DIALOGUES\n\n")
        for rec in dialogue_records:
            f.write(f"{rec['instruction']}\n")
            f.write(f"{rec['response']}\n\n")

        # Append clean literary chapters from public domain books
        f.write("================================================================================\n")
        f.write("  CLASSICAL LITERATURE NARRATIVE CHAPTERS & PROSE\n")
        f.write("================================================================================\n\n")
        corpus_dir = os.path.join("scratch", "public_corpus")
        if os.path.exists(corpus_dir):
            for fname in sorted(os.listdir(corpus_dir)):
                if not fname.endswith(".txt"):
                    continue
                fpath = os.path.join(corpus_dir, fname)
                book_name = fname.replace("_", " ").replace(".txt", "").title()
                f.write(f"\n--- BOOK: {book_name} ---\n\n")
                with open(fpath, "r", encoding="utf-8", errors="ignore") as bf:
                    text = bf.read()
                
                # Strip Gutenberg headers and footers
                start_marker = "*** START OF THE PROJECT GUTENBERG EBOOK"
                end_marker = "*** END OF THE PROJECT GUTENBERG EBOOK"
                s_idx = text.find(start_marker)
                if s_idx != -1:
                    line_end = text.find("\n", s_idx)
                    text = text[line_end + 1:]
                e_idx = text.find(end_marker)
                if e_idx != -1:
                    text = text[:e_idx]
                
                clean_text = text.strip()
                f.write(clean_text + "\n\n")
                print(f"  -> Ingested {len(clean_text)} bytes of clean narrative from {fname}.")

    print(f"  -> Successfully generated {story_prose_path} ({os.path.getsize(story_prose_path)} bytes).")
    print("================================================================================")
    print("  DATASET GENERATION COMPLETE & VERIFIED")
    print("================================================================================")

if __name__ == "__main__":
    build_complete_dataset()
