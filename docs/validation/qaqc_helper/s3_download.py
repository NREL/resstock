from pathlib import Path
import boto3


### [1] S3 download func
def download_s3_directory(s3_bucket, s3_prefix, destination):
    destination = Path(destination)

    s3 = boto3.client("s3")
    for item in s3.list_objects(Bucket=s3_bucket, Prefix=s3_prefix)["Contents"]:
        s3_path = item["Key"]
        if s3_path.endswith(".parquet"):
            local_path = destination / Path(s3_path).name
            if not local_path.exists():
                local_path.parent.mkdir(parents=True, exist_ok=True)
                s3.download_file(s3_bucket, s3_path, local_path.as_posix())

    print(f"S3 directory: s3://{s3_bucket}/{s3_prefix}/ downloaded to: {destination}")


def download_s3_files(
    s3_prefix, s3_bucket="eussrr2", destination="auto", check_files_against_s3=False
):
    """Download summary files (baseline and upgrade) for LA100 topic run
    Args :
        s3_prefix : str
            s3 subpath to directory from bucket name
        destination : str | Path
            local directory for downloaded files (files are downloaded as "results_up00.parquet", etc)
        check_files_against_s3 : bool
            if True, each item within s3://<s3_bucket>/<s3_prefix> are checked and downloaded accordingly
            if False, only download s3 files if destination does not exist or is empty
    """
    if destination == "auto":
        destination = get_localdir_for_run(s3_prefix)
    else:
        destination = Path(destination)

    if not check_files_against_s3:
        # do simple check
        if (
            destination.exists()
            and len([x for x in destination.rglob("*.parquet")]) > 0
        ):
            print(f"{destination} files exist, no downloading")
            return

    s3_prefix = s3_prefix.removesuffix("/")
    try:
        download_s3_directory(s3_bucket, s3_prefix + "/baseline", destination)
    except KeyError:
        print(f"No baseline for {s3_prefix}")
        pass
    try:
        download_s3_directory(s3_bucket, s3_prefix + "/upgrades", destination)
    except KeyError:
        print(f"No upgrades for {s3_prefix}")
        pass
    print("Downloading completed")


def get_localdir_for_run(s3_prefix):
    """where resstock results should download to
    Take folder name of s3_prefix
    """
    table_name = Path(s3_prefix).stem
    data_dir = Path(".").resolve() / "data" / table_name
    print(f"Data directory: {data_dir}")
    return data_dir
