#!/bin/bash
# Posts a git diff to MS Team Channel using webhooks
#
# Usage:
#   Make sure jq and curl are installed.
#   Save this script in /var/lib/oxidized/extra/
#   Add to oxidized config:
#
# hooks:
#  ms_teams_webhook:
#    type: exec
#    events: [post_store]
#    cmd: '/var/lib/oxidized/extra/gitdiff-msteams.sh'
#    async: true
#    timeout: 120
#
# Add webhook to your MS Teams channel and set the next variable to the full url
# If INCLUDE_GITHUB_LINK is set to true, there will be a button that links to GITURL in the bottom of each teams post. the commit id is added at the end of the url.
# MAXSIZE is set to respect the 28 KB limit for teams webhooks, but you might need to change it if you modify the Adaptive Card

weburl="https://contoso.webhook.office.com/webhookb2/etc etc etc"
GITURL="https://github.example.com/My-org/oxidized/commit/"
INCLUDE_GITHUB_LINK=false
# Max size for summary text.
MAXSIZE=24500

if [ "$INCLUDE_GITHUB_LINK" = true ]; then
  github_action=",
            { \"type\": \"ActionSet\",
              \"actions\":
               [
                 {
                 \"type\": \"Action.OpenUrl\",
                 \"title\": \"Click to see diff in github\",
                 \"url\": \"${GITURL}${OX_REPO_COMMITREF}\"
                 }
               ]
             }"
fi

postdata()
{
    cat <<EOF
{
   "type":"message",
   "attachments":[
      {
         "contentType":"application/vnd.microsoft.card.adaptive",
         "contentUrl":null,
         "content":{
            "$schema":"http://adaptivecards.io/schemas/adaptive-card.json",
            "type":"AdaptiveCard",
            "version":"1.2",
            "msTeams": { "width": "full" },
            "body":[
                {
                    "type": "TextBlock",
                    "text": "Oxidized update for ${OX_NODE_NAME}",
                    "size": "medium",
                    "weight": "Bolder",
                    "style": "heading",
                    "wrap": "true"
                },
                {
                    "type": "FactSet",
                    "facts": [
                        {
                            "title": "Node name",
                            "value": "${OX_NODE_NAME}"
                        },
                        {
                            "title": "Job status",
                            "value": "${OX_JOB_STATUS}"
                        },
                        {
                            "title": "Job time",
                            "value": "${OX_JOB_TIME}"
                        },
                        {
                            "title": "Git repo",
                            "value": "${OX_REPO_NAME}"
                        },
                        {
                            "title": "Git commit ID",
                            "value": "${OX_REPO_COMMITREF}"
                        }
                    ]
                },
                {
                    "type": "RichTextBlock",
                    "inlines": [
                        {
                            "type": "TextRun",
                            "text": ${COMMIT},
                            "fontType": "monospace",
                            "size": "small"
                        }
                    ]
                }${github_action}
           ]
         }
      }
   ]
}
EOF
}

COMMIT=$(git --bare --git-dir="${OX_REPO_NAME}" show --pretty='' --no-color "${OX_REPO_COMMITREF}" | jq --raw-input --slurp --compact-output)
URL=""

size=$(postdata | wc -c)
if [ "$size" -gt "$MAXSIZE" ]; then
  COMMIT=$(git --bare --git-dir="${OX_REPO_NAME}" show --pretty='' --no-color "${OX_REPO_COMMITREF}" | head -c $MAXSIZE)
  COMMIT+="$NEWLINE...$NEWLINE Shortened because of length"
  COMMIT=$(echo "${COMMIT}" | jq --raw-input --slurp --compact-output )
fi

curl -i -H "Content-Type: application/json" -X POST --data "$(postdata)" "${weburl}"
