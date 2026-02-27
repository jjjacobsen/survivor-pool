(function () {
  const seasonNumber = 49;
  const finalWeek = 13;

  const contestants = [
    { name: "Nicole Mazullo", age: 26, hometown: "Philadelphia, PA", occupation: "Financial Crime Consultant" },
    { name: "Annie Davis", age: 49, hometown: "Austin, TX", occupation: "Musician" },
    { name: "Sage Ahrens-Nichols", age: 30, hometown: "Olympia, WA", occupation: "Clinical Social Worker" },
    { name: "Sophi Balerdi", age: 27, hometown: "Miami, FL", occupation: "Entrepreneur" },
    { name: "MC Chukwujekwu", age: 29, hometown: "San Diego, CA", occupation: "Fitness Trainer" },
    { name: "Shannon Fairweather", age: 27, hometown: "Boston, MA", occupation: "Wellness Specialist" },
    { name: "Jeremiah Ing", age: 38, hometown: "Toronto, ON", occupation: "Global Events Manager" },
    { name: "Jake Latimer", age: 35, hometown: "St. Albert, AB", occupation: "Correctional Officer" },
    { name: "Savannah Louie", age: 31, hometown: "Atlanta, GA", occupation: "Former Reporter" },
    { name: "Kristina Mills", age: 35, hometown: "Edmond, OK", occupation: "MBA Career Coach" },
    { name: "Alex Moore", age: 26, hometown: "Washington, DC", occupation: "Political Comms Director" },
    { name: "Nate Moore", age: 47, hometown: "Hermosa Beach, CA", occupation: "Film Producer" },
    { name: "Jawan Pitts", age: 28, hometown: "Los Angeles, CA", occupation: "Video Editor" },
    { name: "Steven Ramm", age: 35, hometown: "Denver, CO", occupation: "Rocket Scientist" },
    { name: "Sophie Segreti", age: 31, hometown: "New York, NY", occupation: "Strategy Associate" },
    { name: "Jason Treul", age: 32, hometown: "Santa Ana, CA", occupation: "Law Clerk" },
    { name: "Rizo Velovic", age: 25, hometown: "Yonkers, NY", occupation: "Tech Sales" },
    { name: "Matt Williams", age: 52, hometown: "St. George, UT", occupation: "Airport Ramp Agent" }
  ].map(c => ({
    id: idOf(c.name),
    name: c.name,
    age: c.age,
    occupation: c.occupation,
    hometown: c.hometown
  }));

  const eliminations = [
    { week: 1, eliminated_contestant_id: idOf("Nicole Mazullo") },
    { week: 2, eliminated_contestant_id: idOf("Annie Davis") },
    { week: 3, eliminated_contestant_id: idOf("Jake Latimer") },
    { week: 3, eliminated_contestant_id: idOf("Jeremiah Ing") },
    { week: 4, eliminated_contestant_id: idOf("Matt Williams") },
    { week: 5, eliminated_contestant_id: idOf("Jason Treul") },
    { week: 6, eliminated_contestant_id: idOf("Shannon Fairweather") },
    { week: 7, eliminated_contestant_id: idOf("Nate Moore") },
    { week: 8, eliminated_contestant_id: idOf("MC Chukwujekwu") },
    { week: 9, eliminated_contestant_id: idOf("Alex Moore") },
    { week: 10, eliminated_contestant_id: idOf("Jawan Pitts") },
    { week: 11, eliminated_contestant_id: idOf("Sophie Segreti") },
    { week: 12, eliminated_contestant_id: idOf("Steven Ramm") },
    { week: 13, eliminated_contestant_id: idOf("Kristina Mills") },
    { week: 13, eliminated_contestant_id: idOf("Rizo Velovic") }
  ];

  const tribeTimeline = [
    {
      week: 1,
      event: "start",
      tribes: [
        {
          name: "Kele",
          color: "#32AAD6",
          members: [
            idOf("Nicole Mazullo"),
            idOf("Annie Davis"),
            idOf("Sophi Balerdi"),
            idOf("Jeremiah Ing"),
            idOf("Jake Latimer"),
            idOf("Alex Moore")
          ]
        },
        {
          name: "Uli",
          color: "#F26B52",
          members: [
            idOf("Sage Ahrens-Nichols"),
            idOf("Shannon Fairweather"),
            idOf("Savannah Louie"),
            idOf("Nate Moore"),
            idOf("Jawan Pitts"),
            idOf("Rizo Velovic")
          ]
        },
        {
          name: "Hina",
          color: "#FEDA47",
          members: [
            idOf("MC Chukwujekwu"),
            idOf("Kristina Mills"),
            idOf("Steven Ramm"),
            idOf("Sophie Segreti"),
            idOf("Jason Treul"),
            idOf("Matt Williams")
          ]
        }
      ]
    },
    {
      week: 4,
      event: "swap",
      notes: "Day 7 tribe switch dissolved Uli and reformed two tribes of seven",
      tribes: [
        {
          name: "Hina",
          color: "#FEDA47",
          members: [
            idOf("Jason Treul"),
            idOf("Jawan Pitts"),
            idOf("Matt Williams"),
            idOf("Nate Moore"),
            idOf("Rizo Velovic"),
            idOf("Savannah Louie"),
            idOf("Sophi Balerdi")
          ]
        },
        {
          name: "Kele",
          color: "#32AAD6",
          members: [
            idOf("Alex Moore"),
            idOf("Kristina Mills"),
            idOf("MC Chukwujekwu"),
            idOf("Sage Ahrens-Nichols"),
            idOf("Shannon Fairweather"),
            idOf("Sophie Segreti"),
            idOf("Steven Ramm")
          ]
        }
      ]
    },
    {
      week: 6,
      event: "swap",
      notes: "Day 11 expansion reinstated Uli and split into three tribes of four",
      tribes: [
        {
          name: "Hina",
          color: "#FEDA47",
          members: [
            idOf("MC Chukwujekwu"),
            idOf("Rizo Velovic"),
            idOf("Savannah Louie"),
            idOf("Sophi Balerdi")
          ]
        },
        {
          name: "Kele",
          color: "#32AAD6",
          members: [
            idOf("Jawan Pitts"),
            idOf("Sage Ahrens-Nichols"),
            idOf("Shannon Fairweather"),
            idOf("Steven Ramm")
          ]
        },
        {
          name: "Uli",
          color: "#F26B52",
          members: [
            idOf("Alex Moore"),
            idOf("Kristina Mills"),
            idOf("Nate Moore"),
            idOf("Sophie Segreti")
          ]
        }
      ]
    },
    {
      week: 7,
      event: "merge",
      notes: "Traditional merge at final eleven on the former Kele beach, forming Lewatu",
      tribes: [
        {
          name: "Lewatu",
          color: "#000000",
          members: [
            idOf("Alex Moore"),
            idOf("Jawan Pitts"),
            idOf("Kristina Mills"),
            idOf("MC Chukwujekwu"),
            idOf("Nate Moore"),
            idOf("Rizo Velovic"),
            idOf("Sage Ahrens-Nichols"),
            idOf("Savannah Louie"),
            idOf("Sophi Balerdi"),
            idOf("Sophie Segreti"),
            idOf("Steven Ramm")
          ]
        }
      ]
    }
  ];

  const advantages = [
    {
      id: "idol_alex_moore_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Alex Moore"),
      obtained_week: 2,
      acquisition_notes: "Opened the Kele beware idol on Day 4, lost his vote, then dug by the well after the Ep2 loss to unearth the idol",
      end_week: 3,
      end_notes: "Played on himself at week 3 Tribal Council and negated the votes against him as Jeremiah was voted out"
    },
    {
      id: "idol_mc_chukwujekwu_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("MC Chukwujekwu"),
      obtained_week: 7,
      acquisition_notes: "Unlocked the merge rehidden idol with the massive key ring after her RC-losing group couldn't compete for immunity",
      end_week: 7,
      end_notes: "Played on herself at the first merge Tribal where Nate became the first juror"
    },
    {
      id: "idol_rizo_velovic_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Rizo Velovic"),
      obtained_week: 4,
      acquisition_notes: "Retrieved the idol from Hina's underwater chest after allies dug up the beware clue and key",
      end_week: 13,
      end_notes: "Played on Savannah at the final-five Tribal Council and all votes landed on Kristina instead"
    },
    {
      id: "kip_sophi_balerdi_1",
      advantage_type: "knowledge_is_power",
      advantage_display_name: "Knowledge is Power",
      contestant_id: idOf("Sophi Balerdi"),
      obtained_week: 6,
      acquisition_notes: "Spotted the Knowledge is Power parchment near Hina's camp after the three-tribe expansion",
      end_week: 12,
      end_notes: "Attempted to use at the week 12 Tribal on Steven after his vote blocker was already played, so the steal failed"
    },
    {
      id: "challenge_advantage_sage_1",
      advantage_type: "challenge_advantage",
      advantage_display_name: "Challenge Advantage",
      contestant_id: idOf("Sage Ahrens-Nichols"),
      obtained_week: 7,
      acquisition_notes: "Unlocked the merge chest on Day 13 to claim the challenge advantage",
      end_week: 7,
      end_notes: "Used immediately to skip the merge reward challenge and compete for immunity"
    },
    {
      id: "journey_disadvantage_jawan_1",
      advantage_type: "challenge_disadvantage",
      advantage_display_name: "Challenge Disadvantage",
      contestant_id: idOf("Jawan Pitts"),
      obtained_week: 2,
      acquisition_notes: "Won the Nut Bucket journey and chose the tribe-disadvantage option for the next challenge",
      end_week: 2,
      end_notes: "Used at the Day 5 Mona Lisas and Mad Ladders challenge to saddle another tribe with extra weight and keys"
    },
    {
      id: "idol_kristina_mills_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Kristina Mills"),
      obtained_week: 8,
      acquisition_notes: "Dug up the rehidden idol on Lewatu beach after MC's idol play",
      end_week: 10,
      end_notes: "Played on Steven at Jawan's boot; no votes were cast for him"
    },
    {
      id: "challenge_advantage_savannah_louie_1",
      advantage_type: "challenge_advantage",
      advantage_display_name: "Challenge Advantage",
      contestant_id: idOf("Savannah Louie"),
      obtained_week: 8,
      acquisition_notes: "Won the overall individual reward and immunity challenge to claim a challenge advantage",
      end_week: 9,
      end_notes: "Cashed in by banking her vote at the week 9 Tribal Council to receive an extra vote"
    },
    {
      id: "extra_vote_savannah_louie_1",
      advantage_type: "extra_vote",
      advantage_display_name: "Extra Vote",
      contestant_id: idOf("Savannah Louie"),
      obtained_week: 9,
      acquisition_notes: "Received after banking her vote at the week 9 Tribal Council",
      end_week: 10,
      end_notes: "Used to cast two votes at the week 10 Tribal where Jawan left (5-3-1)"
    },
    {
      id: "vote_blocker_steven_ramm_1",
      advantage_type: "vote_blocker",
      advantage_display_name: "Vote Blocker",
      contestant_id: idOf("Steven Ramm"),
      obtained_week: 11,
      acquisition_notes: "Won the vote blocker during the Day 20 island run journey",
      end_week: 12,
      end_notes: "Played before leaving camp to block Savannah's vote at the week 12 Tribal, but Steven was voted out 4-1"
    },
    {
      id: "challenge_advantage_sophi_balerdi_1",
      advantage_type: "challenge_advantage",
      advantage_display_name: "Challenge Advantage",
      contestant_id: idOf("Sophi Balerdi"),
      obtained_week: 13,
      acquisition_notes: "Solved the Day 24 boat-puzzle table clue and found the challenge advantage marker in a tree",
      end_week: 13,
      end_notes: "Used in the final-five immunity challenge"
    }
  ];

  registerSeason({
    season_name: "Survivor 49",
    season_number: seasonNumber,
    air_date: new Date("2025-09-24T00:00:00Z"),
    location: "Fiji",
    format: "new_era",
    final_week: finalWeek,
    contestants,
    eliminations,
    tribe_timeline: tribeTimeline,
    advantages
  });
})();
