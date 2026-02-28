(function () {
  const seasonNumber = 50;
  const finalWeek = null;

  const contestants = [
    { name: "Jenna Lewis-Dougherty", age: 48, hometown: "Franklin Lakes, NJ" },
    { name: "Colby Donaldson", age: 51, hometown: "Christoval, TX" },
    { name: "Stephenie LaGrossa Kendrick", age: 45, hometown: "Philadelphia, PA" },
    { name: "Cirie Fields", age: 54, hometown: "Jersey City, NJ" },
    { name: "Ozzy Lusth", age: 43, hometown: "Guanajuato, Mexico" },
    { name: "Benjamin \"Coach\" Wade", age: 53, hometown: "Delray Beach, FL" },
    { name: "Aubry Bracco", age: 38, hometown: "Menlo Park, CA" },
    { name: "Chrissy Hofbeck", age: 54, hometown: "Lebanon, NJ" },
    { name: "Christian Hubicki", age: 39, hometown: "Baltimore, MD" },
    { name: "Angelina Keeley", age: 35, hometown: "San Clemente, CA" },
    { name: "Rick Devens", age: 42, hometown: "Macon, GA" },
    { name: "Mike White", age: 55, hometown: "Los Angeles, CA" },
    { name: "Jonathan Young", age: 32, hometown: "Guntersville, AL" },
    { name: "Maryanne Oketch", age: 27, hometown: "Ajax, ON" },
    { name: "Dee Valladares", age: 29, hometown: "Miami, FL" },
    { name: "Emily Flippen", age: 31, hometown: "McKinney, TX" },
    { name: "Q Burdette", age: 31, hometown: "Memphis, TN" },
    { name: "Tiffany Ervin", age: 34, hometown: "Plainview, NY" },
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

  registerSeason({
    season_name: "Survivor 50",
    season_number: seasonNumber,
    air_date: new Date("2026-02-25T00:00:00Z"),
    location: "Fiji",
    format: "new_era",
    final_week: finalWeek,
    contestants,
    eliminations: [],
    tribe_timeline: [],
    advantages: []
  });
})();
