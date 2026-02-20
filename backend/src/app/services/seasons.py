from ..db.mongo import seasons_collection
from ..schemas.seasons import SeasonResponse


def list_seasons():
    seasons = seasons_collection.find(
        {},
        {
            "season_name": 1,
            "season_number": 1,
            "final_week": 1,
        },
    ).sort("season_number", -1)

    return [
        SeasonResponse(
            id=str(season["_id"]),
            season_name=season["season_name"],
            season_number=season.get("season_number"),
            final_week=season.get("final_week"),
        )
        for season in seasons
    ]
