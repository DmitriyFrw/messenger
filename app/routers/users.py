from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import User
from app.schemas import UpdateDisplayNameRequest, UserPublic

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserPublic)
def me(current_user: User = Depends(get_current_user)) -> UserPublic:
    return UserPublic.model_validate(current_user)


@router.patch("/me", response_model=UserPublic)
def update_me(
    body: UpdateDisplayNameRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserPublic:
    current_user.display_name = body.display_name
    db.commit()
    db.refresh(current_user)
    return UserPublic.model_validate(current_user)


@router.get("/search", response_model=list[UserPublic])
def search_users(
    q: str = Query(min_length=1, max_length=64),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[UserPublic]:
    pattern = f"%{q}%"
    users = (
        db.query(User)
        .filter(User.id != current_user.id)
        .filter((User.username.ilike(pattern)) | (User.display_name.ilike(pattern)))
        .limit(20)
        .all()
    )
    return [UserPublic.model_validate(u) for u in users]
