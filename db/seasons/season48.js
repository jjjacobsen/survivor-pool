(function () {
  const seasonNumber = 48;
  const finalWeek = 13;

  const contestants = [
    { name: "Kyle Fraser", age: 30, hometown: "Brooklyn, NY", occupation: "Attorney" },
    { name: "Eva Erickson", age: 23, hometown: "Providence, RI", occupation: "PhD Candidate" },
    { name: "Joe Hunter", age: 45, hometown: "West Sacramento, CA", occupation: "Fire Captain" },
    { name: "Kamilla Karthigesu", age: 30, hometown: "Foster City, CA", occupation: "Software Engineer" },
    { name: "David Kinne", age: 38, hometown: "Buena Park, CA", occupation: "Stunt Performer" },
    { name: "Chrissy Sarnowsky", age: 54, hometown: "Chicago, IL", occupation: "Fire Lieutenant" },
    { name: "Mitch Guerra", age: 34, hometown: "Waco, TX", occupation: "P.E. Coach" },
    { name: "Shauhin Davari", age: 37, hometown: "Costa Mesa, CA", occupation: "Debate Professor" },
    { name: "Mary Zheng", age: 30, hometown: "Philadelphia, PA", occupation: "Substance Abuse Counselor" },
    { name: "Star Toomey", age: 27, hometown: "Augusta, GA", occupation: "Sales Expert" },
    { name: "Cedrek McFadden", age: 45, hometown: "Greenville, SC", occupation: "Surgeon" },
    { name: "Saiounia Hughley", age: 29, hometown: "Simi Valley, CA", occupation: "Marketing Professional" },
    { name: "Charity Nelms", age: 33, hometown: "St. Petersburg, FL", occupation: "Flight Attendant" },
    { name: "Bianca Roses", age: 32, hometown: "Arlington, VA", occupation: "PR Consultant" },
    { name: "Thomas Krottinger", age: 34, hometown: "Los Angeles, CA", occupation: "Music Executive" },
    { name: "Justin Pioppi", age: 29, hometown: "Winthrop, MA", occupation: "Pizzeria Manager" },
    { name: "Kevin Leung", age: 33, hometown: "Livermore, CA", occupation: "Finance Manager" },
    { name: "Stephanie Berger", age: 37, hometown: "Brooklyn, NY", occupation: "Tech Product Lead" }
  ].map(c => ({
    id: idOf(c.name),
    name: c.name,
    age: c.age,
    occupation: c.occupation,
    hometown: c.hometown
  }));

  const eliminations = [
    { week: 1, eliminated_contestant_id: idOf("Stephanie Berger") },
    { week: 2, eliminated_contestant_id: idOf("Kevin Leung") },
    { week: 3, eliminated_contestant_id: idOf("Justin Pioppi") },
    { week: 4, eliminated_contestant_id: idOf("Thomas Krottinger") },
    { week: 5, eliminated_contestant_id: idOf("Bianca Roses") },
    { week: 6, eliminated_contestant_id: idOf("Charity Nelms") },
    { week: 7, eliminated_contestant_id: idOf("Saiounia Hughley") },
    { week: 7, eliminated_contestant_id: idOf("Cedrek McFadden") },
    { week: 8, eliminated_contestant_id: idOf("Chrissy Sarnowsky") },
    { week: 9, eliminated_contestant_id: idOf("David Kinne") },
    { week: 10, eliminated_contestant_id: idOf("Star Toomey") },
    { week: 11, eliminated_contestant_id: idOf("Mary Zheng") },
    { week: 12, eliminated_contestant_id: idOf("Shauhin Davari") },
    { week: 13, eliminated_contestant_id: idOf("Mitch Guerra") },
    { week: 13, eliminated_contestant_id: idOf("Kamilla Karthigesu") }
  ];

  const tribeTimeline = [
    {
      week: 1,
      event: "start",
      tribes: [
        { name: "Lagi", color: "purple", members: [
          idOf("Joe Hunter"), idOf("Eva Erickson"), idOf("Thomas Krottinger"), idOf("Star Toomey"), idOf("Shauhin Davari"), idOf("Bianca Roses")
        ]},
        { name: "Civa", color: "orange", members: [
          idOf("Kyle Fraser"), idOf("Kamilla Karthigesu"), idOf("David Kinne"), idOf("Chrissy Sarnowsky"), idOf("Mitch Guerra"), idOf("Charity Nelms")
        ]},
        { name: "Vula", color: "green", members: [
          idOf("Saiounia Hughley"), idOf("Cedrek McFadden"), idOf("Mary Zheng"), idOf("Kevin Leung"), idOf("Justin Pioppi"), idOf("Stephanie Berger")
        ]}
      ]
    },
    {
      week: 4,
      event: "swap",
      notes: "Day 8 tribe switch into three tribes of five",
      tribes: [
        { name: "Lagi", color: "purple", members: [
          idOf("Charity Nelms"), idOf("David Kinne"), idOf("Eva Erickson"), idOf("Mary Zheng"), idOf("Star Toomey")
        ]},
        { name: "Civa", color: "orange", members: [
          idOf("Bianca Roses"), idOf("Cedrek McFadden"), idOf("Chrissy Sarnowsky"), idOf("Mitch Guerra"), idOf("Saiounia Hughley")
        ]},
        { name: "Vula", color: "green", members: [
          idOf("Joe Hunter"), idOf("Kamilla Karthigesu"), idOf("Kyle Fraser"), idOf("Shauhin Davari"), idOf("Thomas Krottinger")
        ]}
      ]
    },
    {
      week: 7,
      event: "merge",
      tribes: [
        { name: "Niu Nai", color: "blue", members: [
          idOf("Joe Hunter"), idOf("Eva Erickson"), idOf("Kyle Fraser"), idOf("Kamilla Karthigesu"), idOf("David Kinne"), idOf("Chrissy Sarnowsky"), idOf("Mitch Guerra"), idOf("Shauhin Davari"), idOf("Mary Zheng"), idOf("Star Toomey"), idOf("Cedrek McFadden"), idOf("Saiounia Hughley")
        ]}
      ]
    }
  ];

  const advantages = [
    {
      id: "idol_saiounia_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Saiounia Hughley"),
      obtained_week: 1,
      acquisition_notes: "Found via Beware Advantage on Vula",
      end_week: 2,
      end_notes: "Played at Vula's week 2 Tribal Council"
    },
    {
      id: "idol_kyle_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Kyle Fraser"),
      obtained_week: 2,
      acquisition_notes: "Found the Civa idol back at camp after the day 4 journey",
      end_week: 4,
      end_notes: "Played after the swap to cancel votes, sending Thomas home"
    },
    {
      id: "beware_star_1",
      advantage_type: "beware_advantage",
      advantage_display_name: "Beware Advantage",
      contestant_id: idOf("Star Toomey"),
      obtained_week: 2,
      acquisition_notes: "Found the Beware Advantage cryptex at the Lagi camp",
      end_week: 5,
      end_notes: "Cryptex solved at the swapped Lagi camp and the idol moved to Eva"
    },
    {
      id: "idol_eva_erickson_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Eva Erickson"),
      obtained_week: 5,
      acquisition_notes: "Unlocked the idol after solving the Beware Advantage cryptex Star found",
      end_week: 13,
      end_notes: "Played at the final five; no votes landed on Eva and Mitch still left 4-1"
    },
    {
      id: "challenge_advantage_saiounia_1",
      advantage_type: "challenge_advantage",
      advantage_display_name: "Challenge Advantage",
      contestant_id: idOf("Saiounia Hughley"),
      obtained_week: 6,
      acquisition_notes: "Found the Earn-the-Merge sit-out advantage before the team challenge",
      end_week: 6,
      end_notes: "Used to skip the team stage of the Earn-the-Merge and advance to the individual IC"
    },
    {
      id: "block_vote_mitch_1",
      advantage_type: "block_a_vote",
      advantage_display_name: "Block a Vote",
      contestant_id: idOf("Mitch Guerra"),
      obtained_week: 2,
      acquisition_notes: "Won the vote block on a day 4 journey challenge",
      end_week: 7,
      end_notes: "Used at the first split Tribal to block Saiounia's vote in the 5-0 boot"
    },
    {
      id: "steal_vote_thomas_1",
      advantage_type: "steal_a_vote",
      advantage_display_name: "Steal a Vote",
      contestant_id: idOf("Thomas Krottinger"),
      obtained_week: 2,
      acquisition_notes: "Won the vote steal on the day 4 journey challenge",
      end_week: 4,
      end_notes: "Voted out at the first post-swap Tribal with the steal-a-vote unused"
    },
    {
      id: "extra_vote_kamilla_1",
      advantage_type: "extra_vote",
      advantage_display_name: "Extra Vote",
      contestant_id: idOf("Kamilla Karthigesu"),
      obtained_week: 3,
      acquisition_notes: "Won an extra vote on the day 7 dice-roll journey",
      end_week: 4,
      end_notes: "Transferred to Kyle before the post-swap Vula Tribal Council"
    },
    {
      id: "extra_vote_kyle_1",
      advantage_type: "extra_vote",
      advantage_display_name: "Extra Vote",
      contestant_id: idOf("Kyle Fraser"),
      obtained_week: 4,
      acquisition_notes: "Received from Kamilla before the post-swap Vula Tribal Council",
      end_week: 4,
      end_notes: "Used at the post-swap Vula Tribal Council where Thomas was voted out"
    },
    {
      id: "extra_vote_eva_1",
      advantage_type: "extra_vote",
      advantage_display_name: "Extra Vote",
      contestant_id: idOf("Eva Erickson"),
      obtained_week: 9,
      acquisition_notes: "Took the extra vote option first from the Night 16 advantage stash",
      end_week: 9,
      end_notes: "Risked it on the second pull from the stash and swapped it for Safety Without Power"
    },
    {
      id: "safety_without_power_eva_1",
      advantage_type: "safety_without_power",
      advantage_display_name: "Safety Without Power",
      contestant_id: idOf("Eva Erickson"),
      obtained_week: 9,
      acquisition_notes: "Took Safety Without Power from the Night 16 advantage stash after risking for it",
      end_week: 11,
      end_notes: "Expired unused after the final-seven Mary vote when its window closed"
    },
    {
      id: "challenge_advantage_eva_1",
      advantage_type: "challenge_advantage",
      advantage_display_name: "Challenge Advantage",
      contestant_id: idOf("Eva Erickson"),
      obtained_week: 13,
      acquisition_notes: "Solved the final-five puzzle lock for a challenge advantage",
      end_week: 13,
      end_notes: "Used for the final-five immunity challenge shortcut"
    }
  ];

  registerSeason({
    season_name: "Survivor 48",
    season_number: seasonNumber,
    air_date: new Date("2025-02-26T00:00:00Z"),
    location: "Fiji",
    format: "new_era",
    final_week: finalWeek,
    contestants,
    eliminations,
    tribe_timeline: tribeTimeline,
    advantages
  });
})();
