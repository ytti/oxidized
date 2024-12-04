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

weburl="https://contoso.webhook.office.com/webhookb2/etc etc etc"
GITURL="https://github.example.com/My-org/oxidized/commit/"

# Max size before shortening
MAXSIZE=20000
# When shortening - how many lines to show
SHORTLINES=30

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
                },
                {
                    "type": "ActionSet",
                    "actions": [
                        {
                        "type": "Action.OpenUrl",
                        "title": "Click to see diff in github",
                        "url": "${GITURL}${OX_REPO_COMMITREF}"
                    }
                ]
            }
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
  COMMIT=$(git --bare --git-dir="${OX_REPO_NAME}" show --pretty='' --no-color "${OX_REPO_COMMITREF}" | head -n $SHORTLINES)
  COMMIT+="$NEWLINE...$NEWLINE Shortened because of length, see full diff by clicking below button"
  COMMIT=$(echo "${COMMIT}" | jq --raw-input --slurp --compact-output )
fi

curl -i -H "Content-Type: application/json" -X POST --data "$(postdata)" "${weburl}"
