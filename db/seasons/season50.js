(function () {
  const seasonNumber = 50;
  const finalWeek = null;

  const contestants = [
    { name: "Jenna Lewis-Dougherty", age: 47, hometown: "Woodland, CA" },
    { name: "Colby Donaldson", age: 51, hometown: "Austin, TX" },
    { name: "Stephenie LaGrossa Kendrick", age: 45, hometown: "Dunedin, FL" },
    { name: "Cirie Fields", age: 54, hometown: "Jersey City, NJ" },
    { name: "Ozzy Lusth", age: 43, hometown: "Guanajuato, Mexico" },
    { name: "Benjamin \"Coach\" Wade", age: 53, hometown: "Susanville, CA" },
    { name: "Aubry Bracco", age: 39, hometown: "Hampton Falls, NH" },
    { name: "Chrissy Hofbeck", age: 54, hometown: "The Villages, FL" },
    { name: "Christian Hubicki", age: 39, hometown: "Tallahassee, FL" },
    { name: "Angelina Keeley", age: 35, hometown: "San Diego, CA" },
    { name: "Rick Devens", age: 41, hometown: "Macon, GA" },
    { name: "Mike White", age: 54, hometown: "Hanalei, HI" },
    { name: "Jonathan Young", age: 32, hometown: "Gulf Shores, AL" },
    { name: "Rizo Velovic", age: 25, hometown: "Yonkers, NY" },
    { name: "Dee Valladares", age: 28, hometown: "Miami, FL" },
    { name: "Emily Flippen", age: 30, hometown: "Laurel, MD" },
    { name: "Q Burdette", age: 31, hometown: "Germantown, TN" },
    { name: "Tiffany Ervin", age: 34, hometown: "Los Angeles, CA" },
    { name: "Charlie Davis", age: 27, hometown: "Boston, MA" },
    { name: "Genevieve Mushaluk", age: 34, hometown: "Winnipeg, MB" },
    { name: "Kamilla Karthigesu", age: 31, hometown: "Foster City, CA" },
    { name: "Kyle Fraser", age: 31, hometown: "Brooklyn, NY" },
    { name: "Joe Hunter", age: 45, hometown: "West Sacramento, CA" },
    { name: "Savannah Louie", age: 31, hometown: "Atlanta, GA" }
  ].map(c => ({
    id: idOf(c.name),
    name: c.name,
    age: c.age,
    occupation: null,
    hometown: c.hometown
  }));

  const eliminations = [
    { week: 1, eliminated_contestant_id: idOf("Jenna Lewis-Dougherty") },
    { week: 1, eliminated_contestant_id: idOf("Kyle Fraser") }
  ];

  const tribeTimeline = [
    {
      week: 1,
      event: "start",
      tribes: [
        {
          name: "Cila",
          color: "orange",
          members: [
            idOf("Christian Hubicki"),
            idOf("Cirie Fields"),
            idOf("Emily Flippen"),
            idOf("Jenna Lewis-Dougherty"),
            idOf("Joe Hunter"),
            idOf("Ozzy Lusth"),
            idOf("Rick Devens"),
            idOf("Savannah Louie")
          ]
        },
        {
          name: "Kalo",
          color: "teal",
          members: [
            idOf("Charlie Davis"),
            idOf("Chrissy Hofbeck"),
            idOf("Benjamin \"Coach\" Wade"),
            idOf("Dee Valladares"),
            idOf("Jonathan Young"),
            idOf("Kamilla Karthigesu"),
            idOf("Mike White"),
            idOf("Tiffany Ervin")
          ]
        },
        {
          name: "Vatu",
          color: "magenta",
          members: [
            idOf("Angelina Keeley"),
            idOf("Aubry Bracco"),
            idOf("Colby Donaldson"),
            idOf("Genevieve Mushaluk"),
            idOf("Kyle Fraser"),
            idOf("Q Burdette"),
            idOf("Rizo Velovic"),
            idOf("Stephenie LaGrossa Kendrick")
          ]
        }
      ]
    }
  ];

  const advantages = [
    {
      id: "extra_vote_ozzy_lusth_1",
      advantage_type: "extra_vote",
      advantage_display_name: "Extra Vote",
      contestant_id: idOf("Ozzy Lusth"),
      obtained_week: 1,
      acquisition_notes: "Received when Q accepted Exile supplies and gave Ozzy his next Tribal vote in the Day 1 Exile negotiation",
      end_week: null,
      end_notes: null
    },
    {
      id: "vote_blocker_savannah_louie_1",
      advantage_type: "block_a_vote",
      advantage_display_name: "Block a Vote",
      contestant_id: idOf("Savannah Louie"),
      obtained_week: 1,
      acquisition_notes: "Won the Day 4 journey advantage after Mike drew out and Colby lost the stack challenge",
      end_week: null,
      end_notes: null
    },
    {
      id: "lost_vote_colby_donaldson_1",
      advantage_type: "lost_vote",
      advantage_display_name: "Lost Vote",
      contestant_id: idOf("Colby Donaldson"),
      obtained_week: 1,
      acquisition_notes: "Lost the Day 4 journey stack challenge against Savannah after Mike drew out",
      end_week: null,
      end_notes: null
    },
    {
      id: "lost_vote_q_burdette_1",
      advantage_type: "lost_vote",
      advantage_display_name: "Lost Vote",
      contestant_id: idOf("Q Burdette"),
      obtained_week: 1,
      acquisition_notes: "Accepted Exile supplies in the Day 1 negotiation, which cost his next Tribal vote and granted Ozzy an extra vote",
      end_week: null,
      end_notes: null
    },
    {
      id: "boomerang_idol_ozzy_lusth_1",
      advantage_type: "hidden_immunity_idol",
      advantage_display_name: "Boomerang Immunity Idol",
      contestant_id: idOf("Ozzy Lusth"),
      obtained_week: 1,
      acquisition_notes: "Received after Genevieve found the Boomerang Immunity Idol at Vatu camp and sent it to Ozzy on Day 4",
      end_week: null,
      end_notes: null
    }
  ];

  registerSeason({
    season_name: "Survivor 50",
    season_number: seasonNumber,
    air_date: new Date("2026-02-25T00:00:00Z"),
    location: "Fiji",
    format: "new_era",
    final_week: finalWeek,
    contestants,
    eliminations,
    tribe_timeline: tribeTimeline,
    advantages
  });
})();
