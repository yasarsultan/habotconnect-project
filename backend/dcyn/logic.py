DCYN_YES = "Y"
DCYN_NO = "N"

ALLOWED_DCYN_VALUES = {DCYN_YES, DCYN_NO}


def to_dcyn(value):
    if isinstance(value, bool):
        return DCYN_YES if value else DCYN_NO
    if isinstance(value, str):
        normalized = value.strip().upper()
        if normalized in ("Y", "YES", "TRUE", "1"):
            return DCYN_YES
        if normalized in ("N", "NO", "FALSE", "0"):
            return DCYN_NO
    raise ValueError(f"Cannot resolve '{value}' to a DCYN value")


def from_dcyn(dcyn_value):
    if dcyn_value not in ALLOWED_DCYN_VALUES:
        raise ValueError(f"'{dcyn_value}' is not a valid DCYN value")
    return dcyn_value == DCYN_YES
