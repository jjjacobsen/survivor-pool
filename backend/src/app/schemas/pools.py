from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class PoolCreateRequest(BaseModel):
    name: str
    season_id: str
    owner_id: str
    start_week: int = 1
    invite_user_ids: list[str] = Field(default_factory=list)


class PoolResponse(BaseModel):
    id: str
    name: str
    owner_id: str
    season_id: str
    created_at: datetime
    current_week: int
    start_week: int = 1
    settings: dict[str, Any] = Field(default_factory=dict)
    invited_user_ids: list[str] = Field(default_factory=list)
    status: str = "open"
    is_competitive: bool = False
    competitive_since_week: int | None = None
    completed_week: int | None = None
    completed_at: datetime | None = None
    winner_user_ids: list[str] = Field(default_factory=list)


class AvailableContestantResponse(BaseModel):
    id: str
    name: str
    subtitle: str | None = None
    tribe_name: str | None = None
    tribe_color: str | None = None


class CurrentPickSummary(BaseModel):
    pick_id: str
    contestant_id: str
    contestant_name: str
    week: int
    locked_at: datetime


class AvailableContestantsResponse(BaseModel):
    pool_id: str
    user_id: str
    current_week: int
    contestants: list[AvailableContestantResponse]
    score: int
    current_pick: CurrentPickSummary | None = None
    is_eliminated: bool = False
    elimination_reason: str | None = None
    eliminated_week: int | None = None
    is_winner: bool = False
    pool_status: str = "open"
    pool_completed_week: int | None = None
    pool_completed_at: datetime | None = None
    winners: list[PoolWinnerSummary] = Field(default_factory=list)
    did_tie: bool = False


class ContestantDetail(BaseModel):
    id: str
    name: str
    age: int | None = None
    occupation: str | None = None
    hometown: str | None = None
    tribe_name: str | None = None
    tribe_color: str | None = None
    advantages: list[ContestantAdvantage] = Field(default_factory=list)


class ContestantAdvantage(BaseModel):
    id: str
    label: str
    value: str


class ContestantDetailResponse(BaseModel):
    pool_id: str
    user_id: str
    contestant: ContestantDetail
    is_available: bool
    eliminated_week: int | None = None
    already_picked_week: int | None = None
    current_pick: CurrentPickSummary | None = None


class PoolAdvanceMissingMember(BaseModel):
    user_id: str
    display_name: str


class PoolAdvanceStatusResponse(BaseModel):
    current_week: int
    active_member_count: int
    locked_count: int
    missing_count: int
    missing_members: list[PoolAdvanceMissingMember]
    can_advance: bool = False


class PoolAdvanceRequest(BaseModel):
    user_id: str


class PoolEliminatedMember(BaseModel):
    user_id: str
    display_name: str
    reason: str


class PoolWinnerSummary(BaseModel):
    user_id: str
    display_name: str


class PoolAdvanceResponse(BaseModel):
    new_current_week: int
    eliminations: list[PoolEliminatedMember] = Field(default_factory=list)
    pool_completed: bool = False
    winners: list[PoolWinnerSummary] = Field(default_factory=list)


class PoolLeaderboardEntry(BaseModel):
    rank: int
    user_id: str
    display_name: str
    score: int
    status: str
    is_winner: bool = False
    elimination_reason: str | None = None
    eliminated_week: int | None = None
    final_rank: int | None = None
    finished_week: int | None = None
    finished_date: datetime | None = None


class PoolLeaderboardResponse(BaseModel):
    pool_id: str
    current_week: int
    pool_status: str
    pool_completed_week: int | None = None
    pool_completed_at: datetime | None = None
    entries: list[PoolLeaderboardEntry]
    winners: list[PoolWinnerSummary] = Field(default_factory=list)
    did_tie: bool = False


class PoolMemberSummary(BaseModel):
    user_id: str
    display_name: str
    email: str
    role: str
    status: str
    joined_at: datetime | None = None
    invited_at: datetime | None = None
    elimination_reason: str | None = None
    eliminated_week: int | None = None
    eliminated_date: datetime | None = None
    final_rank: int | None = None
    finished_week: int | None = None
    finished_date: datetime | None = None


class PoolMembershipListResponse(BaseModel):
    pool_id: str
    members: list[PoolMemberSummary]


class PoolInviteRequest(BaseModel):
    owner_id: str
    invited_user_id: str


class PoolInviteResponse(BaseModel):
    member: PoolMemberSummary


class PoolInviteDecisionRequest(BaseModel):
    user_id: str
    action: str


class PoolInviteDecisionResponse(BaseModel):
    member: PoolMemberSummary


class PendingInviteSummary(BaseModel):
    pool_id: str
    pool_name: str
    owner_display_name: str
    season_id: str
    season_number: int | None = None
    invited_at: datetime | None = None


class PendingInvitesResponse(BaseModel):
    invites: list[PendingInviteSummary]
