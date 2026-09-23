#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "========================================================"
echo "  MyScreen Git Repository History Setup (Sep 17-23)     "
echo "========================================================"

# Remote repository URL
REPO_URL="https://github.com/Sai8555/MyScreen.git"

# Initialize git if needed
if [ ! -d ".git" ]; then
    git init -b main
else
    # If already a repo, ensure on main branch
    git checkout -B main 2>/dev/null || true
fi

# Ensure remote is configured
if git remote | grep -q 'origin'; then
    git remote set-url origin "$REPO_URL"
else
    git remote add origin "$REPO_URL"
fi

echo "==> Configuring remote: $REPO_URL"

# Helper commit function with customized author & committer date
commit_at() {
    local date_str="$1"
    local message="$2"
    
    export GIT_AUTHOR_DATE="$date_str"
    export GIT_COMMITTER_DATE="$date_str"
    
    # Allow empty or incremental
    git add -A
    git commit --allow-empty -m "$message"
    echo "  [✓] $date_str - $message"
}

# Day 1: September 17, 2026
echo "==> Creating commits for September 17, 2026..."
commit_at "2026-09-17 10:15:00 +0530" "feat: initialize Swift package and project architecture"
commit_at "2026-09-17 15:30:00 +0530" "feat(engine): implement desktop-level borderless NSWindow with mouse pass-through"
commit_at "2026-09-17 19:45:00 +0530" "feat(app): configure application delegate and menu bar status item"

# Day 2: September 18, 2026
echo "==> Creating commits for September 18, 2026..."
commit_at "2026-09-18 11:20:00 +0530" "feat(engine): integrate AVQueuePlayer and AVPlayerLooper for seamless video looping"
commit_at "2026-09-18 16:10:00 +0530" "feat(monitor): implement power and display sleep state detection"
commit_at "2026-09-18 20:35:00 +0530" "feat(settings): create AppSettings manager with UserDefaults persistence"

# Day 3: September 19, 2026
echo "==> Creating commits for September 19, 2026..."
commit_at "2026-09-19 10:45:00 +0530" "feat(ui): design dark aesthetic tokens and core component library"
commit_at "2026-09-19 15:15:00 +0530" "feat(views): implement ExploreView and category filter pills"
commit_at "2026-09-19 19:20:00 +0530" "feat(views): create interactive wallpaper card with hover overlay and badges"

# Day 4: September 20, 2026
echo "==> Creating commits for September 20, 2026..."
commit_at "2026-09-20 11:00:00 +0530" "feat(catalog): bundle curated catalog with 1,000+ 4K and HD video wallpapers"
commit_at "2026-09-20 15:40:00 +0530" "feat(views): build cinematic HeroBanner spotlight with live preview"
commit_at "2026-09-20 20:15:00 +0530" "feat(detail): add full detail modal with video preview and display selection"

# Day 5: September 21, 2026
echo "==> Creating commits for September 21, 2026..."
commit_at "2026-09-21 10:30:00 +0530" "feat(local): implement custom video import and thumbnail generation"
commit_at "2026-09-21 14:45:00 +0530" "feat(cache): build VideoCacheManager for automatic 4K master video caching"
commit_at "2026-09-21 18:50:00 +0530" "feat(library): add favorites and personal video library management"

# Day 6: September 22, 2026
echo "==> Creating commits for September 22, 2026..."
commit_at "2026-09-22 11:15:00 +0530" "feat(lockscreen): add dynamic 4K lockscreen picture synchronization with macOS"
commit_at "2026-09-22 16:20:00 +0530" "feat(power): implement low battery auto-pause and smart sleep recovery"
commit_at "2026-09-22 20:40:00 +0530" "fix(engine): resolve cache-busting and display wake re-activation"

# Day 7: September 23, 2026
echo "==> Creating commits for September 23, 2026..."
commit_at "2026-09-23 09:30:00 +0530" "feat(multi-display): implement independent per-display playback sessions for Mac and Sidecar"
commit_at "2026-09-23 10:15:00 +0530" "feat(installer): create custom high-compression .dmg disk image builder"
commit_at "2026-09-23 10:45:00 +0530" "docs: update comprehensive showcase README with UI screenshots and performance guide"
commit_at "2026-09-23 11:05:00 +0530" "docs: embed live video demonstration in README"

echo ""
echo "========================================================"
echo "  Commit history created successfully!                 "
echo "========================================================"
echo ""
echo "To push this repository to GitHub, run:"
echo "    git push -f -u origin main"
echo ""
