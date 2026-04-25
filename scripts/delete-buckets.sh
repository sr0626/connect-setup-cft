# 1. List buckets and filter by prefix
# 2. For each bucket, empty all objects (including versions)
# 3. Delete the bucket itself

for bucket in $(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'sr0626-')].Name" --output text); do
    echo "Processing bucket: $bucket"
    
    # Empty the bucket (Standard objects)
    aws s3 rm s3://$bucket --recursive
    
    # If versioning was ever enabled, you must remove object versions and delete markers
    aws s3api delete-objects \
        --bucket $bucket \
        --delete "$(aws s3api list-object-versions --bucket $bucket --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" > /dev/null 2>&1

    aws s3api delete-objects \
        --bucket $bucket \
        --delete "$(aws s3api list-object-versions --bucket $bucket --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)" > /dev/null 2>&1

    # Finally, delete the bucket
    aws s3 rb s3://$bucket --force
done