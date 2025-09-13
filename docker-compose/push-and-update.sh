#!/bin/bash
# Push to GitHub then update Portainer
echo "Pushing to GitHub..."
git push "$@"
if [ $? -eq 0 ]; then
    echo "Push successful. Updating Portainer stack..."
    sleep 2  # Give GitHub a moment to update
    curl -X POST http://nas.rove-turtle.ts.net:9000/api/stacks/webhooks/bf0e4fb6-28a0-451e-9c60-2752474a7a99
    echo "Portainer webhook triggered"
else
    echo "Push failed. Skipping Portainer update."
fi