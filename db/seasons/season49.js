(function () {
  const seasonNumber = 49;

  const contestants = [
    { name: "Nicole Mazullo", age: 26, hometown: "Philadelphia, PA", occupation: "Financial crime consultant" },
    { name: "Kimberly \"Annie\" Davis", age: 49, hometown: "Austin, TX", occupation: "Musician" },
    { name: "Sage Ahrens-Nichols", age: 30, hometown: "Olympia, WA", occupation: "Clinical social worker" },
    { name: "Sophia \"Sophi\" Balerdi", age: 27, hometown: "Miami, FL", occupation: "Entrepreneur" },
    { name: "Michelle \"MC\" Chukwujekwu", age: 29, hometown: "San Diego, CA", occupation: "Fitness trainer" },
    { name: "Shannon Fairweather", age: 28, hometown: "Boston, MA", occupation: "Wellness specialist" },
    { name: "Jeremiah Ing", age: 39, hometown: "Toronto, Ontario", occupation: "Global events manager" },
    { name: "Jake Latimer", age: 36, hometown: "St. Albert, Alberta", occupation: "Correctional officer" },
    { name: "Savannah Louie", age: 31, hometown: "Atlanta, GA", occupation: "Former reporter" },
    { name: "Kristina Mills", age: 36, hometown: "Edmond, OK", occupation: "MBA career coach" },
    { name: "Alex Moore", age: 27, hometown: "Washington, DC", occupation: "Political comms director" },
    { name: "Nate Moore", age: 47, hometown: "Hermosa Beach, CA", occupation: "Film producer" },
    { name: "Jawan Pitts", age: 28, hometown: "Los Angeles, CA", occupation: "Video editor" },
    { name: "Steven Ramm", age: 35, hometown: "Denver, CO", occupation: "Rocket scientist" },
    { name: "Sophia \"Sophie\" Segreti", age: 31, hometown: "New York City, NY", occupation: "Strategy associate" },
    { name: "Jason Treul", age: 32, hometown: "Santa Ana, CA", occupation: "Law clerk" },
    { name: "Rizo Velovic", age: 25, hometown: "Yonkers, NY", occupation: "Tech sales" },
    { name: "Matthew \"Matt\" Williams", age: 52, hometown: "St. George, UT", occupation: "Airport ramp agent" }
  ].map(c => ({
    id: idOf(c.name),
    name: c.name,
    age: c.age,
    occupation: c.occupation,
    hometown: c.hometown
  }));

  const eliminations = [
    { week: 1, eliminated_contestant_id: idOf("Nicole Mazullo") },
    { week: 2, eliminated_contestant_id: idOf("Kimberly \"Annie\" Davis") },
    { week: 3, eliminated_contestant_id: idOf("Jake Latimer") },
    { week: 3, eliminated_contestant_id: idOf("Jeremiah Ing") },
    { week: 4, eliminated_contestant_id: idOf("Matthew \"Matt\" Williams") },
    { week: 5, eliminated_contestant_id: idOf("Jason Treul") },
    { week: 6, eliminated_contestant_id: idOf("Shannon Fairweather") },
    { week: 7, eliminated_contestant_id: idOf("Nate Moore") },
    { week: 8, eliminated_contestant_id: idOf("Michelle \"MC\" Chukwujekwu") },
    { week: 9, eliminated_contestant_id: idOf("Alex Moore") },
    { week: 10, eliminated_contestant_id: idOf("Jawan Pitts") },
    { week: 11, eliminated_contestant_id: idOf("Sophia \"Sophie\" Segreti") }
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
            idOf("Kimberly \"Annie\" Davis"),
            idOf("Sophia \"Sophi\" Balerdi"),
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
            idOf("Michelle \"MC\" Chukwujekwu"),
            idOf("Kristina Mills"),
            idOf("Steven Ramm"),
            idOf("Sophia \"Sophie\" Segreti"),
            idOf("Jason Treul"),
            idOf("Matthew \"Matt\" Williams")
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
            idOf("Matthew \"Matt\" Williams"),
            idOf("Nate Moore"),
            idOf("Rizo Velovic"),
            idOf("Savannah Louie"),
            idOf("Sophia \"Sophi\" Balerdi")
          ]
        },
        {
          name: "Kele",
          color: "#32AAD6",
          members: [
            idOf("Alex Moore"),
            idOf("Kristina Mills"),
            idOf("Michelle \"MC\" Chukwujekwu"),
            idOf("Sage Ahrens-Nichols"),
            idOf("Shannon Fairweather"),
            idOf("Sophia \"Sophie\" Segreti"),
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
            idOf("Michelle \"MC\" Chukwujekwu"),
            idOf("Rizo Velovic"),
            idOf("Savannah Louie"),
            idOf("Sophia \"Sophi\" Balerdi")
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
            idOf("Sophia \"Sophie\" Segreti")
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
            idOf("Michelle \"MC\" Chukwujekwu"),
            idOf("Nate Moore"),
            idOf("Rizo Velovic"),
            idOf("Sage Ahrens-Nichols"),
            idOf("Savannah Louie"),
            idOf("Sophia \"Sophi\" Balerdi"),
            idOf("Sophia \"Sophie\" Segreti"),
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
      status: "expired",
      played_week: null,
      transferred_to: null,
      notes: "Alex completed the beware activation steps on Kele in week 2"
    },
    {
      id: "idol_mc_chukwujekwu_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Michelle \"MC\" Chukwujekwu"),
      obtained_week: 3,
      status: "played",
      played_week: 7,
      transferred_to: null,
      notes: "MC finished the beware tasks after the merge feast chest search"
    },
    {
      id: "idol_rizo_velovic_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Rizo Velovic"),
      obtained_week: 4,
      status: "active",
      played_week: null,
      transferred_to: null,
      notes: "Savannah, Jawan, and Nate dug up Hina's beware clue/key post-swap and handed it to Rizo, letting him retrieve the idol from the underwater chest"
    },
    {
      id: "kip_sophi_balerdi_1",
      advantage_type: "knowledge_is_power",
      advantage_display_name: "Knowledge is Power",
      contestant_id: idOf("Sophia \"Sophi\" Balerdi"),
      obtained_week: 6,
      status: "active",
      played_week: null,
      transferred_to: null,
      notes: "Sophi spotted the Knowledge is Power parchment near Hina's camp the day after the three-tribe expansion"
    },
    {
      id: "challenge_advantage_sage_1",
      advantage_type: "challenge_advantage",
      advantage_display_name: "Challenge Advantage",
      contestant_id: idOf("Sage Ahrens-Nichols"),
      obtained_week: 7,
      status: "played",
      played_week: 7,
      transferred_to: null,
      notes: "Sage unlocked the merge chest on Day 13 to claim the challenge advantage"
    },
    {
      id: "idol_kristina_mills_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Kristina Mills"),
      obtained_week: 8,
      status: "played",
      played_week: 10,
      transferred_to: null,
      notes: "Kristina dug up Lewatu's hidden idol on Day 15 ahead of the Chimney Sweeps merge challenge"
    },
    {
      id: "extra_vote_savannah_louie_1",
      advantage_type: "extra_vote",
      advantage_display_name: "Extra Vote",
      contestant_id: idOf("Savannah Louie"),
      obtained_week: 8,
      status: "played",
      played_week: 10,
      transferred_to: null,
      notes: "Savannah won the Chimney Sweeps endurance reward/immunity challenge advantage and banked the extra vote for a later Tribal"
    },
    {
      id: "vote_blocker_steven_ramm_1",
      advantage_type: "vote_blocker",
      advantage_display_name: "Vote Blocker",
      contestant_id: idOf("Steven Ramm"),
      obtained_week: 11,
      status: "active",
      played_week: null,
      transferred_to: null,
      notes: "Steven won the vote blocker during the Day 20 journey sprint"
    }
  ];

  registerSeason({
    season_name: "Survivor 49",
    season_number: seasonNumber,
    air_date: new Date("2025-09-24T00:00:00Z"),
    location: "Fiji",
    format: "new_era",
    contestants,
    eliminations,
    tribe_timeline: tribeTimeline,
    advantages
  });
})();
