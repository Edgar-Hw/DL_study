from pathlib import Path

import polars as pl
from sklearn.model_selection import train_test_split

COLOR_LABELS = [
    'black', 
    'blue', 
    'brown', 
    'green', 
    'red', 
    'white'
]

CATEGORY_LABELS = [
    'dress', 
    'shirt', 
    'pants', 
    'shorts', 
    'shoes'
]

MULTI_LABEL_COLUMNS = COLOR_LABELS + CATEGORY_LABELS
COLOR_TO_INDEX = {color: idx for idx, color in enumerate(COLOR_LABELS)}

# ----------------------------------------------------------
#  폴더 이름을 분리하는 함수
# ----------------------------------------------------------
def parse_folder_name(folder_name: str) -> tuple[str, str]:
    color, category = folder_name.split('_', maxsplit=1)

    if color not in COLOR_LABELS:
        raise ValueError(f'알 수 없는 색상 라벨입니다: {color}')
    
    if category not in CATEGORY_LABELS:
        raise ValueError(f'알 수 없는 의류 종류 라벨입니다: {category}')
    
    return color, category


# ----------------------------------------------------------
#  이미지 경로 1개를 라벨 레코드 1개로 바꾸는 함수
# ----------------------------------------------------------
def build_label_record(image_path: str | Path) -> dict:
    image_path = Path(image_path)

    folder_name = image_path.parent.name
    color, category = parse_folder_name(folder_name)

    record = {'image':str(image_path)}

    for label in MULTI_LABEL_COLUMNS:
        record[label] = 0

    record[color] = 1
    record[category] = 1
    record['color_index'] = COLOR_TO_INDEX[color]

    return record


# ----------------------------------------------------------
#  전체 이미지 경로를 모으는 함수
# ----------------------------------------------------------
def collect_image_paths(dataset_dir: str | Path) -> list[Path]:
    dataset_dir = Path(dataset_dir)

    # clothes_dataset 아래의 하위 폴더들을 돌면서 .jpg 파일을 전부 모음
    image_paths = sorted(dataset_dir.glob('*/*.jpg'))   

    if not image_paths:
        raise FileNotFoundError(f'이미지 파일을 찾지 못했습니다: {dataset_dir}')
    
    return image_paths


# ----------------------------------------------------------
#  전체 이미지 경로를 Polars DataFrame으로 바꾸는 함수
# ----------------------------------------------------------
def build_dataframe(dataset_dir: str | Path) -> pl.DataFrame:
    image_paths = collect_image_paths(dataset_dir)
    # 이미지 하나마다 build_label_record() 적용
    # List of Dictionaries 생성
    records = [build_label_record(image_path) for image_path in image_paths]

    df = pl.DataFrame(records)

    #    멀티라벨 컬럼의 자료형을 UInt8로 변환
    #    기본적으로 0/1 값만 저장하므로 i64를 사용할 필요가 없음
    #    UInt8로 바꾸면 메모리를 덜 사용함
    df = df.with_columns(
        [pl.col(label).cast(pl.UInt8) for label in MULTI_LABEL_COLUMNS] + 
        [pl.col('color_index').cast(pl.UInt8)]
    )

    return df


# ----------------------------------------------------------
# 전체 DataFrame을 train, validation, test 데이터로 나누는 함수
# ----------------------------------------------------------
def split_dataframe(df: pl.DataFrame, test_size: float = 0.3, 
                                    val_size_within_train: float = 0.3, random_state: int = 777) -> tuple[pl.DataFrame, pl.DataFrame, pl.DataFrame]:
    train_df, test_df = train_test_split(
        df.to_pandas(),
        test_size=test_size,
        shuffle=True,
        random_state=random_state
    )

    train_df, val_df = train_test_split(
        train_df,
        test_size=val_size_within_train,
        shuffle=True,
        random_state=random_state
    )

    train_df = pl.from_pandas(train_df.reset_index(drop=True))
    val_df = pl.from_pandas(val_df.reset_index(drop=True))
    test_df = pl.from_pandas(test_df.reset_index(drop=True))

    return train_df, val_df, test_df


# ----------------------------------------------------------
# 분할된 `train_df`, `val_df`, `test_df`를 CSV 파일로 저장하는 함수
# ----------------------------------------------------------
def save_split_dataframes(train_df: pl.DataFrame, val_df: pl.DataFrame, test_df: pl.DataFrame, output_dir: str | Path = './csv_data') -> None:
    output_dir = Path(output_dir)

    nocolor_dir = output_dir / 'nocolorinfo'
    color_dir = output_dir / 'colorinfo'

    nocolor_dir.mkdir(parents=True, exist_ok=True)
    color_dir.mkdir(parents=True, exist_ok=True)

    no_color_columns = ['image'] + MULTI_LABEL_COLUMNS
    color_columns = ['image'] + MULTI_LABEL_COLUMNS + ['color_index']

    train_df.select(no_color_columns).write_csv(nocolor_dir / 'train.csv')
    val_df.select(no_color_columns).write_csv(nocolor_dir / 'val.csv')
    test_df.select(no_color_columns).write_csv(nocolor_dir / 'test.csv')

    train_df.select(color_columns).write_csv(color_dir / 'train_color.csv')
    val_df.select(color_columns).write_csv(color_dir / 'val_color.csv')
    test_df.select(color_columns).write_csv(color_dir / 'test_color.csv')


# -------------------------------------------------------------------------
# 저장된 CSV 파일을 다시 읽어서 train, validation, test 데이터프레임으로 불러오는 함수
# -------------------------------------------------------------------------
def load_split_dataframes(input_dir: str | Path = './csv_data', 
                                                use_color_info: bool = False) -> tuple[pl.DataFrame, pl.DataFrame, pl.DataFrame]:
    input_dir = Path(input_dir)

    if use_color_info:
        train_path = input_dir / 'colorinfo' / 'train_color.csv'
        val_path = input_dir / 'colorinfo' / 'val_color.csv'
        test_path = input_dir / 'colorinfo' / 'test_color.csv'
    else:
        train_path = input_dir / 'nocolorinfo' / 'train.csv'
        val_path = input_dir / 'nocolorinfo' / 'val.csv'
        test_path = input_dir / 'nocolorinfo' / 'test.csv'

    train_df = pl.read_csv(train_path)
    val_df = pl.read_csv(val_path)
    test_df = pl.read_csv(test_path)

    return train_df, val_df, test_df