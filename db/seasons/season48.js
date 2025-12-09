(function () {
  const seasonNumber = 48;

  const contestants = [
    { name: "Kyle Fraser", age: 30, hometown: "Brooklyn, NY", occupation: "Digital Strategist" },
    { name: "Eva Erickson", age: 23, hometown: "Providence, RI", occupation: "Biotech Researcher" },
    { name: "Joe Hunter", age: 45, hometown: "West Sacramento, CA", occupation: "Firefighter" },
    { name: "Kamilla Karthigesu", age: 30, hometown: "Foster City, CA", occupation: "Product Manager" },
    { name: "David Kinne", age: 38, hometown: "Buena Park, CA", occupation: "Elementary Teacher" },
    { name: "Chrissy Sarnowsky", age: 54, hometown: "Chicago, IL", occupation: "Tax Consultant" },
    { name: "Mitch Guerra", age: 34, hometown: "Waco, TX", occupation: "Fitness Coach" },
    { name: "Shauhin Davari", age: 37, hometown: "Costa Mesa, CA", occupation: "Sports Agent" },
    { name: "Mary Zheng", age: 30, hometown: "Philadelphia, PA", occupation: "Data Analyst" },
    { name: "Star Toomey", age: 27, hometown: "Augusta, GA", occupation: "Graphic Designer" },
    { name: "Cedrek McFadden", age: 45, hometown: "Greenville, SC", occupation: "Youth Pastor" },
    { name: "Saiounia Hughley", age: 29, hometown: "Simi Valley, CA", occupation: "Marketing Specialist" },
    { name: "Charity Nelms", age: 33, hometown: "St. Petersburg, FL", occupation: "Real Estate Broker" },
    { name: "Bianca Roses", age: 32, hometown: "Arlington, VA", occupation: "Public Defender" },
    { name: "Thomas Krottinger", age: 34, hometown: "Los Angeles, CA", occupation: "Entrepreneur" },
    { name: "Justin Pioppi", age: 29, hometown: "Winthrop, MA", occupation: "Bartender" },
    { name: "Kevin Leung", age: 33, hometown: "Livermore, CA", occupation: "Mechanical Engineer" },
    { name: "Stephanie Berger", age: 37, hometown: "Brooklyn, NY", occupation: "Nurse Practitioner" }
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
      notes: "Three-tribe swap to 5-5-5; membership best-effort from aired data",
      tribes: [
        { name: "Lagi", color: "purple", members: [
          idOf("Joe Hunter"), idOf("Eva Erickson"), idOf("Kyle Fraser"), idOf("Kamilla Karthigesu"), idOf("David Kinne")
        ]},
        { name: "Civa", color: "orange", members: [
          idOf("Mitch Guerra"), idOf("Chrissy Sarnowsky"), idOf("Bianca Roses"), idOf("Saiounia Hughley"), idOf("Cedrek McFadden")
        ]},
        { name: "Vula", color: "green", members: [
          idOf("Mary Zheng"), idOf("Shauhin Davari"), idOf("Star Toomey"), idOf("Thomas Krottinger"), idOf("Charity Nelms")
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
      acquisition_notes: "Found via Beware Advantage on Vula"
    },
    {
      id: "idol_kyle_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Kyle Fraser"),
      obtained_week: 2,
      acquisition_notes: "Found on Civa after working with Kamilla on the clue"
    },
    {
      id: "beware_star_1",
      advantage_type: "beware_advantage",
      advantage_display_name: "Beware Advantage",
      contestant_id: idOf("Star Toomey"),
      obtained_week: 2,
      acquisition_notes: "Found the Beware Advantage cryptex at the Lagi camp"
    },
    {
      id: "idol_eva_erickson_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Hidden Immunity Idol",
      contestant_id: idOf("Eva Erickson"),
      obtained_week: 5,
      acquisition_notes: "Unlocked the idol after solving the Beware Advantage cryptex Star found"
    },
    {
      id: "challenge_advantage_saiounia_1",
      advantage_type: "challenge_advantage",
      advantage_display_name: "Challenge Advantage",
      contestant_id: idOf("Saiounia Hughley"),
      obtained_week: 6,
      acquisition_notes: "Found the Earn-the-Merge sit-out advantage before the team challenge"
    },
    {
      id: "block_vote_mitch_1",
      advantage_type: "block_a_vote",
      advantage_display_name: "Block a Vote",
      contestant_id: idOf("Mitch Guerra"),
      obtained_week: 2,
      acquisition_notes: "Won the vote block on a day 4 journey challenge"
    },
    {
      id: "steal_vote_thomas_1",
      advantage_type: "steal_a_vote",
      advantage_display_name: "Steal a Vote",
      contestant_id: idOf("Thomas Krottinger"),
      obtained_week: 2,
      acquisition_notes: "Won the vote steal on the day 4 journey challenge"
    },
    {
      id: "extra_vote_kamilla_1",
      advantage_type: "extra_vote",
      advantage_display_name: "Extra Vote",
      contestant_id: idOf("Kamilla Karthigesu"),
      obtained_week: 3,
      acquisition_notes: "Won an extra vote on the day 7 dice-roll journey"
    },
    {
      id: "safety_without_power_eva_1",
      advantage_type: "safety_without_power",
      advantage_display_name: "Safety Without Power",
      contestant_id: idOf("Eva Erickson"),
      obtained_week: 9,
      acquisition_notes: "Won Safety Without Power during the late-game night journey"
    },
    {
      id: "challenge_advantage_eva_1",
      advantage_type: "challenge_advantage",
      advantage_display_name: "Challenge Advantage",
      contestant_id: idOf("Eva Erickson"),
      obtained_week: 13,
      acquisition_notes: "Solved the final-five puzzle lock for a challenge advantage"
    }
  ];

  registerSeason({
    season_name: "Survivor 48",
    season_number: seasonNumber,
    air_date: new Date("2025-02-26T00:00:00Z"),
    location: "Fiji",
    format: "new_era",
    contestants,
    eliminations,
    tribe_timeline: tribeTimeline,
    advantages
  });
})();
