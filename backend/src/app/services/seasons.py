from ..db.mongo import seasons_collection
from ..schemas.seasons import SeasonResponse


def list_seasons() -> list[SeasonResponse]:
    seasons = seasons_collection.find(
        {},
        {
            "season_name": 1,
            "season_number": 1,
        },
    ).sort("season_number", -1)

    return [
        SeasonResponse(
            id=str(season["_id"]),
            season_name=season["season_name"],
            season_number=season.get("season_number"),
        )
        for season in seasons
    ]
