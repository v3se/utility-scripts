# Desktop Backup Script

Automated home directory backup using restic and Backblaze B2 S3-compatible storage.

## Requirements

- restic
- Backblaze B2 account with S3-compatible API keys
- Credentials file with proper permissions

## Setup

1. Install restic:
```bash
sudo apt install restic  # Debian/Ubuntu
```

2. Create credentials file `.backup-secrets` in the same directory as the script:
```bash
export AWS_ACCESS_KEY_ID="your_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export RESTIC_PASSWORD="your_repository_password"
```

3. Set proper permissions:
```bash
chmod 600 .backup-secrets
chmod +x desktop-backup.sh
```

4. Update `B2_BUCKET_NAME` and `B2_ENDPOINT` in the script to match your B2 configuration.

## Usage

Run manually:
```bash
./desktop-backup.sh
```

Run with anacron for daily backups:
```bash
# Edit /etc/anacrontab as root
sudo nano /etc/anacrontab

# Add this line (runs daily, 10 minutes after boot):
1  10  backup.daily  /home/user/path-to-the-dir/desktop-backup.sh
```

The anacron format is: `period delay job-id command`
- `1` = run every 1 day
- `10` = wait 10 minutes after boot before running
- `backup.daily` = job identifier for tracking
- Full path to the backup script

Anacron will run the backup once per day, even if the system wasn't on at the scheduled time.

## Backup Policy

- Backs up `/home` directory
- Keeps last 3 daily snapshots
- Automatically prunes older snapshots
- Verifies 5% of backup data after each run

## Exclusions

The script excludes common cache directories, temporary files, and large unnecessary data:
- Browser caches
- npm/yarn caches
- node_modules
- Downloads folder
- Steam directory and games
- Docker data
- Trash

Modify the `EXCLUDES` array to adjust what gets backed up.

## Managing Backups

All restic commands require credentials. Source the secrets file first:
```bash
source .backup-secrets
```

List all snapshots:
```bash
restic -r s3:s3.eu-central-003.backblazeb2.com/your-bucket-name snapshots
```

List files in a specific snapshot:
```bash
restic -r s3:s3.eu-central-003.backblazeb2.com/your-bucket-name ls <snapshot-id>
```

List files in the latest snapshot:
```bash
restic -r s3:s3.eu-central-003.backblazeb2.com/your-bucket-name ls latest
```

List files with details:
```bash
restic -r s3:s3.eu-central-003.backblazeb2.com/your-bucket-name ls -l <snapshot-id>
```

List files in specific path:
```bash
restic -r s3:s3.eu-central-003.backblazeb2.com/your-bucket-name ls <snapshot-id> /home/user/Documents
```

## Restore

Restore specific snapshot:
```bash
restic -r s3:s3.eu-central-003.backblazeb2.com/bucket-name restore <snapshot-id> --target /restore/path
```

## Security Notes

- Never commit `.backup-secrets` to version control
- Keep the restic password secure - it cannot be recovered if lost
- The credentials file must be readable only by the owner (600 permissions)
